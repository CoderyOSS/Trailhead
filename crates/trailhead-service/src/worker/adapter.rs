use anyhow::{Context, Result};
use reqwest::header::{HeaderMap, HeaderValue};

use super::events::{self, WorkerEvent};

#[derive(Debug, Clone, serde::Serialize)]
pub struct PermissionRule {
    pub permission: String,
    pub pattern: String,
    pub action: String,
}

pub struct OpencodeAdapter {
    base_url: String,
    client: reqwest::Client,
}

impl OpencodeAdapter {
    pub fn new(base_url: String) -> Self {
        Self {
            base_url,
            client: reqwest::Client::new(),
        }
    }

    fn build_headers(&self) -> HeaderMap {
        let mut headers = HeaderMap::new();
        headers.insert(
            "x-opencode-directory",
            HeaderValue::from_static("/workspace"),
        );
        headers
    }

    pub async fn create_session(
        &self,
        title: &str,
        model_provider: &str,
        model_id: &str,
        permission_rules: Vec<PermissionRule>,
    ) -> Result<String> {
        #[derive(serde::Serialize)]
        struct ModelInfo {
            #[serde(rename = "providerID")]
            provider_id: String,
            id: String,
        }
        #[derive(serde::Serialize)]
        struct CreateSessionRequest {
            title: String,
            permission: Vec<PermissionRule>,
            model: ModelInfo,
        }

        let body = CreateSessionRequest {
            title: title.to_string(),
            permission: permission_rules,
            model: ModelInfo {
                provider_id: model_provider.to_string(),
                id: model_id.to_string(),
            },
        };

        let resp = self
            .client
            .post(format!("{}/session", self.base_url))
            .headers(self.build_headers())
            .json(&body)
            .send()
            .await
            .context("failed to create session")?;

        let session: serde_json::Value = resp
            .json()
            .await
            .context("failed to parse session response")?;

        session
            .get("id")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string())
            .ok_or_else(|| anyhow::anyhow!("session response missing id field"))
    }

    pub async fn send_prompt(&self, session_id: &str, message: &str) -> Result<()> {
        #[derive(serde::Serialize)]
        struct PromptPart {
            #[serde(rename = "type")]
            part_type: String,
            text: String,
        }
        #[derive(serde::Serialize)]
        struct PromptRequest {
            parts: Vec<PromptPart>,
        }

        let body = PromptRequest {
            parts: vec![PromptPart {
                part_type: "text".to_string(),
                text: message.to_string(),
            }],
        };

        self.client
            .post(format!(
                "{}/session/{}/prompt_async",
                self.base_url, session_id
            ))
            .headers(self.build_headers())
            .json(&body)
            .send()
            .await
            .context("failed to send prompt")?;

        Ok(())
    }

    pub async fn abort_session(&self, session_id: &str) -> Result<()> {
        self.client
            .post(format!("{}/session/{}/abort", self.base_url, session_id))
            .headers(self.build_headers())
            .send()
            .await
            .context("failed to abort session")?;

        Ok(())
    }

    pub async fn reply_permission(&self, request_id: &str, reply: &str) -> Result<()> {
        #[derive(serde::Serialize)]
        struct ReplyRequest {
            reply: String,
        }

        self.client
            .post(format!("{}/permission/{}/reply", self.base_url, request_id))
            .headers(self.build_headers())
            .json(&ReplyRequest {
                reply: reply.to_string(),
            })
            .send()
            .await
            .context("failed to reply to permission request")?;

        Ok(())
    }

    pub async fn get_messages(&self, session_id: &str) -> Result<Vec<serde_json::Value>> {
        let resp = self
            .client
            .get(format!("{}/session/{}/message", self.base_url, session_id))
            .headers(self.build_headers())
            .send()
            .await
            .context("failed to get messages")?;

        let messages: serde_json::Value = resp
            .json()
            .await
            .context("failed to parse messages response")?;

        match messages {
            serde_json::Value::Array(arr) => Ok(arr),
            other => {
                if let Some(arr) = other.get("messages").and_then(|v| v.as_array()) {
                    Ok(arr.clone())
                } else {
                    Ok(vec![other])
                }
            }
        }
    }

    pub async fn subscribe_events(&self) -> Result<reqwest::Response> {
        let resp = self
            .client
            .get(format!("{}/event", self.base_url))
            .headers(self.build_headers())
            .send()
            .await
            .context("failed to subscribe to events")?;

        Ok(resp)
    }

    pub async fn wait_for_idle(
        &self,
        session_id: &str,
        policy: &super::permission::PermissionPolicy,
    ) -> Result<()> {
        let resp = self.subscribe_events().await?;
        let mut stream = resp.bytes_stream();
        let mut buffer = String::new();

        use futures_util::StreamExt;

        while let Some(chunk) = stream.next().await {
            let chunk = chunk.context("error reading SSE stream")?;
            buffer.push_str(&String::from_utf8_lossy(&chunk));

            while let Some(pos) = buffer.find('\n') {
                let line = buffer[..pos].to_string();
                buffer = buffer[pos + 1..].to_string();

                if let Some(event) = events::parse_sse_line(&line) {
                    match event {
                        WorkerEvent::SessionStatus(evt)
                            if evt.session_id == session_id
                                && evt.status.status_type == "idle" =>
                        {
                            return Ok(());
                        }
                        WorkerEvent::PermissionAsked(evt) => {
                            let action = super::permission::decide(
                                &evt.permission,
                                &evt.patterns,
                                policy,
                            );
                            let reply = match action {
                                super::permission::PermissionAction::Approve => "always",
                                super::permission::PermissionAction::Reject { .. } => "reject",
                            };
                            self.reply_permission(&evt.id, reply).await?;
                        }
                        WorkerEvent::SessionError(evt)
                            if evt.session_id == session_id =>
                        {
                            return Err(anyhow::anyhow!("session error: {}", evt.error));
                        }
                        _ => {}
                    }
                }
            }
        }

        Err(anyhow::anyhow!("SSE stream ended without idle status"))
    }
}
