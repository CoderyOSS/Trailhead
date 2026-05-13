use anyhow::{anyhow, Result};

pub struct OpenAiProvider;

impl OpenAiProvider {
    pub fn new(_api_key: String, _model: String, _base_url: Option<String>) -> Result<Self> {
        Err(anyhow!("OpenAI provider not yet implemented"))
    }
}
