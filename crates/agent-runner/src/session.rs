use crate::agent::TokenUsage;
use crate::agent::Message;
use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Session {
    pub id: String,
    pub messages: Vec<Message>,
    pub token_usage: TokenUsage,
    pub created_at: String,
}

impl Session {
    pub fn new(messages: Vec<Message>, token_usage: TokenUsage) -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            messages,
            token_usage,
            created_at: chrono_like_now(),
        }
    }

    pub fn save(&self, workspace: &Path) -> Result<()> {
        let session_path = workspace.join("session.json");
        let json = serde_json::to_string_pretty(self)?;
        std::fs::write(&session_path, json)?;
        Ok(())
    }

    pub fn load(workspace: &Path) -> Result<Self> {
        let session_path = workspace.join("session.json");
        if !session_path.exists() {
            return Err(anyhow!("session file not found: {}", session_path.display()));
        }
        let json = std::fs::read_to_string(&session_path)?;
        let session: Session = serde_json::from_str(&json)?;
        Ok(session)
    }
}

fn chrono_like_now() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let duration = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default();
    format!("{}", duration.as_secs())
}
