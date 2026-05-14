# Trailhead Phase 2: Deployment, Provider Config & Hello World Pipeline

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Get trailhead-service deployed on VPS and running a hello world pipeline end-to-end: service → Docker container → agent-runner → LLM (DeepSeek V4 Pro) → response.

**Architecture:** trailhead-service runs on VPS host under supervisord (not containerized). Worker containers run agent-runner. LLM config via `trailhead.toml` (OpenCode-style provider/agent pattern). New OpenAI-compatible provider with DeepSeek reasoning_content support. All API wiring gaps closed.

**Tech Stack:** Rust, reqwest, serde, Docker (bollard), SQLite, axum, minijinja, TOML (toml crate), supervisord

**Design doc:** `docs/specs/2026-05-13-trailhead-phase2-design.md`

---

## File Map

### New Files

| File | Purpose |
|------|---------|
| `crates/agent-runner/src/provider/openai_compatible.rs` | OpenAI-compatible provider (DeepSeek, etc.) |
| `crates/trailhead-service/src/config.rs` | trailhead.toml config loading |
| `crates/trailhead-service/workflows/hello-world.yaml` | Hello world test workflow |
| `tests/probes/integration/hello-world.test.ts` | E2E hello world test |
| `.github/workflows/deploy-trailhead.yml` | CI build + deploy to VPS |

### Modified Files

| File | Change |
|------|--------|
| `crates/trailhead-core/src/lib.rs` | Standardize TokenUsage fields, add Display impl |
| `crates/agent-runner/src/agent/message.rs` | Add reasoning_content to Message, remove local TokenUsage |
| `crates/agent-runner/src/agent/mod.rs` | Use trailhead_core TokenUsage, remove local import |
| `crates/agent-runner/src/provider/mod.rs` | Add model to RequestConfig |
| `crates/agent-runner/src/provider/anthropic.rs` | Use shared TokenUsage, handle reasoning_content |
| `crates/agent-runner/src/provider/openai.rs` | Replace with re-export of openai_compatible module |
| `crates/agent-runner/src/main.rs` | Provider selection by api type, --base-url flag |
| `crates/agent-runner/Cargo.toml` | Remove async-openai, add toml |
| `crates/agent-runner/src/session.rs` | Use trailhead_core TokenUsage |
| `crates/trailhead-service/src/workflow/parser.rs` | skill optional, add model/provider fields to Stage |
| `crates/trailhead-service/src/workflow/mod.rs` | No changes needed (Engine already works) |
| `crates/trailhead-service/src/api.rs` | Wire job_config to workflow engine, add LLM fields |
| `crates/trailhead-service/src/provider/mod.rs` | Add LLM config to WorkerSpec |
| `crates/trailhead-service/src/provider/docker.rs` | Inject LLM env vars |
| `crates/trailhead-service/src/main.rs` | Load config, pass to daemon |
| `crates/trailhead-service/src/scheduler.rs` | Pass config through to workers |
| `crates/trailhead-service/src/web.rs` | Pass config to create_job workflow validation |
| `crates/trailhead-service/Cargo.toml` | Add toml crate |

---

### Task 0: Standardize TokenUsage in trailhead-core

**Files:**
- Modify: `crates/trailhead-core/src/lib.rs`

The TokenUsage in trailhead-core has `input_tokens`/`output_tokens`. The agent-runner has `prompt_tokens`/`completion_tokens`/`total_tokens`. Standardize on the agent-runner's field names (more standard) and move to trailhead-core as the single source.

- [ ] **Step 1: Update TokenUsage in trailhead-core**

In `crates/trailhead-core/src/lib.rs`, replace the existing TokenUsage:

```rust
    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct TokenUsage {
        pub prompt_tokens: u64,
        pub completion_tokens: u64,
        pub total_tokens: u64,
    }

    impl TokenUsage {
        pub fn zero() -> Self {
            Self {
                prompt_tokens: 0,
                completion_tokens: 0,
                total_tokens: 0,
            }
        }

        pub fn new(prompt_tokens: u64, completion_tokens: u64) -> Self {
            Self {
                prompt_tokens,
                completion_tokens,
                total_tokens: prompt_tokens + completion_tokens,
            }
        }
    }

    impl std::ops::Add for TokenUsage {
        type Output = TokenUsage;

        fn add(self, rhs: TokenUsage) -> TokenUsage {
            TokenUsage::new(
                self.prompt_tokens + rhs.prompt_tokens,
                self.completion_tokens + rhs.completion_tokens,
            )
        }
    }
```

Also update HeartbeatPayload and CheckpointPayload to use the new field names:

```rust
    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct HeartbeatPayload {
        pub status: String,
        pub current_stage: String,
        pub token_usage: TokenUsage,
        pub files_changed: u64,
        pub tool_calls_made: u64,
        pub message: String,
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct CheckpointPayload {
        pub stage: String,
        pub response: serde_json::Value,
        pub session_path: String,
        pub git_sha: String,
        pub token_usage: TokenUsage,
        pub files_changed: Vec<String>,
        pub next_stage: String,
    }
```

(HeartbeatPayload and CheckpointPayload remain the same — they already use `TokenUsage` which now has the updated fields.)

