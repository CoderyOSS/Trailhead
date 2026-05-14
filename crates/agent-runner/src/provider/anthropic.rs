use crate::agent::{FinishReason, LlmResponse, Message, Role, ToolCall};
use trailhead_core::types::TokenUsage;
use crate::provider::{LlmProvider, RequestConfig, ToolDef};
use anyhow::{anyhow, Result};
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::time::Duration;

#[derive(Debug, Clone, Serialize)]
struct AnthropicRequest {
    model: String,
    max_tokens: u32,
    messages: Vec<AnthropicMessage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tools: Option<Vec<AnthropicTool>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    system: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AnthropicMessage {
    role: String,
    content: serde_json::Value,
}

#[derive(Debug, Clone, Serialize)]
struct AnthropicTool {
    name: String,
    description: String,
    input_schema: serde_json::Value,
}

#[derive(Debug, Deserialize)]
struct AnthropicResponse {
    content: Vec<AnthropicContentBlock>,
    stop_reason: Option<String>,
    usage: AnthropicUsage,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "type")]
enum AnthropicContentBlock {
    #[serde(rename = "text")]
    Text { text: String },
    #[serde(rename = "tool_use")]
    ToolUse {
        id: String,
        name: String,
        input: serde_json::Value,
    },
}

#[derive(Debug, Deserialize)]
struct AnthropicUsage {
    input_tokens: u64,
    output_tokens: u64,
}

pub struct AnthropicProvider {
    client: reqwest::Client,
    api_key: String,
    model: String,
    base_url: String,
}

impl AnthropicProvider {
    pub fn new(api_key: String, model: String) -> Self {
        let base_url =
            std::env::var("ANTHROPIC_BASE_URL").unwrap_or_else(|_| "https://api.anthropic.com".into());
        Self {
            client: reqwest::Client::builder()
                .timeout(Duration::from_secs(120))
                .build()
                .unwrap_or_default(),
            api_key,
            model,
            base_url,
        }
    }

    fn convert_messages(messages: &[Message]) -> (Option<String>, Vec<AnthropicMessage>) {
        let mut system_prompt = None;
        let mut api_messages = Vec::new();

        for msg in messages {
            match msg.role {
                Role::System => {
                    system_prompt = msg.content.clone();
                }
                Role::User => {
                    api_messages.push(AnthropicMessage {
                        role: "user".into(),
                        content: serde_json::Value::String(msg.content.clone().unwrap_or_default()),
                    });
                }
                Role::Assistant => {
                    if let Some(tcs) = &msg.tool_calls {
                        let mut content = Vec::new();
                        if let Some(text) = &msg.content {
                            if !text.is_empty() {
                                content.push(serde_json::json!({
                                    "type": "text",
                                    "text": text
                                }));
                            }
                        }
                        for tc in tcs {
                            content.push(serde_json::json!({
                                "type": "tool_use",
                                "id": tc.id,
                                "name": tc.name,
                                "input": tc.arguments
                            }));
                        }
                        api_messages.push(AnthropicMessage {
                            role: "assistant".into(),
                            content: serde_json::Value::Array(content),
                        });
                    } else {
                        api_messages.push(AnthropicMessage {
                            role: "assistant".into(),
                            content: serde_json::Value::String(
                                msg.content.clone().unwrap_or_default(),
                            ),
                        });
                    }
                }
                Role::Tool => {
                    let tool_call_id = msg.tool_call_id.clone().unwrap_or_default();
                    api_messages.push(AnthropicMessage {
                        role: "user".into(),
                        content: serde_json::json!([{
                            "type": "tool_result",
                            "tool_use_id": tool_call_id,
                            "content": msg.content.clone().unwrap_or_default()
                        }]),
                    });
                }
            }
        }

        (system_prompt, api_messages)
    }

    fn convert_tools(tool_defs: &[ToolDef]) -> Vec<AnthropicTool> {
        tool_defs
            .iter()
            .map(|t| AnthropicTool {
                name: t.name.clone(),
                description: t.description.clone(),
                input_schema: t.input_schema.clone(),
            })
            .collect()
    }
}

#[async_trait]
impl LlmProvider for AnthropicProvider {
    async fn send(&self, messages: &[Message], config: &RequestConfig) -> Result<LlmResponse> {
        let (system, api_messages) = Self::convert_messages(messages);
        let tools = if config.tools.is_empty() {
            None
        } else {
            Some(Self::convert_tools(&config.tools))
        };

        let request = AnthropicRequest {
            model: self.model.clone(),
            max_tokens: config.max_tokens,
            messages: api_messages,
            tools,
            system,
        };

        let url = format!("{}/v1/messages", self.base_url);
        let resp = self
            .client
            .post(&url)
            .header("x-api-key", &self.api_key)
            .header("anthropic-version", "2023-06-01")
            .header("content-type", "application/json")
            .json(&request)
            .send()
            .await
            .map_err(|e| anyhow!("Anthropic API request failed: {e}"))?;

        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            return Err(anyhow!("Anthropic API error {status}: {body}"));
        }

        let api_response: AnthropicResponse = resp
            .json()
            .await
            .map_err(|e| anyhow!("Failed to parse Anthropic response: {e}"))?;

        let mut text_content = String::new();
        let mut tool_calls = Vec::new();

        for block in &api_response.content {
            match block {
                AnthropicContentBlock::Text { text } => {
                    text_content.push_str(text);
                }
                AnthropicContentBlock::ToolUse { id, name, input } => {
                    tool_calls.push(ToolCall {
                        id: id.clone(),
                        name: name.clone(),
                        arguments: input.clone(),
                    });
                }
            }
        }

        let finish_reason = match api_response.stop_reason.as_deref() {
            Some("tool_use") => FinishReason::ToolUse,
            Some("max_tokens") => FinishReason::MaxTokens,
            _ => FinishReason::Stop,
        };

        let usage = TokenUsage::new(
            api_response.usage.input_tokens,
            api_response.usage.output_tokens,
        );

        let message = if tool_calls.is_empty() {
            Message::assistant(&text_content)
        } else {
            let content = if text_content.is_empty() {
                None
            } else {
                Some(text_content)
            };
            Message::assistant_with_tool_calls(content, tool_calls)
        };

        Ok(LlmResponse {
            message,
            finish_reason,
            usage,
        })
    }

    fn name(&self) -> &str {
        "anthropic"
    }
}
