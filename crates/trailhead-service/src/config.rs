use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrailheadConfig {
    pub model: Option<String>,
    #[serde(default)]
    pub provider: HashMap<String, ProviderConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProviderConfig {
    pub api: String,
    #[serde(default)]
    pub base_url: Option<String>,
    #[serde(default)]
    pub env: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct ResolvedModel {
    pub provider_id: String,
    pub model_id: String,
    pub api: String,
    pub base_url: String,
}

impl TrailheadConfig {
    pub fn load(path: &Path) -> Result<Self> {
        let content = std::fs::read_to_string(path)
            .with_context(|| format!("read config from {}", path.display()))?;
        toml::from_str(&content).with_context(|| "parse trailhead.toml".to_string())
    }

    pub fn resolve_model(&self, stage_model: Option<&str>) -> Result<ResolvedModel> {
        let model_ref = stage_model
            .or(self.model.as_deref())
            .ok_or_else(|| anyhow::anyhow!("no model configured: set model in trailhead.toml or workflow stage"))?;

        let (provider_id, model_id) = model_ref
            .split_once('/')
            .ok_or_else(|| anyhow::anyhow!("model reference must be provider_id/model_id, got: {}", model_ref))?;

        let provider = self.provider.get(provider_id)
            .ok_or_else(|| anyhow::anyhow!("unknown provider: {}", provider_id))?;

        let base_url = provider.base_url.clone()
            .or_else(|| match provider.api.as_str() {
                "anthropic" => Some("https://api.anthropic.com".to_string()),
                "openai-compatible" => Some("https://api.openai.com/v1".to_string()),
                _ => None,
            })
            .ok_or_else(|| anyhow::anyhow!("no base_url for provider {}", provider_id))?;

        Ok(ResolvedModel {
            provider_id: provider_id.to_string(),
            model_id: model_id.to_string(),
            api: provider.api.clone(),
            base_url,
        })
    }
}