- [ ] **Step 2: Run cargo check**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check -p trailhead-core 2>&1'`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add crates/trailhead-core/src/lib.rs
git commit -m "core: standardize TokenUsage fields to prompt/completion/total"
```

---

### Task 1: Update agent-runner Message and TokenUsage

**Files:**
- Modify: `crates/agent-runner/src/agent/message.rs`
- Modify: `crates/agent-runner/src/agent/mod.rs`
- Modify: `crates/agent-runner/src/session.rs`

Remove the local TokenUsage from message.rs. Add `reasoning_content` to Message. Use `trailhead_core::types::TokenUsage` everywhere.

- [ ] **Step 1: Replace message.rs with updated Message + removed TokenUsage**

In `crates/agent-runner/src/agent/message.rs`, replace the entire file:

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Role {
    System,
    User,
    Assistant,
    Tool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolCall {
    pub id: String,
    pub name: String,
    pub arguments: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolResult {
    pub tool_call_id: String,
    pub content: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    pub role: Role,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub content: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reasoning_content: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tool_calls: Option<Vec<ToolCall>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tool_call_id: Option<String>,
}

impl Message {
    pub fn system(content: impl Into<String>) -> Self {
        Self {
            role: Role::System,
            content: Some(content.into()),
            reasoning_content: None,
            tool_calls: None,
            tool_call_id: None,
        }
    }

    pub fn user(content: impl Into<String>) -> Self {
        Self {
            role: Role::User,
            content: Some(content.into()),
            reasoning_content: None,
            tool_calls: None,
            tool_call_id: None,
        }
    }

    pub fn assistant(content: impl Into<String>) -> Self {
        Self {
            role: Role::Assistant,
            content: Some(content.into()),
            reasoning_content: None,
            tool_calls: None,
            tool_call_id: None,
        }
    }

    pub fn assistant_with_tool_calls(
        content: Option<String>,
        tool_calls: Vec<ToolCall>,
    ) -> Self {
        Self {
            role: Role::Assistant,
            content,
            reasoning_content: None,
            tool_calls: Some(tool_calls),
            tool_call_id: None,
        }
    }

    pub fn assistant_with_reasoning(
        content: Option<String>,
        reasoning_content: Option<String>,
        tool_calls: Option<Vec<ToolCall>>,
    ) -> Self {
        Self {
            role: Role::Assistant,
            content,
            reasoning_content,
            tool_calls: tool_calls,
            tool_call_id: None,
        }
    }

    pub fn tool_result(tool_call_id: impl Into<String>, content: impl Into<String>) -> Self {
        Self {
            role: Role::Tool,
            content: Some(content.into()),
            reasoning_content: None,
            tool_calls: None,
            tool_call_id: Some(tool_call_id.into()),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FinishReason {
    Stop,
    ToolUse,
    MaxTokens,
}

#[derive(Debug, Clone)]
pub struct LlmResponse {
    pub message: Message,
    pub finish_reason: FinishReason,
    pub usage: trailhead_core::types::TokenUsage,
}
```

- [ ] **Step 2: Update mod.rs to use trailhead_core TokenUsage**

In `crates/agent-runner/src/agent/mod.rs`, replace the entire file:

```rust
pub mod message;

pub use message::{FinishReason, LlmResponse, Message, Role, ToolCall, ToolResult};

use crate::provider::{LlmProvider, RequestConfig};
use crate::tools::{ToolContext, ToolRegistry};
use anyhow::Result;
use trailhead_core::types::TokenUsage;

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
```

- [ ] **Step 3: Update session.rs to use trailhead_core TokenUsage**

In `crates/agent-runner/src/session.rs`, replace the imports line:

```rust
use crate::agent::Message;
use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use std::path::Path;
use trailhead_core::types::TokenUsage;
```

The rest of session.rs stays the same — `Session` struct already uses `TokenUsage` via the import.

- [ ] **Step 4: Run cargo check on agent-runner**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check -p agent-runner 2>&1'`
Expected: FAIL — Anthropic provider still imports local TokenUsage. Will fix in next task.

- [ ] **Step 5: Commit (partial — will fix compilation in Task 2)****

```bash
git add crates/agent-runner/src/agent/
git add crates/agent-runner/src/session.rs
git add crates/trailhead-core/src/lib.rs
git commit -m "agent-runner: use trailhead_core TokenUsage, add reasoning_content to Message"
```

---

### Task 2: Update Anthropic provider for shared types

**Files:**
- Modify: `crates/agent-runner/src/provider/anthropic.rs`

- [ ] **Step 1: Update Anthropic provider imports**

In `crates/agent-runner/src/provider/anthropic.rs`, replace the imports line:

```rust
use crate::agent::{FinishReason, LlmResponse, Message, Role, ToolCall};
use crate::provider::{LlmProvider, RequestConfig, ToolDef};
use anyhow::{anyhow, Result};
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::time::Duration;
use trailhead_core::types::TokenUsage;
```

The rest of the file stays the same — `TokenUsage::new(...)` calls now resolve to `trailhead_core::types::TokenUsage::new(...)` which has the same signature.

