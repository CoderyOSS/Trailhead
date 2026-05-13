pub mod message;

pub use message::{FinishReason, LlmResponse, Message, Role, TokenUsage, ToolCall, ToolResult};

use crate::provider::{LlmProvider, RequestConfig};
use crate::tools::{ToolContext, ToolRegistry};
use anyhow::Result;

#[derive(Debug, Clone)]
pub struct AgentConfig {
    pub max_tool_calls: u32,
    pub system_prompt: Option<String>,
    pub user_prompt: String,
    pub allowed_tools: Vec<String>,
    pub max_tokens: u32,
}

#[derive(Debug)]
pub struct AgentOutput {
    pub messages: Vec<Message>,
    pub tool_calls_made: u32,
    pub usage: TokenUsage,
    pub finish_reason: FinishReason,
}

pub async fn run_agent_loop(
    provider: &dyn LlmProvider,
    tools: &ToolRegistry,
    config: AgentConfig,
    tool_ctx: ToolContext,
) -> Result<AgentOutput> {
    let mut messages = Vec::new();

    if let Some(sys) = &config.system_prompt {
        messages.push(Message::system(sys));
    }

    messages.push(Message::user(&config.user_prompt));

    let tool_defs = tools.tool_defs(&config.allowed_tools)?;
    let request_config = RequestConfig {
        max_tokens: config.max_tokens,
        tools: tool_defs,
    };

    let mut tool_calls_made = 0u32;
    let mut total_usage = TokenUsage::zero();
    #[allow(unused_assignments)]
    let mut finish_reason = FinishReason::Stop;

    loop {
        let response = provider.send(&messages, &request_config).await?;
        total_usage = total_usage + response.usage.clone();

        let assistant_msg = response.message.clone();
        finish_reason = response.finish_reason;

        messages.push(assistant_msg.clone());

        match response.finish_reason {
            FinishReason::ToolUse => {
                if tool_calls_made >= config.max_tool_calls {
                    finish_reason = FinishReason::MaxTokens;
                    break;
                }

                let tool_calls = assistant_msg.tool_calls.as_deref().unwrap_or(&[]);
                for tc in tool_calls {
                    tool_calls_made += 1;
                    let result = tools
                        .execute(&tc.name, &tc.arguments, &tool_ctx)
                        .await
                        .unwrap_or_else(|e| format!("error: {e}"));
                    messages.push(Message::tool_result(&tc.id, result));
                }
            }
            FinishReason::Stop | FinishReason::MaxTokens => break,
        }
    }

    Ok(AgentOutput {
        messages,
        tool_calls_made,
        usage: total_usage,
        finish_reason,
    })
}
