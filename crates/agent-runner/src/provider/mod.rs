use anyhow::Result;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

pub mod anthropic;
pub mod openai_compatible;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolDef {
    pub name: String,
    pub description: String,
    pub input_schema: serde_json::Value,
}

#[derive(Debug, Clone)]
pub struct RequestConfig {
    pub max_tokens: u32,
    pub tools: Vec<ToolDef>,
}

#[async_trait]
pub trait LlmProvider: Send + Sync {
    async fn send(
        &self,
        messages: &[crate::agent::Message],
        config: &RequestConfig,
    ) -> Result<crate::agent::LlmResponse>;
    fn name(&self) -> &str;
}