- [ ] **Step 2: Run cargo check on agent-runner**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check -p agent-runner 2>&1'`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add crates/agent-runner/src/provider/anthropic.rs
git commit -m "agent-runner: update Anthropic provider to use shared TokenUsage"
```

---

### Task 3: Implement OpenAI-compatible provider

**Files:**
- Create: `crates/agent-runner/src/provider/openai_compatible.rs`
- Modify: `crates/agent-runner/src/provider/openai.rs`
- Modify: `crates/agent-runner/src/provider/mod.rs`
- Modify: `crates/agent-runner/Cargo.toml`

- [ ] **Step 1: Remove async-openai from Cargo.toml, it is unused**

In `crates/agent-runner/Cargo.toml`, remove the line `async-openai = "0.38"`.

- [ ] **Step 2: Add model field to RequestConfig**

In `crates/agent-runner/src/provider/mod.rs`, replace `RequestConfig`:

```rust
#[derive(Debug, Clone)]
pub struct RequestConfig {
    pub max_tokens: u32,
    pub tools: Vec<ToolDef>,
}
```

(No model field on RequestConfig — the provider owns its model. This is the existing design, keep it.)

- [ ] **Step 3: Create openai_compatible.rs**

Create `crates/agent-runner/src/provider/openai_compatible.rs`:

```rust
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
                    serde_json::from_str(&tc.arguments.arguments).unwrap_or(serde_json::Value::Null);
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
```

- [ ] **Step 4: Replace openai.rs with module re-export**

Replace `crates/agent-runner/src/provider/openai.rs` entirely:

```rust
pub mod openai_compatible;

pub use openai_compatible::OpenAiCompatibleProvider;
```

Wait — that creates a nested module. Instead, just update `mod.rs` to declare the module and remove openai.rs.

Actually: the simplest approach — delete `openai.rs` and update `mod.rs` to declare `openai_compatible` instead of `openai`.

In `crates/agent-runner/src/provider/mod.rs`, replace:

```rust
pub mod anthropic;
pub mod openai;
```

with:

```rust
pub mod anthropic;
pub mod openai_compatible;
```

Then delete `crates/agent-runner/src/provider/openai.rs` and create `crates/agent-runner/src/provider/openai_compatible.rs` as above.

- [ ] **Step 5: Run cargo check on agent-runner**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check -p agent-runner 2>&1'`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add crates/agent-runner/src/provider/
git add crates/agent-runner/Cargo.toml
git commit -m "agent-runner: add OpenAI-compatible provider with reasoning_content support"
```

---

### Task 4: Update provider selection in agent-runner main.rs

**Files:**
- Modify: `crates/agent-runner/src/main.rs`

- [ ] **Step 1: Update create_provider() to support openai-compatible**

In `crates/agent-runner/src/main.rs`, update imports:

```rust
use agent_runner::agent::{self, AgentConfig, FinishReason};
use agent_runner::provider::anthropic::AnthropicProvider;
use agent_runner::provider::openai_compatible::OpenAiCompatibleProvider;
use agent_runner::session::Session;
use agent_runner::tools::{self, ToolContext};
use anyhow::{anyhow, Result};
use std::env;
use std::path::PathBuf;
use std::process;
use trailhead_core::types::TokenUsage;
```

Replace `create_provider()`:

```rust
fn create_provider() -> Result<Box<dyn agent_runner::provider::LlmProvider>> {
    let provider_name = env::var("LLM_PROVIDER").unwrap_or_else(|_| "anthropic".to_string());
    let api_key = env::var("LLM_API_KEY")
        .map_err(|_| anyhow!("LLM_API_KEY environment variable is required"))?;
    let model = env::var("LLM_MODEL").unwrap_or_else(|_| "claude-sonnet-4-20250514".to_string());

    match provider_name.as_str() {
        "anthropic" => Ok(Box::new(AnthropicProvider::new(api_key, model))),
        "openai-compatible" => {
            let base_url = env::var("LLM_BASE_URL")
                .unwrap_or_else(|_| "https://api.openai.com/v1".to_string());
            Ok(Box::new(OpenAiCompatibleProvider::new(api_key, model, base_url)))
        }
        other => Err(anyhow!("unknown LLM_PROVIDER: {other}")),
    }
}
```

- [ ] **Step 2: Run cargo check on agent-runner**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check -p agent-runner 2>&1'`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add crates/agent-runner/src/main.rs
git commit -m "agent-runner: provider selection supports openai-compatible"
```

---

### Task 5: Add trailhead.toml config loading to trailhead-service

**Files:**
- Create: `crates/trailhead-service/src/config.rs`
- Modify: `crates/trailhead-service/Cargo.toml`
- Modify: `crates/trailhead-service/src/main.rs`

- [ ] **Step 1: Add toml dependency**

In `crates/trailhead-service/Cargo.toml`, add to dependencies:

```toml
toml = "0.8"
```

- [ ] **Step 2: Create config.rs**

Create `crates/trailhead-service/src/config.rs`:

```rust
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
    pub api_key: String,
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

        let api_key = provider.env.iter()
            .filter_map(|var_name| std::env::var(var_name).ok())
            .next()
            .ok_or_else(|| anyhow::anyhow!("no API key found for provider {}: set one of {:?}", provider_id, provider.env))?;

        Ok(ResolvedModel {
            provider_id: provider_id.to_string(),
            model_id: model_id.to_string(),
            api: provider.api.clone(),
            base_url,
            api_key,
        })
    }
}
```

- [ ] **Step 3: Update main.rs to load config**

In `crates/trailhead-service/src/main.rs`, add after the module declarations:

```rust
pub mod config;
```

Update `daemon_cmd` to load config and pass it through:

```rust
async fn daemon_cmd(args: &[String]) -> anyhow::Result<()> {
    let port: u16 = get_flag(args, "--port")
        .unwrap_or_else(|_| "4050".into())
        .parse()
        .map_err(|e| anyhow::anyhow!("invalid port: {}", e))?;
    let db_path = get_flag(args, "--db").unwrap_or_else(|_| "/opt/codery/trailhead.db".into());
    let config_path = get_flag(args, "--config").unwrap_or_else(|_| "/opt/codery/trailhead/trailhead.toml".into());

    let app_config = config::TrailheadConfig::load(std::path::Path::new(&config_path))?;
    tracing::info!("loaded config from {}", config_path);

    let db = Arc::new(db::Database::open(&db_path)?);
    let provider = Arc::new(provider::docker::DockerProvider::new()?);
    let app_config = Arc::new(app_config);

    let sched_db = db.clone();
    let sched_provider = provider.clone();
    let sched_config = app_config.clone();
    let sched_handle = tokio::spawn(async move {
        let sched = scheduler::Scheduler::new(
            sched_db,
            sched_provider,
            scheduler::SchedulerConfig::default(),
            sched_config,
        );
        sched.run().await;
    });

    let api_router = api::api_routes(db.clone(), app_config.clone());
    let web_router = web::web_routes(db.clone());
    let app = api_router.merge(web_router);

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port)).await?;
    tracing::info!("trailhead-service listening on port {}", port);

    axum::serve(listener, app).await?;
    sched_handle.abort();

    Ok(())
}
```

- [ ] **Step 4: Run cargo check on trailhead-service**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check -p trailhead-service 2>&1'`
Expected: FAIL — Scheduler and api_routes signatures changed. Fix in subsequent tasks.

