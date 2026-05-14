use crate::agent::{FinishReason, LlmResponse, Message, Role, ToolCall};
use crate::provider::{LlmProvider, RequestConfig, ToolDef};
use anyhow::{anyhow, Result};
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::time::Duration;
use trailhead_core::types::TokenUsage;

#[derive(Debug, Clone, Serialize)]
struct OaiRequest {
    model: String,
    messages: Vec<serde_json::Value>,
    max_tokens: u32,
    #[serde(skip_serializing_if = "Option::is_none")]
    tools: Option<Vec<OaiTool>>,
}

#[derive(Debug, Clone, Serialize)]
struct OaiTool {
    r#type: String,
    function: OaiFunction,
}

#[derive(Debug, Clone, Serialize)]
struct OaiFunction {
    name: String,
    description: String,
    parameters: serde_json::Value,
}

#[derive(Debug, Deserialize)]
struct OaiResponse {
    choices: Vec<OaiChoice>,
    usage: OaiUsage,
}

#[derive(Debug, Deserialize)]
struct OaiChoice {
    message: OaiMessage,
    finish_reason: Option<String>,
}

#[derive(Debug, Deserialize)]
struct OaiMessage {
    content: Option<String>,
    reasoning_content: Option<String>,
    tool_calls: Option<Vec<OaiToolCall>>,
}

#[derive(Debug, Deserialize)]
struct OaiToolCall {
    id: String,
    r#type: String,
    function: OaiFunctionCall,
}

#[derive(Debug, Deserialize)]
struct OaiFunctionCall {
    name: String,
    arguments: String,
}

#[derive(Debug, Deserialize)]
struct OaiUsage {
    prompt_tokens: u64,
    completion_tokens: u64,
    total_tokens: Option<u64>,
}

pub struct OpenAiCompatibleProvider {
    client: reqwest::Client,
    api_key: String,
    model: String,
    base_url: String,
}

impl OpenAiCompatibleProvider {
    pub fn new(api_key: String, model: String, base_url: String) -> Self {
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

    fn convert_messages(messages: &[Message]) -> Vec<serde_json::Value> {
        let mut result = Vec::new();
        for msg in messages {
            let val = match msg.role {
                Role::System => {
                    serde_json::json!({
                        "role": "system",
                        "content": msg.content.clone().unwrap_or_default()
                    })
                }
                Role::User => {
                    serde_json::json!({
                        "role": "user",
                        "content": msg.content.clone().unwrap_or_default()
                    })
                }
                Role::Assistant => {
                    let mut obj = serde_json::json!({
                        "role": "assistant",
                        "content": msg.content
                    });
                    if let Some(rc) = &msg.reasoning_content {
                        obj["reasoning_content"] = serde_json::Value::String(rc.clone());
                    }
                    if let Some(tcs) = &msg.tool_calls {
                        let tc_vals: Vec<serde_json::Value> = tcs
                            .iter()
                            .map(|tc| {
                                serde_json::json!({
                                    "id": tc.id,
                                    "type": "function",
                                    "function": {
                                        "name": tc.name,
                                        "arguments": tc.arguments.to_string()
                                    }
                                })
                            })
                            .collect();
                        obj["tool_calls"] = serde_json::Value::Array(tc_vals);
                    }
                    obj
                }
                Role::Tool => {
                    serde_json::json!({
                        "role": "tool",
                        "tool_call_id": msg.tool_call_id.clone().unwrap_or_default(),
                        "content": msg.content.clone().unwrap_or_default()
                    })
                }
            };
            result.push(val);
        }
        result
    }

    fn convert_tools(tool_defs: &[ToolDef]) -> Vec<OaiTool> {
        tool_defs
            .iter()
            .map(|t| OaiTool {
                r#type: "function".into(),
                function: OaiFunction {
                    name: t.name.clone(),
                    description: t.description.clone(),
                    parameters: t.input_schema.clone(),
                },
            })
            .collect()
    }
}

#[async_trait]
impl LlmProvider for OpenAiCompatibleProvider {
    async fn send(&self, messages: &[Message], config: &RequestConfig) -> Result<LlmResponse> {
        let api_messages = Self::convert_messages(messages);
        let tools = if config.tools.is_empty() {
            None
        } else {
            Some(Self::convert_tools(&config.tools))
        };

        let request = OaiRequest {
            model: self.model.clone(),
            messages: api_messages,
            max_tokens: config.max_tokens,
            tools,
        };

        let url = format!("{}/chat/completions", self.base_url.trim_end_matches('/'));
        let resp = self
            .client
            .post(&url)
            .header("authorization", format!("Bearer {}", self.api_key))
            .header("content-type", "application/json")
            .json(&request)
            .send()
            .await
            .map_err(|e| anyhow!("OpenAI-compatible API request failed: {e}"))?;

        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            return Err(anyhow!("OpenAI-compatible API error {status}: {body}"));
        }

        let api_response: OaiResponse = resp
            .json()
            .await
            .map_err(|e| anyhow!("Failed to parse OpenAI-compatible response: {e}"))?;

        let choice = api_response
            .choices
            .into_iter()
            .next()
            .ok_or_else(|| anyhow!("no choices in response"))?;

        let mut tool_calls = Vec::new();
        if let Some(tcs) = choice.message.tool_calls {
            for tc in tcs {
                let args: serde_json::Value =
                    serde_json::from_str(&tc.function.arguments).unwrap_or(serde_json::Value::Null);
                tool_calls.push(ToolCall {
                    id: tc.id,
                    name: tc.function.name,
                    arguments: args,
                });
            }
        }

        let content = choice.message.content.filter(|c| !c.is_empty());
        let reasoning_content = choice.message.reasoning_content.filter(|c| !c.is_empty());

        let finish_reason = match choice.finish_reason.as_deref() {
            Some("tool_calls") | Some("function_call") => FinishReason::ToolUse,
            Some("length") => FinishReason::MaxTokens,
            _ => FinishReason::Stop,
        };

        let usage = TokenUsage::new(
            api_response.usage.prompt_tokens,
            api_response.usage.completion_tokens,
        );

        let message = if tool_calls.is_empty() {
            Message::assistant_with_reasoning(content, reasoning_content, None)
        } else {
            Message::assistant_with_reasoning(content, reasoning_content, Some(tool_calls))
        };

        Ok(LlmResponse {
            message,
            finish_reason,
            usage,
        })
    }

    fn name(&self) -> &str {
        "openai-compatible"
    }
}