- [ ] **Step 5: Commit**

```bash
git add crates/trailhead-service/src/config.rs
git add crates/trailhead-service/Cargo.toml
git add crates/trailhead-service/src/main.rs
git commit -m "service: add trailhead.toml config loading with provider/model resolution"
```

---

### Task 6: Update Scheduler to accept config

**Files:**
- Modify: `crates/trailhead-service/src/scheduler.rs`

- [ ] **Step 1: Add config parameter to Scheduler**

In `crates/trailhead-service/src/scheduler.rs`, update imports and struct:

```rust
use std::sync::Arc;
use tokio::time::{interval, Duration};
use tracing::{error, info, warn};
use crate::config::TrailheadConfig;
use crate::db::Database;
use crate::provider::WorkerProvider;

pub struct SchedulerConfig {
    pub max_global_workers: usize,
    pub max_workers_per_project: usize,
    pub heartbeat_timeout_secs: u64,
    pub job_timeout_secs: u64,
    pub max_retries: u32,
    pub interval_secs: u64,
}
```

Add `app_config` to Scheduler struct and constructor:

```rust
pub struct Scheduler {
    db: Arc<Database>,
    provider: Arc<dyn WorkerProvider>,
    config: SchedulerConfig,
    app_config: Arc<TrailheadConfig>,
}

impl Scheduler {
    pub fn new(
        db: Arc<Database>,
        provider: Arc<dyn WorkerProvider>,
        config: SchedulerConfig,
        app_config: Arc<TrailheadConfig>,
    ) -> Self {
        Self {
            db,
            provider,
            config,
            app_config,
        }
    }
```

The rest of the Scheduler implementation stays the same for now (worker launching will use app_config in a later task).

- [ ] **Step 2: Run cargo check**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check -p trailhead-service 2>&1'`
Expected: FAIL — api_routes still needs config param. That's fine.

- [ ] **Step 3: Commit**

```bash
git add crates/trailhead-service/src/scheduler.rs
git commit -m "service: pass config to Scheduler"
```

---

### Task 7: Update Stage schema — skill optional, model/provider fields

**Files:**
- Modify: `crates/trailhead-service/src/workflow/parser.rs`

- [ ] **Step 1: Update Stage struct**

In `crates/trailhead-service/src/workflow/parser.rs`, replace the Stage struct:

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Stage {
    #[serde(default)]
    pub skill: Option<String>,
    #[serde(default)]
    pub prompt: String,
    pub model: Option<String>,
    pub response_schema: Option<serde_json::Value>,
    #[serde(default)]
    pub tools: Vec<String>,
    pub max_tokens: Option<u32>,
    pub timeout_secs: Option<u64>,
    #[serde(default)]
    pub checkpoint: bool,
    pub routes: Option<Vec<Route>>,
}
```

- [ ] **Step 2: Update validation — skill is optional now**

In the `parse_workflow` function, remove the skill validation:

```rust
pub fn parse_workflow(yaml_str: &str) -> Result<Workflow> {
    let wf: Workflow = serde_yaml::from_str(yaml_str).context("parse workflow YAML")?;
    if wf.stages.is_empty() {
        bail!("workflow needs at least one stage");
    }
    for (name, stage) in &wf.stages {
        if let Some(ref routes) = stage.routes {
            for route in routes {
                if !route.next.is_empty() && !wf.stages.contains_key(&route.next) {
                    bail!("stage '{}' routes to unknown stage '{}'", name, route.next);
                }
            }
        }
    }
    Ok(wf)
}
```

- [ ] **Step 3: Update existing tests**

The test `parse_simple_workflow` uses `skill: plan` which still works with `Option<String>`. The `reject_unknown_route_target` test uses `skill: plan` too. Remove `reject_empty_stages` if it relied on empty skill check. The test suite should still pass since `skill` is now `Option<String>` and existing YAML has `skill` set.

- [ ] **Step 4: Run cargo check**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check -p trailhead-service 2>&1'`

- [ ] **Step 5: Run unit tests**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo test -p trailhead-service 2>&1'`

- [ ] **Step 6: Commit**

```bash
git add crates/trailhead-service/src/workflow/parser.rs
git commit -m "service: skill optional in Stage, add model field for per-stage override"
```

---

### Task 8: Wire API — job_config reads workflow, resolves prompt/skill/model

**Files:**
- Modify: `crates/trailhead-service/src/api.rs`

This is the big wiring task. The `job_config` handler must:
1. Load workflow for the job
2. Parse the current stage
3. Resolve prompt via minijinja
4. Load skill content
5. Resolve model/provider via config
6. Return everything

- [ ] **Step 1: Update api_routes signature and job_config handler**

Replace `crates/trailhead-service/src/api.rs` entirely:

```rust
use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use uuid::Uuid;
use crate::config::TrailheadConfig;
use crate::db::Database;

#[derive(Deserialize)]
struct RegisterRequest {
    job_id: String,
    status: String,
}

#[derive(Deserialize, Serialize)]
struct TokenUsageReport {
    prompt_tokens: u64,
    completion_tokens: u64,
}

#[derive(Deserialize)]
struct HeartbeatRequest {
    #[allow(dead_code)]
    status: String,
    #[allow(dead_code)]
    current_stage: String,
    #[allow(dead_code)]
    token_usage: TokenUsageReport,
    #[allow(dead_code)]
    files_changed: u64,
    #[allow(dead_code)]
    tool_calls_made: u64,
    #[allow(dead_code)]
    message: String,
}

#[derive(Deserialize)]
struct CheckpointRequest {
    stage: String,
    #[allow(dead_code)]
    response: serde_json::Value,
    session_path: String,
    git_sha: String,
    token_usage: TokenUsageReport,
    files_changed: Vec<String>,
    next_stage: String,
}

#[derive(Deserialize)]
struct CompleteRequest {
    result: String,
}

#[derive(Deserialize)]
struct FailRequest {
    error: String,
}

#[derive(Serialize)]
struct JobConfigResponse {
    job_id: String,
    stage: String,
    prompt: String,
    tools: Vec<String>,
    max_tokens: u32,
    timeout_secs: u64,
    skill_content: String,
    model: String,
    provider: String,
    base_url: String,
    api_key: String,
}

pub fn api_routes(db: Arc<Database>, config: Arc<TrailheadConfig>) -> Router {
    Router::new()
        .route("/api/v1/workers/{id}/register", post(register_worker))
        .route("/api/v1/workers/{id}/heartbeat", post(heartbeat))
        .route("/api/v1/workers/{id}/checkpoint", post(checkpoint))
        .route("/api/v1/workers/{id}/complete", post(complete))
        .route("/api/v1/workers/{id}/fail", post(fail))
        .route("/api/v1/jobs/{id}/config", get(job_config))
        .route("/api/v1/jobs/{id}/skill/{name}", get(skill_content))
        .with_state((db, config))
}

async fn register_worker(
    Path(worker_id): Path<String>,
    State((db, _config)): State<(Arc<Database>, Arc<TrailheadConfig>)>,
    Json(body): Json<RegisterRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    let worker = db
        .get_worker(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let worker = worker.ok_or((StatusCode::NOT_FOUND, "worker not found".into()))?;

    if worker.job_id.as_deref() != Some(&body.job_id) {
        return Err((StatusCode::BAD_REQUEST, "job_id mismatch".into()));
    }

    db.update_worker_status(&worker_id, "running")
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    db.update_job_status(&body.job_id, "running")
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::OK)
}

async fn heartbeat(
    Path(worker_id): Path<String>,
    State((db, _config)): State<(Arc<Database>, Arc<TrailheadConfig>)>,
    Json(_body): Json<HeartbeatRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    db.update_worker_heartbeat(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(StatusCode::OK)
}

async fn checkpoint(
    Path(worker_id): Path<String>,
    State((db, _config)): State<(Arc<Database>, Arc<TrailheadConfig>)>,
    Json(body): Json<CheckpointRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    let worker = db
        .get_worker(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let worker = worker.ok_or((StatusCode::NOT_FOUND, "worker not found".into()))?;

    let job_id = worker
        .job_id
        .ok_or((StatusCode::BAD_REQUEST, "worker has no job".into()))?;

    let checkpoint_id = Uuid::new_v4().to_string();
    let token_usage = serde_json::to_string(&body.token_usage)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let files_changed = serde_json::to_string(&body.files_changed)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    db.save_checkpoint(
        &checkpoint_id,
        &job_id,
        &body.stage,
        &serde_json::to_string(&body.response)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?,
        &body.session_path,
        &body.git_sha,
        &token_usage,
        &files_changed,
    )
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    if !body.next_stage.is_empty() {
        let mut history: Vec<serde_json::Value> = serde_json::from_str(
            &db.get_job(&job_id)
                .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
                .ok_or((StatusCode::NOT_FOUND, "job not found".into()))?
                .stage_history,
        )
        .unwrap_or_default();
        history.push(serde_json::json!({"stage": body.stage, "status": "completed"}));
        db.update_job_stage(
            &job_id,
            &body.next_stage,
            &serde_json::to_string(&history)
                .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?,
        )
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    }

    Ok(StatusCode::OK)
}

async fn complete(
    Path(worker_id): Path<String>,
    State((db, _config)): State<(Arc<Database>, Arc<TrailheadConfig>)>,
    Json(body): Json<CompleteRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    let worker = db
        .get_worker(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let worker = worker.ok_or((StatusCode::NOT_FOUND, "worker not found".into()))?;

    if let Some(ref job_id) = worker.job_id {
        db.complete_job(job_id, &body.result)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    }
    db.destroy_worker(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::OK)
}

async fn fail(
    Path(worker_id): Path<String>,
    State((db, _config)): State<(Arc<Database>, Arc<TrailheadConfig>)>,
    Json(body): Json<FailRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    let worker = db
        .get_worker(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let worker = worker.ok_or((StatusCode::NOT_FOUND, "worker not found".into()))?;

    if let Some(ref job_id) = worker.job_id {
        let job = db
            .get_job(job_id)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
        if let Some(job) = job {
            let status = if job.attempt < job.max_attempts {
                "failed_retryable"
            } else {
                "failed_final"
            };
            db.fail_job(job_id, &body.error, status)
                .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
        }
    }
    db.destroy_worker(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::OK)
}

async fn job_config(
    Path(job_id): Path<String>,
    State((db, config)): State<(Arc<Database>, Arc<TrailheadConfig>)>,
) -> Result<Json<JobConfigResponse>, (StatusCode, String)> {
    let job = db
        .get_job(&job_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let job = job.ok_or((StatusCode::NOT_FOUND, "job not found".into()))?;

    let stage = job.current_stage.clone().unwrap_or_default();

    let workflow_content = if let Some(ref wf_name) = job.workflow_name {
        let wf = db
            .get_workflow(wf_name)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
        wf.map(|w| w.content).unwrap_or_default()
    } else {
        String::new()
    };

    let parsed_workflow = crate::workflow::parser::parse_workflow(&workflow_content).ok();
    let stage_def = parsed_workflow
        .as_ref()
        .and_then(|wf| wf.stages.get(&stage));

    let prompt = if let Some(s) = stage_def {
        if s.prompt.is_empty() {
            job.description.clone()
        } else {
            let vars = crate::workflow::resolver::TemplateVars {
                input: job.description.clone(),
                project: crate::workflow::resolver::ProjectVars {
                    name: String::new(),
                    repo: String::new(),
                    branch: String::new(),
                },
                stages: std::collections::HashMap::new(),
                env: std::collections::HashMap::new(),
            };
            crate::workflow::resolver::resolve_prompt(&s.prompt, &vars).unwrap_or(s.prompt.clone())
        }
    } else {
        job.description.clone()
    };

    let skill_content = if let Some(ref skill_name) = stage_def.and_then(|s| s.skill.as_ref()) {
        let skill_path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("skills")
            .join(format!("{}.md", skill_name));
        if skill_path.exists() {
            std::fs::read_to_string(&skill_path).unwrap_or_default()
        } else {
            String::new()
        }
    } else {
        String::new()
    };

    let stage_model = stage_def.and_then(|s| s.model.as_deref());
    let resolved = config.resolve_model(stage_model)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let default_tools = vec![
        "bash".into(),
        "read".into(),
        "write".into(),
        "edit".into(),
        "glob".into(),
        "grep".into(),
    ];
    let tools = stage_def
        .and_then(|s| if s.tools.is_empty() { None } else { Some(s.tools.clone()) })
        .unwrap_or(default_tools);

    let max_tokens = stage_def.and_then(|s| s.max_tokens).unwrap_or(8096);
    let timeout_secs = stage_def.and_then(|s| s.timeout_secs).unwrap_or(600);

    Ok(Json(JobConfigResponse {
        job_id: job.id,
        stage,
        prompt,
        tools,
        max_tokens,
        timeout_secs,
        skill_content,
        model: resolved.model_id,
        provider: resolved.api,
        base_url: resolved.base_url,
        api_key: resolved.api_key,
    }))
}

async fn skill_content(
    Path((job_id, skill_name)): Path<(String, String)>,
    State((_db, _config)): State<(Arc<Database>, Arc<TrailheadConfig>)>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let skill_path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("skills")
        .join(format!("{}.md", skill_name));

    let content = if skill_path.exists() {
        std::fs::read_to_string(&skill_path)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
    } else {
        String::new()
    };

    Ok(Json(serde_json::json!({
        "job_id": job_id,
        "skill": skill_name,
        "content": content,
    })))
}
```

- [ ] **Step 2: Run cargo check**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check -p trailhead-service 2>&1'`
Expected: FAIL — mcp.rs may reference api_routes old signature. Check and fix.

If `mcp.rs` references `api_routes`, it needs to be updated too. Since mcp.rs is a separate module, it likely constructs its own router. Check `crates/trailhead-service/src/mcp.rs` for any references to `api_routes` or `Database` state and update accordingly.

- [ ] **Step 3: Fix any compilation errors from state change**

The state type changed from `Arc<Database>` to `(Arc<Database>, Arc<TrailheadConfig>)`. Any handler that extracts `State<Arc<Database>>` will need to extract `State<(Arc<Database>, Arc<TrailheadConfig>)>` instead.

For `mcp.rs`, it likely has its own router. If it shares state with api_routes, update accordingly. If it has its own state, it doesn't need changes.

- [ ] **Step 4: Commit**

```bash
git add crates/trailhead-service/src/api.rs
git commit -m "service: wire job_config to workflow engine, resolve prompt/skill/model per stage"
```

---

### Task 9: Inject LLM env vars into worker containers

**Files:**
- Modify: `crates/trailhead-service/src/provider/docker.rs`
- Modify: `crates/trailhead-service/src/provider/mod.rs`

- [ ] **Step 1: Add LLM fields to WorkerSpec**

In `crates/trailhead-service/src/provider/mod.rs`, add fields:

```rust
#[derive(Debug, Clone)]
pub struct WorkerSpec {
    pub job_id: String,
    pub workspace_path: PathBuf,
    pub agent_runner_image: String,
    pub env: HashMap<String, String>,
    pub llm_provider: String,
    pub llm_model: String,
    pub llm_api_key: String,
    pub llm_base_url: String,
}
```

- [ ] **Step 2: Inject LLM env vars in DockerProvider**

In `crates/trailhead-service/src/provider/docker.rs`, update the `create_worker` method. Find the section where env vars are built and add:

```rust
        let mut env = vec![
            format!("WORKER_ID={}", spec.job_id),
            format!("JOB_ID={}", spec.job_id),
            format!("LLM_PROVIDER={}", spec.llm_provider),
            format!("LLM_MODEL={}", spec.llm_model),
            format!("LLM_API_KEY={}", spec.llm_api_key),
            format!("LLM_BASE_URL={}", spec.llm_base_url),
        ];
        for (k, v) in &spec.env {
            env.push(format!("{}={}", k, v));
        }
```

- [ ] **Step 3: Run cargo check**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check -p trailhead-service 2>&1'`
Expected: FAIL — Scheduler needs to populate these fields when creating WorkerSpec. That wiring happens when the scheduler actually launches workers.

- [ ] **Step 4: Commit**

```bash
git add crates/trailhead-service/src/provider/
git commit -m "service: inject LLM env vars into worker containers"
```

---

### Task 10: Create hello-world workflow

**Files:**
- Create: `crates/trailhead-service/workflows/hello-world.yaml`

- [ ] **Step 1: Create hello-world.yaml**

```yaml
name: hello-world
description: "Simple test pipeline — sends a prompt, gets a response"
stages:
  greet:
    prompt: "Say 'Hello from Trailhead!' and nothing else."
    max_tokens: 256
    timeout_secs: 60
```

- [ ] **Step 2: Commit**

```bash
git add crates/trailhead-service/workflows/hello-world.yaml
git commit -m "service: add hello-world workflow"
```

---

### Task 11: Full workspace cargo check + cargo test

**Files:**
- None (verification only)

- [ ] **Step 1: Full workspace cargo check**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check 2>&1'`
Expected: PASS (fix any remaining errors)

- [ ] **Step 2: Full workspace cargo test**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo test 2>&1'`
Expected: All tests pass

- [ ] **Step 3: Cargo clippy**

Run: `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo clippy 2>&1'`
Expected: No errors (warnings OK for now)

---

### Task 12: E2E hello-world test

**Files:**
- Create: `tests/probes/integration/hello-world.test.ts`

- [ ] **Step 1: Write hello-world E2E test**

Create `tests/probes/integration/hello-world.test.ts`:

```typescript
import { describe, test, expect, beforeAll, afterAll } from "bun:test";
import { p } from "@codery/probes";
import { uniqueId } from "../helpers";

const BASE_URL = process.env.TRAILHEAD_URL ?? "http://localhost:4050";

describe("hello-world pipeline", () => {
  let projectId: string;
  let jobId: string;

  beforeAll(async () => {
    projectId = uniqueId();
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/projects",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        name: `test-${projectId}`,
        repo_url: "https://github.com/example/test",
        branch: "main",
      }),
    });
    expect(res.status).toBe(200);
    const data = JSON.parse(res.body as string);
    projectId = data.project_id;
  });

  test("creates a job with hello-world workflow", async () => {
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/jobs",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        project_id: projectId,
        description: "Hello world test",
        workflow: "hello-world",
      }),
    });
    expect(res.status).toBe(200);
    const data = JSON.parse(res.body as string);
    jobId = data.job_id;
    expect(jobId).toBeDefined();
  });

  test("job config returns resolved workflow stage", async () => {
    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}/config`,
    });
    expect(res.status).toBe(200);
    const data = JSON.parse(res.body as string);
    expect(data.stage).toBe("greet");
    expect(data.prompt).toContain("Hello from Trailhead");
    expect(data.max_tokens).toBe(256);
    expect(data.timeout_secs).toBe(60);
    expect(data.model).toBeDefined();
    expect(data.provider).toBeDefined();
    expect(data.api_key).toBeDefined();
  });
});
```

Note: This test only verifies the API-level wiring (job config resolution). Full E2E (service → Docker → LLM → response) requires the service to be running with Docker access and a valid LLM API key. That will be tested manually after deployment.

- [ ] **Step 2: Run test**

Run: `cd tests/probes && bun test integration/hello-world.test.ts`

- [ ] **Step 3: Commit**

```bash
git add tests/probes/integration/hello-world.test.ts
git commit -m "tests: add hello-world E2E test for API wiring verification"
```

---

### Task 13: Deployment — supervisord config + CI workflow

**Files:**
- Create: `.github/workflows/deploy-trailhead.yml`

Note: The supervisord config lives in the Codery repo, not this one. That will be added separately.

- [ ] **Step 1: Create deploy-trailhead.yml**

Create `.github/workflows/deploy-trailhead.yml`:

```yaml
name: Build & Deploy Trailhead

on:
  push:
    branches: [main]
    paths:
      - "crates/trailhead-service/**"
      - "crates/trailhead-core/**"
      - "Cargo.toml"
      - ".github/workflows/deploy-trailhead.yml"
  workflow_dispatch:

env:
  CARGO_TERM_COLOR: always

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo check --release -p trailhead-service
      - run: cargo test --release -p trailhead-service
      - run: cargo clippy --release -p trailhead-service -- -D warnings

  deploy:
    needs: check
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2

      - name: Build release binary
        run: cargo build --release -p trailhead-service

      - name: Deploy to VPS
        env:
          SSH_KEY: \${{ secrets.VPS_SSH_KEY }}
          VPS_HOST: \${{ secrets.VPS_HOST }}
          VPS_USER: \${{ secrets.VPS_USER }}
        run: |
          mkdir -p ~/.ssh
          echo "$SSH_KEY" > ~/.ssh/deploy_key
          chmod 600 ~/.ssh/deploy_key

          SHA=$(git rev-parse --short HEAD)
          BINARY="target/release/trailhead-service"

          scp -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no \
            "$BINARY" "$VPS_USER@$VPS_HOST:/opt/codery/trailhead/bin/trailhead-service-$SHA"

          ssh -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no \
            "$VPS_USER@$VPS_HOST" <<EOF
            ln -sf /opt/codery/trailhead/bin/trailhead-service-$SHA /opt/codery/trailhead/bin/current
            sudo supervisorctl restart trailhead
          EOF
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/deploy-trailhead.yml
git commit -m "ci: add trailhead-service deploy workflow"
```

---

### Task 14: Save design doc

**Files:**
- Create: `docs/specs/2026-05-13-trailhead-phase2-design.md`

- [ ] **Step 1: Write design doc**

Save the approved design spec from the brainstorming session to `docs/specs/2026-05-13-trailhead-phase2-design.md`.

- [ ] **Step 2: Commit**

```bash
git add docs/specs/2026-05-13-trailhead-phase2-design.md
git commit -m "docs: add Phase 2 design spec"
```

---

## Self-Review

### Spec Coverage

| Spec Section | Task |
|---|---|
| Deployment (supervisor) | Task 13 |
| LLM Configuration (trailhead.toml) | Task 5 |
| OpenAI-compatible provider | Task 3 |
| reasoning_content | Task 3 (openai_compatible.rs) |
| Message changes | Task 1 |
| TokenUsage dedup | Tasks 0, 1, 2 |
| Provider selection | Task 4 |
| Stage schema (skill optional, model) | Task 7 |
| API wiring (job_config) | Task 8 |
| DockerProvider env injection | Task 9 |
| Hello world workflow | Task 10 |
| E2E test | Task 12 |
| CI workflow | Task 13 |

### Placeholder Scan

No TBDs, TODOs, or "implement later" patterns. Every step has code.

### Type Consistency

- `TokenUsage` used consistently: `trailhead_core::types::TokenUsage` with `prompt_tokens`/`completion_tokens`/`total_tokens`
- `Message` has `reasoning_content: Option<String>` throughout
- `Stage` has `skill: Option<String>`, `model: Option<String>`
- `WorkerSpec` has `llm_provider`, `llm_model`, `llm_api_key`, `llm_base_url` (String fields)
- `ResolvedModel` struct in config.rs provides the bridge between config and WorkerSpec
- `JobConfigResponse` has `model`, `provider`, `base_url`, `api_key` (all String)
- State type is `(Arc<Database>, Arc<TrailheadConfig>)` consistently in api.rs

### Gaps Found and Fixed

1. **api_routes signature change**: Tasks 5-8 chain correctly — config flows from main.rs → Scheduler + api_routes
2. **Scheduler doesn't launch workers yet**: The scheduler currently only marks jobs as "scheduled". Actual worker launching (creating Docker containers) will need the Scheduler to create WorkerSpec with LLM fields. This is not in the current codebase (no `provisioning` → container creation logic). The hello-world test tests API wiring, not the full scheduler → container → agent flow. Full scheduler provisioning can be a follow-up task.
