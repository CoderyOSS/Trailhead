# Trailhead Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Trailhead — a standalone worker-service and agent-runner that execute autonomous, workflow-driven coding tasks in ephemeral Docker containers.

**Architecture:** Cargo workspace with three crates: `trailhead-core` (shared types), `agent-runner` (LLM tool-execution loop for worker containers), `trailhead-service` (job scheduling, worker lifecycle, workflow engine, MCP, dashboard on host). SQLite for state. Docker for workers. CEL for workflow routing.

**Tech Stack:** Rust, tokio, bollard (Docker), rusqlite (SQLite), rmcp (MCP), axum (HTTP), cel (routing), minijinja (templates), reqwest + async-openai (LLM), React + Vite (dashboard)

---

## File Structure

```
~/projects/CoderyTrailhead/
├── Cargo.toml                          # Workspace root
├── crates/
│   ├── trailhead-core/
│   │   ├── Cargo.toml
│   │   └── src/lib.rs
│   ├── trailhead-service/
│   │   ├── Cargo.toml
│   │   ├── src/
│   │   │   ├── main.rs
│   │   │   ├── db.rs
│   │   │   ├── jobs.rs
│   │   │   ├── scheduler.rs
│   │   │   ├── workers.rs
│   │   │   ├── workflow/
│   │   │   │   ├── mod.rs
│   │   │   │   ├── parser.rs
│   │   │   │   ├── resolver.rs
│   │   │   │   └── router.rs
│   │   │   ├── provider/
│   │   │   │   ├── mod.rs
│   │   │   │   └── docker.rs
│   │   │   ├── ide/
│   │   │   │   ├── mod.rs
│   │   │   │   ├── opencode.rs
│   │   │   │   ├── cursor.rs
│   │   │   │   ├── vscode.rs
│   │   │   │   ├── shell.rs
│   │   │   │   └── ssh.rs
│   │   │   ├── mcp.rs
│   │   │   ├── web.rs
│   │   │   └── api.rs
│   │   ├── skills/
│   │   │   ├── plan.md
│   │   │   ├── plan_detail.md
│   │   │   ├── implement.md
│   │   │   ├── test.md
│   │   │   ├── fix.md
│   │   │   ├── review.md
│   │   │   ├── create_pr.md
│   │   │   └── pause.md
│   │   ├── workflows/
│   │   │   ├── feature.yaml
│   │   │   ├── quick-fix.yaml
│   │   │   ├── exploration.yaml
│   │   │   └── refactor.yaml
│   │   └── ui/
│   │       ├── index.html
│   │       ├── package.json
│   │       ├── vite.config.ts
│   │       └── src/
│   │           ├── main.tsx
│   │           ├── App.tsx
│   │           ├── JobList.tsx
│   │           ├── WorkerList.tsx
│   │           └── types.ts
│   └── agent-runner/
│       ├── Cargo.toml
│       └── src/
│           ├── main.rs
│           ├── lib.rs
│           ├── provider/
│           │   ├── mod.rs
│           │   ├── anthropic.rs
│           │   └── openai.rs
│           ├── agent/
│           │   ├── mod.rs
│           │   └── message.rs
│           ├── tools/
│           │   ├── mod.rs
│           │   ├── bash.rs
│           │   ├── file_read.rs
│           │   ├── file_write.rs
│           │   ├── file_edit.rs
│           │   ├── glob.rs
│           │   └── grep.rs
│           └── session.rs
└── docs/
    └── specs/
        └── 2026-05-12-trailhead-phase1-design.md
```

---

## Task Group A: Foundation

### Task 1: Scaffold Cargo Workspace

**Files:**
- Create: `Cargo.toml`
- Create: `crates/trailhead-core/Cargo.toml`
- Create: `crates/trailhead-core/src/lib.rs`
- Create: `crates/agent-runner/Cargo.toml`
- Create: `crates/trailhead-service/Cargo.toml`
- Create: `.gitignore`

- [ ] **Step 1: Create workspace Cargo.toml**

`Cargo.toml`:
```toml
[workspace]
resolver = "2"
members = [
    "crates/trailhead-core",
    "crates/agent-runner",
    "crates/trailhead-service",
]
```

- [ ] **Step 2: Create trailhead-core crate**

`crates/trailhead-core/Cargo.toml`:
```toml
[package]
name = "trailhead-core"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { version = "1", features = ["derive"] }
serde_json = "1"
uuid = { version = "1", features = ["v4"] }
anyhow = "1"
```

`crates/trailhead-core/src/lib.rs`:
```rust
pub mod types {
    use serde::{Deserialize, Serialize};
    use uuid::Uuid;

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct JobId(pub String);

    impl JobId {
        pub fn new() -> Self {
            Self(Uuid::new_v4().to_string())
        }
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct WorkerId(pub String);

    impl WorkerId {
        pub fn new() -> Self {
            Self(Uuid::new_v4().to_string())
        }
    }

    #[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
    #[serde(rename_all = "snake_case")]
    pub enum JobStatus {
        Queued,
        Scheduled,
        Provisioning,
        Running,
        Checkpointing,
        Paused,
        PausedForHuman,
        Resuming,
        FailedRetryable,
        FailedFinal,
        Completed,
        Cancelled,
    }

    #[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
    #[serde(rename_all = "snake_case")]
    pub enum WorkerStatus {
        Creating,
        Running,
        Idle,
        Stopping,
        Stopped,
        Failed(String),
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct TokenUsage {
        pub input_tokens: u64,
        pub output_tokens: u64,
    }

    impl TokenUsage {
        pub fn zero() -> Self {
            Self { input_tokens: 0, output_tokens: 0 }
        }
    }

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
}
```

- [ ] **Step 3: Create agent-runner Cargo.toml**

`crates/agent-runner/Cargo.toml`:
```toml
[package]
name = "agent-runner"
version = "0.1.0"
edition = "2021"

[dependencies]
trailhead-core = { path = "../trailhead-core" }
tokio = { version = "1", features = ["full"] }
reqwest = { version = "0.12", features = ["json", "stream"] }
async-openai = "0.38"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
async-trait = "0.1"
uuid = { version = "1", features = ["v4"] }
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
anyhow = "1"
glob = "0.3"
regex = "1"
similar = "2"
futures-util = "0.3"

[dev-dependencies]
tempfile = "3"
```

- [ ] **Step 4: Create trailhead-service Cargo.toml**

`crates/trailhead-service/Cargo.toml`:
```toml
[package]
name = "trailhead-service"
version = "0.1.0"
edition = "2021"

[dependencies]
trailhead-core = { path = "../trailhead-core" }
tokio = { version = "1", features = ["full"] }
bollard = "0.17"
rusqlite = { version = "0.32", features = ["bundled"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
serde_yaml = "0.9"
cel = "0.13"
rmcp = { version = "1", features = ["server", "streamable-http-server", "schemars"] }
axum = { version = "0.8", features = ["http1", "tokio"] }
tokio-util = { version = "0.7", features = ["rt"] }
uuid = { version = "1", features = ["v4"] }
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
anyhow = "1"
minijinja = "2"
schemars = "1"
chrono = "0.4"

[dev-dependencies]
tempfile = "3"
```

- [ ] **Step 5: Create stub main.rs for each crate**

`crates/agent-runner/src/main.rs`:
```rust
fn main() {
    println!("agent-runner stub");
}
```

`crates/trailhead-service/src/main.rs`:
```rust
fn main() {
    println!("trailhead-service stub");
}
```

- [ ] **Step 6: Verify workspace compiles**

Run: `cargo check`
Expected: Compiles with no errors.

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat: scaffold Cargo workspace with three crates"
```

---

## Task Group B: Agent Runner

### Task 2: Message Types

**Files:**
- Create: `crates/agent-runner/src/lib.rs`
- Create: `crates/agent-runner/src/agent/mod.rs`
- Create: `crates/agent-runner/src/agent/message.rs`
- Create: `crates/agent-runner/src/provider/mod.rs` (empty trait stub)
- Create: `crates/agent-runner/src/tools/mod.rs` (empty trait stub)
- Create: `crates/agent-runner/src/session.rs` (empty stub)

- [ ] **Step 1: Create lib.rs with module declarations**

`crates/agent-runner/src/lib.rs`:
```rust
pub mod agent;
pub mod provider;
pub mod session;
pub mod tools;
```

- [ ] **Step 2: Write message types**

`crates/agent-runner/src/agent/message.rs`:
```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    pub role: Role,
    pub content: Option<String>,
    pub tool_calls: Option<Vec<ToolCall>>,
    pub tool_call_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
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
    pub is_error: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum FinishReason {
    Stop,
    ToolUse,
    MaxTokens,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LlmResponse {
    pub message: Message,
    pub finish_reason: FinishReason,
    pub usage: crate::provider::TokenUsage,
}

impl Message {
    pub fn system(content: impl Into<String>) -> Self {
        Self { role: Role::System, content: Some(content.into()), tool_calls: None, tool_call_id: None }
    }

    pub fn user(content: impl Into<String>) -> Self {
        Self { role: Role::User, content: Some(content.into()), tool_calls: None, tool_call_id: None }
    }

    pub fn assistant(content: impl Into<String>) -> Self {
        Self { role: Role::Assistant, content: Some(content.into()), tool_calls: None, tool_call_id: None }
    }

    pub fn assistant_with_tool_calls(tool_calls: Vec<ToolCall>) -> Self {
        Self { role: Role::Assistant, content: None, tool_calls: Some(tool_calls), tool_call_id: None }
    }

    pub fn tool_result(tool_call_id: impl Into<String>, content: impl Into<String>, is_error: bool) -> Self {
        Self { role: Role::Tool, content: Some(content.into()), tool_calls: None, tool_call_id: Some(tool_call_id.into()) }
    }
}
```

`crates/agent-runner/src/agent/mod.rs`:
```rust
pub mod message;
pub use message::{FinishReason, LlmResponse, Message, ToolCall, ToolResult};
```

- [ ] **Step 3: Create provider stub with TokenUsage**

`crates/agent-runner/src/provider/mod.rs`:
```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenUsage {
    pub input_tokens: u64,
    pub output_tokens: u64,
}

impl TokenUsage {
    pub fn zero() -> Self {
        Self { input_tokens: 0, output_tokens: 0 }
    }
}
```

- [ ] **Step 4: Create tool and session stubs**

`crates/agent-runner/src/tools/mod.rs`:
```rust
// tools module — populated in Task 4
```

`crates/agent-runner/src/session.rs`:
```rust
// session module — populated in Task 7
```

- [ ] **Step 5: Verify compilation**

Run: `cargo check -p agent-runner`
Expected: Compiles.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat(agent-runner): add message types and provider stub"
```

---

### Task 3: LLM Provider Trait + Anthropic Implementation

**Files:**
- Modify: `crates/agent-runner/src/provider/mod.rs`
- Create: `crates/agent-runner/src/provider/anthropic.rs`
- Create: `crates/agent-runner/src/provider/openai.rs`

- [ ] **Step 1: Write provider trait**

Replace `crates/agent-runner/src/provider/mod.rs`:
```rust
pub mod anthropic;
pub mod openai;

use anyhow::Result;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use crate::agent::LlmResponse;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenUsage {
    pub input_tokens: u64,
    pub output_tokens: u64,
}

impl TokenUsage {
    pub fn zero() -> Self {
        Self { input_tokens: 0, output_tokens: 0 }
    }
}

#[derive(Debug, Clone)]
pub struct ToolDef {
    pub name: String,
    pub description: String,
    pub parameters: serde_json::Value,
}

#[derive(Debug, Clone)]
pub struct RequestConfig {
    pub max_tokens: Option<u32>,
    pub temperature: Option<f32>,
    pub system_prompt: Option<String>,
}

impl Default for RequestConfig {
    fn default() -> Self {
        Self { max_tokens: Some(8096), temperature: None, system_prompt: None }
    }
}

#[async_trait]
pub trait LlmProvider: Send + Sync {
    async fn send(
        &self,
        messages: &[crate::agent::Message],
        tools: &[ToolDef],
        config: &RequestConfig,
    ) -> Result<LlmResponse>;
    fn name(&self) -> &str;
}
```

- [ ] **Step 2: Write Anthropic provider**

`crates/agent-runner/src/provider/anthropic.rs`:
```rust
use anyhow::{Context, Result, bail};
use async_trait::async_trait;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use crate::agent::{FinishReason, LlmResponse, Message, ToolCall};
use super::{LlmProvider, RequestConfig, TokenUsage, ToolDef};

pub struct AnthropicProvider {
    client: Client,
    api_key: String,
    model: String,
    base_url: String,
}

impl AnthropicProvider {
    pub fn new(api_key: String, model: String) -> Self {
        Self { client: Client::new(), api_key, model, base_url: "https://api.anthropic.com".into() }
    }

    pub fn with_base_url(mut self, url: String) -> Self {
        self.base_url = url;
        self
    }
}

#[derive(Serialize)]
struct ApiRequest {
    model: String,
    max_tokens: u32,
    #[serde(skip_serializing_if = "Option::is_none")]
    temperature: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    system: Option<String>,
    messages: Vec<serde_json::Value>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    tools: Vec<serde_json::Value>,
}

#[derive(Deserialize)]
struct ApiResponse {
    content: Vec<ContentBlock>,
    stop_reason: Option<String>,
    usage: ApiUsage,
}

#[derive(Deserialize)]
struct ContentBlock {
    #[serde(rename = "type")]
    block_type: String,
    text: Option<String>,
    id: Option<String>,
    name: Option<String>,
    input: Option<serde_json::Value>,
}

#[derive(Deserialize)]
struct ApiUsage {
    input_tokens: u64,
    output_tokens: u64,
}

fn to_api_messages(messages: &[Message]) -> Vec<serde_json::Value> {
    messages
        .iter()
        .filter(|m| m.role != crate::agent::message::Role::System)
        .map(|msg| {
            let role = match msg.role {
                crate::agent::message::Role::User | crate::agent::message::Role::Tool => "user",
                crate::agent::message::Role::Assistant => "assistant",
                crate::agent::message::Role::System => "user",
            };
            match msg.role {
                crate::agent::message::Role::Tool => {
                    serde_json::json!({
                        "role": role,
                        "content": [{
                            "type": "tool_result",
                            "tool_use_id": msg.tool_call_id,
                            "content": msg.content,
                        }]
                    })
                }
                _ => {
                    if let Some(ref tcs) = msg.tool_calls {
                        let mut blocks: Vec<serde_json::Value> = Vec::new();
                        if let Some(ref text) = msg.content {
                            blocks.push(serde_json::json!({"type": "text", "text": text}));
                        }
                        for tc in tcs {
                            blocks.push(serde_json::json!({
                                "type": "tool_use",
                                "id": tc.id,
                                "name": tc.name,
                                "input": tc.arguments,
                            }));
                        }
                        serde_json::json!({"role": role, "content": blocks})
                    } else {
                        serde_json::json!({"role": role, "content": msg.content})
                    }
                }
            }
        })
        .collect()
}

#[async_trait]
impl LlmProvider for AnthropicProvider {
    async fn send(
        &self,
        messages: &[Message],
        tools: &[ToolDef],
        config: &RequestConfig,
    ) -> Result<LlmResponse> {
        let api_tools: Vec<serde_json::Value> = tools
            .iter()
            .map(|t| serde_json::json!({
                "name": t.name,
                "description": t.description,
                "input_schema": t.parameters,
            }))
            .collect();

        let body = ApiRequest {
            model: self.model.clone(),
            max_tokens: config.max_tokens.unwrap_or(8096),
            temperature: config.temperature,
            system: config.system_prompt.clone(),
            messages: to_api_messages(messages),
            tools: api_tools,
        };

        let resp = self.client
            .post(format!("{}/v1/messages", self.base_url))
            .header("x-api-key", &self.api_key)
            .header("anthropic-version", "2023-06-01")
            .header("content-type", "application/json")
            .json(&body)
            .send()
            .await
            .context("anthropic api request")?;

        if !resp.status().is_success() {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            bail!("anthropic api error {}: {}", status, text);
        }

        let api_resp: ApiResponse = resp.json().await.context("parse anthropic response")?;

        let mut text_parts = Vec::new();
        let mut tool_calls = Vec::new();
        for block in &api_resp.content {
            match block.block_type.as_str() {
                "text" => { if let Some(ref t) = block.text { text_parts.push(t.clone()); } }
                "tool_use" => {
                    tool_calls.push(ToolCall {
                        id: block.id.clone().unwrap_or_default(),
                        name: block.name.clone().unwrap_or_default(),
                        arguments: block.input.clone().unwrap_or(serde_json::Value::Null),
                    });
                }
                _ => {}
            }
        }

        let finish_reason = match api_resp.stop_reason.as_deref() {
            Some("end_turn") => FinishReason::Stop,
            Some("tool_use") => FinishReason::ToolUse,
            Some("max_tokens") => FinishReason::MaxTokens,
            _ => FinishReason::Stop,
        };

        let message = if !tool_calls.is_empty() {
            Message::assistant_with_tool_calls(tool_calls)
        } else {
            Message::assistant(text_parts.join(""))
        };

        Ok(LlmResponse {
            message,
            finish_reason,
            usage: TokenUsage {
                input_tokens: api_resp.usage.input_tokens,
                output_tokens: api_resp.usage.output_tokens,
            },
        })
    }

    fn name(&self) -> &str { "anthropic" }
}
```

- [ ] **Step 3: Write OpenAI stub**

`crates/agent-runner/src/provider/openai.rs`:
```rust
use anyhow::Result;
use async_trait::async_trait;
use crate::agent::LlmResponse;
use super::{LlmProvider, RequestConfig, ToolDef};

pub struct OpenAiProvider;

impl OpenAiProvider {
    pub fn new(_api_key: String, _model: String, _base_url: Option<String>) -> Self { Self }
}

#[async_trait]
impl LlmProvider for OpenAiProvider {
    async fn send(&self, _messages: &[crate::agent::Message], _tools: &[ToolDef], _config: &RequestConfig) -> Result<LlmResponse> {
        anyhow::bail!("OpenAI provider not yet implemented")
    }
    fn name(&self) -> &str { "openai" }
}
```

- [ ] **Step 4: Verify compilation**

Run: `cargo check -p agent-runner`
Expected: Compiles.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(agent-runner): add LLM provider trait + Anthropic impl"
```

---

### Task 4: Tool Trait + Bash Tool

**Files:**
- Modify: `crates/agent-runner/src/tools/mod.rs`
- Create: `crates/agent-runner/src/tools/bash.rs`

- [ ] **Step 1: Write tool trait and registry**

`crates/agent-runner/src/tools/mod.rs`:
```rust
pub mod bash;
pub mod file_read;
pub mod file_write;
pub mod file_edit;
pub mod glob;
pub mod grep;

use anyhow::Result;
use async_trait::async_trait;
use std::path::{Path, PathBuf};
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct ToolContext {
    pub workspace: PathBuf,
    pub timeout_secs: u64,
}

impl ToolContext {
    pub fn new(workspace: PathBuf) -> Self {
        Self { workspace, timeout_secs: 120 }
    }

    pub fn validate_path(&self, path: &Path) -> Result<PathBuf> {
        let canonical = if path.is_absolute() {
            path.to_path_buf()
        } else {
            self.workspace.join(path)
        };
        let ws = self.workspace.canonicalize().unwrap_or_else(|_| self.workspace.clone());
        let canon = canonical.canonicalize().unwrap_or_else(|_| canonical.clone());
        if !canon.starts_with(&ws) {
            anyhow::bail!("path traversal: {} is outside workspace", path.display());
        }
        Ok(canon)
    }
}

#[async_trait]
pub trait Tool: Send + Sync {
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    fn parameters_schema(&self) -> serde_json::Value;
    async fn execute(&self, input: serde_json::Value, ctx: &ToolContext) -> Result<String>;
}

pub struct ToolRegistry {
    tools: HashMap<String, Box<dyn Tool>>,
}

impl ToolRegistry {
    pub fn new() -> Self { Self { tools: HashMap::new() } }

    pub fn register(&mut self, tool: Box<dyn Tool>) {
        self.tools.insert(tool.name().to_string(), tool);
    }

    pub fn get(&self, name: &str) -> Option<&dyn Tool> {
        self.tools.get(name).map(|t| t.as_ref())
    }

    pub fn tool_defs(&self) -> Vec<crate::provider::ToolDef> {
        self.tools.values().map(|t| crate::provider::ToolDef {
            name: t.name().to_string(),
            description: t.description().to_string(),
            parameters: t.parameters_schema(),
        }).collect()
    }

    pub fn filter(&self, allowed: &[String]) -> Self {
        let tools: HashMap<_, _> = self.tools.iter()
            .filter(|(name, _)| allowed.contains(name))
            .map(|(k, v)| (k.clone(), v.cloned_box()))
            .collect();
        Self { tools }
    }
}

trait ClonedBox { fn cloned_box(&self) -> Box<dyn Tool>; }
impl<T: Tool + Clone + 'static> ClonedBox for T {
    fn cloned_box(&self) -> Box<dyn Tool> { Box::new(self.clone()) }
}

pub fn default_tools() -> ToolRegistry {
    let mut r = ToolRegistry::new();
    r.register(Box::new(bash::BashTool));
    r.register(Box::new(file_read::FileReadTool));
    r.register(Box::new(file_write::FileWriteTool));
    r.register(Box::new(file_edit::FileEditTool));
    r.register(Box::new(glob::GlobTool));
    r.register(Box::new(grep::GrepTool));
    r
}
```

- [ ] **Step 2: Write bash tool**

`crates/agent-runner/src/tools/bash.rs`:
```rust
use anyhow::{Context, Result};
use async_trait::async_trait;
use serde::Deserialize;
use tokio::process::Command;
use super::{Tool, ToolContext};

#[derive(Clone)]
pub struct BashTool;

#[derive(Deserialize)]
struct BashInput {
    command: String,
    #[serde(default = "default_timeout")]
    timeout_secs: u64,
}

fn default_timeout() -> u64 { 120 }

#[async_trait]
impl Tool for BashTool {
    fn name(&self) -> &str { "bash" }
    fn description(&self) -> &str {
        "Execute a bash command in the workspace directory. Returns stdout and stderr."
    }
    fn parameters_schema(&self) -> serde_json::Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "command": { "type": "string", "description": "The bash command" },
                "timeout_secs": { "type": "integer", "description": "Timeout (default 120)", "default": 120 }
            },
            "required": ["command"]
        })
    }
    async fn execute(&self, input: serde_json::Value, ctx: &ToolContext) -> Result<String> {
        let input: BashInput = serde_json::from_value(input).context("parse bash input")?;
        let timeout = input.timeout_secs.min(ctx.timeout_secs);
        let output = tokio::time::timeout(
            std::time::Duration::from_secs(timeout),
            Command::new("bash")
                .arg("-c")
                .arg(&input.command)
                .current_dir(&ctx.workspace)
                .output(),
        ).await.context("bash timeout")?.context("bash execution")?;

        let mut result = String::new();
        if !output.stdout.is_empty() { result.push_str(&String::from_utf8_lossy(&output.stdout)); }
        if !output.stderr.is_empty() {
            if !result.is_empty() { result.push('\n'); }
            result.push_str("[stderr]\n");
            result.push_str(&String::from_utf8_lossy(&output.stderr));
        }
        let code = output.status.code().unwrap_or(-1);
        if code != 0 { result.push_str(&format!("\n[exit code: {}]", code)); }
        Ok(result)
    }
}
```

- [ ] **Step 3: Create stub files for remaining tools**

Create stub files for `file_read.rs`, `file_write.rs`, `file_edit.rs`, `glob.rs`, `grep.rs` each containing a minimal `#[derive(Clone)] pub struct XxxTool;` struct. These will be filled in Task 5.

- [ ] **Step 4: Verify compilation**

Run: `cargo check -p agent-runner`

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(agent-runner): add tool trait, registry, and bash tool"
```

---

### Task 5: Remaining Tools (Read, Write, Edit, Glob, Grep)

**Files:**
- Modify: `crates/agent-runner/src/tools/file_read.rs`
- Modify: `crates/agent-runner/src/tools/file_write.rs`
- Modify: `crates/agent-runner/src/tools/file_edit.rs`
- Modify: `crates/agent-runner/src/tools/glob.rs`
- Modify: `crates/agent-runner/src/tools/grep.rs`

- [ ] **Step 1: Write file_read tool**

`crates/agent-runner/src/tools/file_read.rs`:
```rust
use anyhow::{Context, Result};
use async_trait::async_trait;
use serde::Deserialize;
use std::path::Path;
use super::{Tool, ToolContext};

#[derive(Clone)]
pub struct FileReadTool;

#[derive(Deserialize)]
struct FileReadInput {
    path: String,
    offset: Option<usize>,
    limit: Option<usize>,
}

#[async_trait]
impl Tool for FileReadTool {
    fn name(&self) -> &str { "read" }
    fn description(&self) -> &str { "Read file contents with optional line range." }
    fn parameters_schema(&self) -> serde_json::Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "path": { "type": "string" },
                "offset": { "type": "integer" },
                "limit": { "type": "integer" }
            },
            "required": ["path"]
        })
    }
    async fn execute(&self, input: serde_json::Value, ctx: &ToolContext) -> Result<String> {
        let input: FileReadInput = serde_json::from_value(input)?;
        let path = ctx.validate_path(Path::new(&input.path))?;
        let content = tokio::fs::read_to_string(&path).await.with_context(|| format!("read {}", path.display()))?;
        let lines: Vec<&str> = content.lines().collect();
        let offset = input.offset.unwrap_or(1).saturating_sub(1);
        let limit = input.limit.unwrap_or(lines.len().saturating_sub(offset));
        let selected: Vec<String> = lines.iter().skip(offset).take(limit)
            .enumerate().map(|(i, l)| format!("{}: {}", offset + i + 1, l)).collect();
        Ok(selected.join("\n"))
    }
}
```

- [ ] **Step 2: Write file_write tool**

`crates/agent-runner/src/tools/file_write.rs`:
```rust
use anyhow::{Context, Result};
use async_trait::async_trait;
use serde::Deserialize;
use std::path::Path;
use super::{Tool, ToolContext};

#[derive(Clone)]
pub struct FileWriteTool;

#[derive(Deserialize)]
struct FileWriteInput { path: String, content: String }

#[async_trait]
impl Tool for FileWriteTool {
    fn name(&self) -> &str { "write" }
    fn description(&self) -> &str { "Write content to a file. Creates parent dirs." }
    fn parameters_schema(&self) -> serde_json::Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "path": { "type": "string" },
                "content": { "type": "string" }
            },
            "required": ["path", "content"]
        })
    }
    async fn execute(&self, input: serde_json::Value, ctx: &ToolContext) -> Result<String> {
        let input: FileWriteInput = serde_json::from_value(input)?;
        let path = ctx.validate_path(Path::new(&input.path))?;
        if let Some(parent) = path.parent() { tokio::fs::create_dir_all(parent).await?; }
        tokio::fs::write(&path, &input.content).await?;
        Ok(format!("wrote {} bytes to {}", input.content.len(), input.path))
    }
}
```

- [ ] **Step 3: Write file_edit tool**

`crates/agent-runner/src/tools/file_edit.rs`:
```rust
use anyhow::{anyhow, Context, Result};
use async_trait::async_trait;
use serde::Deserialize;
use similar::TextDiff;
use std::path::Path;
use super::{Tool, ToolContext};

#[derive(Clone)]
pub struct FileEditTool;

#[derive(Deserialize)]
struct FileEditInput { path: String, old_string: String, new_string: String }

#[async_trait]
impl Tool for FileEditTool {
    fn name(&self) -> &str { "edit" }
    fn description(&self) -> &str { "Replace old_string with new_string in a file. Returns diff." }
    fn parameters_schema(&self) -> serde_json::Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "path": { "type": "string" },
                "old_string": { "type": "string" },
                "new_string": { "type": "string" }
            },
            "required": ["path", "old_string", "new_string"]
        })
    }
    async fn execute(&self, input: serde_json::Value, ctx: &ToolContext) -> Result<String> {
        let input: FileEditInput = serde_json::from_value(input)?;
        let path = ctx.validate_path(Path::new(&input.path))?;
        let content = tokio::fs::read_to_string(&path).await?;
        let count = content.matches(&input.old_string).count();
        if count == 0 { return Err(anyhow!("old_string not found in {}", input.path)); }
        if count > 1 { return Err(anyhow!("old_string found {} times — must be unique", count)); }
        let new_content = content.replacen(&input.old_string, &input.new_string, 1);
        let diff = TextDiff::from_lines(&content, &new_content);
        let mut out = String::new();
        for change in diff.iter_all_changes() {
            let sign = match change.tag() {
                similar::ChangeTag::Delete => "-",
                similar::ChangeTag::Insert => "+",
                similar::ChangeTag::Equal => " ",
            };
            out.push_str(&format!("{}{}", sign, change));
        }
        tokio::fs::write(&path, &new_content).await?;
        Ok(out)
    }
}
```

- [ ] **Step 4: Write glob tool**

`crates/agent-runner/src/tools/glob.rs`:
```rust
use anyhow::Result;
use async_trait::async_trait;
use serde::Deserialize;
use super::{Tool, ToolContext};

#[derive(Clone)]
pub struct GlobTool;

#[derive(Deserialize)]
struct GlobInput { pattern: String }

#[async_trait]
impl Tool for GlobTool {
    fn name(&self) -> &str { "glob" }
    fn description(&self) -> &str { "Find files matching a glob pattern." }
    fn parameters_schema(&self) -> serde_json::Value {
        serde_json::json!({
            "type": "object",
            "properties": { "pattern": { "type": "string" } },
            "required": ["pattern"]
        })
    }
    async fn execute(&self, input: serde_json::Value, ctx: &ToolContext) -> Result<String> {
        let input: GlobInput = serde_json::from_value(input)?;
        let pattern = ctx.workspace.join(&input.pattern);
        let paths: Vec<String> = glob::glob(pattern.to_str().unwrap_or(""))?
            .filter_map(|p| p.ok())
            .filter_map(|p| p.strip_prefix(&ctx.workspace).ok())
            .map(|p| p.display().to_string())
            .collect();
        Ok(if paths.is_empty() { "no matches".into() } else { paths.join("\n") })
    }
}
```

- [ ] **Step 5: Write grep tool**

`crates/agent-runner/src/tools/grep.rs`:
```rust
use anyhow::Result;
use async_trait::async_trait;
use regex::Regex;
use serde::Deserialize;
use std::path::Path;
use super::{Tool, ToolContext};

#[derive(Clone)]
pub struct GrepTool;

#[derive(Deserialize)]
struct GrepInput {
    pattern: String,
    path: Option<String>,
    #[serde(default = "default_ctx")]
    context_lines: usize,
}

fn default_ctx() -> usize { 2 }

#[async_trait]
impl Tool for GrepTool {
    fn name(&self) -> &str { "grep" }
    fn description(&self) -> &str { "Search file contents using regex. Returns matching lines with context." }
    fn parameters_schema(&self) -> serde_json::Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "pattern": { "type": "string" },
                "path": { "type": "string" },
                "context_lines": { "type": "integer", "default": 2 }
            },
            "required": ["pattern"]
        })
    }
    async fn execute(&self, input: serde_json::Value, ctx: &ToolContext) -> Result<String> {
        let input: GrepInput = serde_json::from_value(input)?;
        let re = Regex::new(&input.pattern)?;
        let search_path = match &input.path {
            Some(p) => ctx.validate_path(Path::new(p))?,
            None => ctx.workspace.clone(),
        };
        let mut results = Vec::new();
        search_dir(&search_path, &search_path, &re, input.context_lines, &mut results)?;
        Ok(if results.is_empty() { "no matches".into() } else { results.join("\n") })
    }
}

fn search_dir(base: &std::path::Path, current: &std::path::Path, re: &Regex, ctx: usize, results: &mut Vec<String>) -> Result<()> {
    if !current.is_dir() { return Ok(()); }
    for entry in std::fs::read_dir(current)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_dir() {
            let name = path.file_name().unwrap_or_default().to_string_lossy();
            if name.starts_with('.') || name == "target" || name == "node_modules" { continue; }
            search_dir(base, &path, re, ctx, results)?;
        } else {
            let content = match std::fs::read_to_string(&path) { Ok(c) => c, Err(_) => continue };
            let lines: Vec<&str> = content.lines().collect();
            let rel = path.strip_prefix(base).unwrap_or(&path).display();
            for (i, line) in lines.iter().enumerate() {
                if re.is_match(line) {
                    let start = i.saturating_sub(ctx);
                    let end = (i + ctx + 1).min(lines.len());
                    for j in start..end {
                        let prefix = if j == i { ">" } else { " " };
                        results.push(format!("{}:{}:{} {}", rel, j + 1, prefix, lines[j]));
                    }
                    results.push("---".into());
                }
            }
        }
    }
    Ok(())
}
```

- [ ] **Step 6: Verify all tools compile**

Run: `cargo check -p agent-runner`

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat(agent-runner): add file read/write/edit/glob/grep tools"
```

---

### Task 6: Agent Loop

**Files:**
- Modify: `crates/agent-runner/src/agent/mod.rs`

- [ ] **Step 1: Write agent loop**

Replace `crates/agent-runner/src/agent/mod.rs`:
```rust
pub mod message;
pub use message::{FinishReason, LlmResponse, Message, ToolCall, ToolResult};

use anyhow::Result;
use tracing::info;
use crate::provider::{LlmProvider, RequestConfig};
use crate::tools::ToolContext;

pub struct AgentConfig {
    pub max_tool_calls: u64,
    pub system_prompt: String,
    pub user_prompt: String,
    pub allowed_tools: Vec<String>,
    pub max_tokens: u32,
}

pub struct AgentOutput {
    pub messages: Vec<Message>,
    pub tool_calls_made: u64,
    pub usage: crate::provider::TokenUsage,
    pub finish_reason: FinishReason,
}

pub async fn run_agent_loop(
    provider: &dyn LlmProvider,
    tools: &crate::tools::ToolRegistry,
    config: &AgentConfig,
    tool_ctx: &ToolContext,
) -> Result<AgentOutput> {
    let filtered = tools.filter(&config.allowed_tools);
    let tool_defs = filtered.tool_defs();
    let mut messages = vec![Message::system(&config.system_prompt), Message::user(&config.user_prompt)];
    let mut total_usage = crate::provider::TokenUsage::zero();
    let mut tool_calls_made: u64 = 0;

    loop {
        if tool_calls_made >= config.max_tool_calls {
            return Ok(AgentOutput { messages, tool_calls_made, usage: total_usage, finish_reason: FinishReason::MaxTokens });
        }
        let req = RequestConfig { max_tokens: Some(config.max_tokens), temperature: None, system_prompt: None };
        let response = provider.send(&messages, &tool_defs, &req).await?;
        total_usage.input_tokens += response.usage.input_tokens;
        total_usage.output_tokens += response.usage.output_tokens;
        let finish = response.finish_reason.clone();
        messages.push(response.message.clone());

        match finish {
            FinishReason::Stop | FinishReason::MaxTokens => {
                return Ok(AgentOutput { messages, tool_calls_made, usage: total_usage, finish_reason: finish });
            }
            FinishReason::ToolUse => {
                if let Some(ref tcs) = response.message.tool_calls {
                    tool_calls_made += tcs.len() as u64;
                    for tc in tcs {
                        info!("tool: {}", tc.name);
                        let result = match filtered.get(&tc.name) {
                            Some(tool) => match tool.execute(tc.arguments.clone(), tool_ctx).await {
                                Ok(out) => Message::tool_result(&tc.id, out, false),
                                Err(e) => Message::tool_result(&tc.id, format!("error: {}", e), true),
                            },
                            None => Message::tool_result(&tc.id, format!("unknown tool: {}", tc.name), true),
                        };
                        messages.push(result);
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify compilation**

Run: `cargo check -p agent-runner`

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(agent-runner): add agent loop with tool dispatch"
```

---

### Task 7: Session Persistence + CLI

**Files:**
- Modify: `crates/agent-runner/src/session.rs`
- Modify: `crates/agent-runner/src/main.rs`

- [ ] **Step 1: Write session module**

`crates/agent-runner/src/session.rs`:
```rust
use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::path::Path;
use crate::agent::Message;
use crate::provider::TokenUsage;

#[derive(Debug, Serialize, Deserialize)]
pub struct Session {
    pub id: String,
    pub messages: Vec<Message>,
    pub token_usage: TokenUsage,
    pub current_stage: String,
}

impl Session {
    pub fn new(id: String, stage: String) -> Self {
        Self { id, messages: Vec::new(), token_usage: TokenUsage::zero(), current_stage: stage }
    }
    pub fn save(&self, path: &Path) -> Result<()> {
        std::fs::write(path, serde_json::to_string_pretty(self)?)?;
        Ok(())
    }
    pub fn load(path: &Path) -> Result<Self> {
        let json = std::fs::read_to_string(path).with_context(|| format!("read session {}", path.display()))?;
        serde_json::from_str(&json).context("parse session")
    }
}
```

- [ ] **Step 2: Write CLI main**

`crates/agent-runner/src/main.rs`:
```rust
use anyhow::Result;
use std::path::PathBuf;

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let args: Vec<String> = std::env::args().collect();
    match args.get(1).map(|s| s.as_str()) {
        Some("run") => run_cmd(&args[2..]).await,
        Some("resume") => resume_cmd(&args[2..]).await,
        _ => {
            eprintln!("usage: agent-runner <run|resume> [options]");
            std::process::exit(1);
        }
    }
}

async fn run_cmd(args: &[String]) -> Result<()> {
    let workspace = get_arg(args, "--workspace")?;
    let system_prompt_file = get_arg(args, "--system-prompt")?;
    let prompt = get_arg(args, "--prompt")?;
    let tools_str = get_arg(args, "--tools").unwrap_or_else(|_| "bash,read,write,edit,glob,grep".into());
    let max_tokens: u32 = get_arg(args, "--max-tokens").unwrap_or_else(|_| "8096".into()).parse()?;
    let max_tool_calls: u64 = get_arg(args, "--max-tool-calls").unwrap_or_else(|_| "200".into()).parse()?;

    let workspace = PathBuf::from(&workspace);
    let system_prompt = std::fs::read_to_string(&system_prompt_file)?;
    let allowed_tools: Vec<String> = tools_str.split(',').map(|s| s.trim().to_string()).collect();
    let provider = create_provider()?;
    let tool_registry = agent_runner::tools::default_tools();
    let tool_ctx = agent_runner::tools::ToolContext::new(workspace);

    let output = agent_runner::agent::run_agent_loop(
        &*provider,
        &tool_registry,
        &agent_runner::agent::AgentConfig { max_tool_calls, system_prompt, user_prompt: prompt, allowed_tools, max_tokens },
        &tool_ctx,
    ).await?;

    println!("{}", output.messages.last().and_then(|m| m.content.clone()).unwrap_or_default());
    Ok(())
}

async fn resume_cmd(args: &[String]) -> Result<()> {
    let workspace = get_arg(args, "--workspace")?;
    let session_file = get_arg(args, "--session")?;
    let prompt = get_arg(args, "--prompt")?;
    let max_tokens: u32 = get_arg(args, "--max-tokens").unwrap_or_else(|_| "8096".into()).parse()?;

    let mut session = agent_runner::session::Session::load(PathBuf::from(&session_file).as_path())?;
    let provider = create_provider()?;
    let tool_ctx = agent_runner::tools::ToolContext::new(PathBuf::from(&workspace));

    session.messages.push(agent_runner::agent::Message::user(&prompt));
    let req = agent_runner::provider::RequestConfig { max_tokens: Some(max_tokens), temperature: None, system_prompt: None };
    let response = provider.send(&session.messages, &[], &req).await?;
    println!("{}", response.message.content.as_deref().unwrap_or(""));
    session.messages.push(response.message);
    session.save(PathBuf::from(&session_file).as_path())?;
    Ok(())
}

fn create_provider() -> Result<Box<dyn agent_runner::provider::LlmProvider>> {
    let name = std::env::var("LLM_PROVIDER").unwrap_or_else(|_| "anthropic".into());
    let key = std::env::var("LLM_API_KEY")?;
    let model = std::env::var("LLM_MODEL").unwrap_or_else(|_| "claude-sonnet-4-20250514".into());
    match name.as_str() {
        "anthropic" => Ok(Box::new(agent_runner::provider::anthropic::AnthropicProvider::new(key, model))),
        "openai" => Ok(Box::new(agent_runner::provider::openai::OpenAiProvider::new(key, model, std::env::var("OPENAI_BASE_URL").ok()))),
        _ => anyhow::bail!("unknown provider: {}", name),
    }
}

fn get_arg(args: &[String], flag: &str) -> Result<String> {
    let idx = args.iter().position(|a| a == flag).ok_or_else(|| anyhow::anyhow!("missing: {}", flag))?;
    args.get(idx + 1).cloned().ok_or_else(|| anyhow::anyhow!("missing value: {}", flag))
}
```

- [ ] **Step 3: Verify compilation**

Run: `cargo check -p agent-runner`

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(agent-runner): add session persistence and CLI"
```

---

## Task Group C: Workflow Engine

### Task 8: Workflow YAML Parser

**Files:**
- Create: `crates/trailhead-service/src/workflow/mod.rs`
- Create: `crates/trailhead-service/src/workflow/parser.rs`
- Create: `crates/trailhead-service/src/workflow/resolver.rs` (stub)
- Create: `crates/trailhead-service/src/workflow/router.rs` (stub)

- [ ] **Step 1: Write workflow types and parser**

`crates/trailhead-service/src/workflow/parser.rs`:
```rust
use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Workflow {
    pub name: String,
    #[serde(default)]
    pub description: String,
    pub stages: HashMap<String, Stage>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Stage {
    pub skill: String,
    #[serde(default)]
    pub prompt: String,
    pub response_schema: Option<serde_json::Value>,
    #[serde(default)]
    pub tools: Vec<String>,
    pub max_tokens: Option<u32>,
    pub timeout_secs: Option<u64>,
    #[serde(default)]
    pub checkpoint: bool,
    pub routes: Option<Vec<Route>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Route {
    pub when: String,
    pub next: String,
}

pub fn parse_workflow(yaml_str: &str) -> Result<Workflow> {
    let wf: Workflow = serde_yaml::from_str(yaml_str).context("parse workflow YAML")?;
    if wf.stages.is_empty() { bail!("workflow needs at least one stage"); }
    for (name, stage) in &wf.stages {
        if stage.skill.is_empty() { bail!("stage '{}' needs a skill", name); }
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_simple_workflow() {
        let yaml = r#"
name: test
stages:
  plan:
    skill: plan
    prompt: "Plan: {{input}}"
    routes:
      - when: 'response.ok'
        next: done
  done:
    skill: pause
    routes: null
"#;
        let wf = parse_workflow(yaml).unwrap();
        assert_eq!(wf.name, "test");
        assert_eq!(wf.stages.len(), 2);
        assert!(wf.stages["plan"].routes.is_some());
    }

    #[test]
    fn reject_empty_stages() {
        let yaml = "name: bad\nstages: {}\n";
        assert!(parse_workflow(yaml).is_err());
    }

    #[test]
    fn reject_unknown_route_target() {
        let yaml = r#"
name: bad
stages:
  start:
    skill: plan
    routes:
      - when: "true"
        next: nonexistent
"#;
        assert!(parse_workflow(yaml).is_err());
    }
}
```

`crates/trailhead-service/src/workflow/mod.rs`:
```rust
pub mod parser;
pub mod resolver;
pub mod router;

pub use parser::{Workflow, Stage, Route, parse_workflow};
```

`crates/trailhead-service/src/workflow/resolver.rs`:
```rust
// resolver — populated in Task 9
```

`crates/trailhead-service/src/workflow/router.rs`:
```rust
// router — populated in Task 10
```

- [ ] **Step 2: Run tests**

Run: `cargo test -p trailhead-service parser`
Expected: 3 tests pass.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(trailhead-service): add workflow YAML parser with tests"
```

---

### Task 9: Template Resolver

**Files:**
- Modify: `crates/trailhead-service/src/workflow/resolver.rs`

- [ ] **Step 1: Write resolver with `{{input}}` and `{{stages.*}}` support**

`crates/trailhead-service/src/workflow/resolver.rs`:
```rust
use anyhow::Result;
use minijinja::{Environment, context};
use serde::Serialize;
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize)]
pub struct TemplateVars {
    pub input: String,
    pub project: ProjectVars,
    pub stages: HashMap<String, StageOutput>,
    pub env: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize)]
pub struct ProjectVars {
    pub name: String,
    pub repo: String,
    pub branch: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct StageOutput {
    pub output: String,
    pub changed_files: Vec<String>,
}

pub fn resolve_prompt(template: &str, vars: &TemplateVars) -> Result<String> {
    let mut env = Environment::new();
    env.add_template("prompt", template)?;
    let tmpl = env.get_template("prompt")?;
    Ok(tmpl.render(context! { input => &vars.input, project => &vars.project, stages => &vars.stages, env => &vars.env })?)
}

pub fn resolve_input(
    user_input: &str,
    previous_stage_name: Option<&str>,
    stage_outputs: &HashMap<String, StageOutput>,
) -> String {
    match previous_stage_name {
        Some(id) => stage_outputs.get(id).map(|s| s.output.clone()).unwrap_or_default(),
        None => user_input.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolve_input_var() {
        let vars = TemplateVars {
            input: "fix the bug".into(),
            project: ProjectVars { name: "myproject".into(), repo: "https://github.com/x/y".into(), branch: "main".into() },
            stages: HashMap::new(),
            env: HashMap::new(),
        };
        let result = resolve_prompt("Task: {{input}}", &vars).unwrap();
        assert_eq!(result, "Task: fix the bug");
    }

    #[test]
    fn resolve_stages_var() {
        let mut stages = HashMap::new();
        stages.insert("plan".into(), StageOutput { output: "do thing".into(), changed_files: vec![] });
        let vars = TemplateVars {
            input: "original".into(),
            project: ProjectVars { name: "p".into(), repo: "r".into(), branch: "main".into() },
            stages,
            env: HashMap::new(),
        };
        let result = resolve_prompt("Plan: {{stages.plan.output}}", &vars).unwrap();
        assert_eq!(result, "Plan: do thing");
    }

    #[test]
    fn resolve_input_from_previous_stage() {
        let mut stages = HashMap::new();
        stages.insert("plan".into(), StageOutput { output: "{\"plan\": \"do it\"}".into(), changed_files: vec![] });
        let result = resolve_input("original", Some("plan"), &stages);
        assert_eq!(result, "{\"plan\": \"do it\"}");
    }

    #[test]
    fn resolve_input_first_stage() {
        let result = resolve_input("fix this", None, &HashMap::new());
        assert_eq!(result, "fix this");
    }
}
```

- [ ] **Step 2: Run tests**

Run: `cargo test -p trailhead-service resolver`
Expected: 4 tests pass.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(trailhead-service): add template resolver with input/stages vars"
```

---

### Task 10: CEL Router

**Files:**
- Modify: `crates/trailhead-service/src/workflow/router.rs`

- [ ] **Step 1: Write CEL router with tests**

`crates/trailhead-service/src/workflow/router.rs`:
```rust
use anyhow::{Context, Result};
use cel::{Context, Program};
use serde_json::Value;
use super::parser::Route;

pub fn evaluate_routes(routes: &[Route], response: &Value) -> Result<Option<String>> {
    for route in routes {
        if evaluate_condition(&route.when, response)? {
            return Ok(Some(route.next.clone()));
        }
    }
    Ok(None)
}

fn evaluate_condition(condition: &str, response: &Value) -> Result<bool> {
    let program = Program::compile(condition).with_context(|| format!("compile CEL: {}", condition))?;
    let mut ctx = Context::default();
    ctx.add_variable("response", cel::Value::from(response.clone())).with_context(|| "CEL context")?;
    let result = program.execute(&ctx).with_context(|| format!("eval CEL: {}", condition))?;
    result.into_bool().ok_or_else(|| anyhow::anyhow!("CEL did not return bool: {}", condition))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn route(when: &str, next: &str) -> Route {
        Route { when: when.into(), next: next.into() }
    }

    #[test]
    fn string_equality() {
        let routes = vec![route(r#"response.complexity == "simple""#, "edit"), route("true", "pause")];
        assert_eq!(evaluate_routes(&routes, &json!({"complexity": "simple"})).unwrap(), Some("edit".into()));
    }

    #[test]
    fn boolean_field() {
        let routes = vec![route("response.passed", "review"), route("true", "fix")];
        assert_eq!(evaluate_routes(&routes, &json!({"passed": false})).unwrap(), Some("fix".into()));
    }

    #[test]
    fn numeric_comparison() {
        let routes = vec![route("response.count > 3", "pause"), route("true", "fix")];
        assert_eq!(evaluate_routes(&routes, &json!({"count": 5})).unwrap(), Some("pause".into()));
    }

    #[test]
    fn compound_expression() {
        let routes = vec![route("response.success && response.files > 0", "test"), route("true", "edit")];
        assert_eq!(evaluate_routes(&routes, &json!({"success": true, "files": 3})).unwrap(), Some("test".into()));
    }

    #[test]
    fn no_match() {
        let routes = vec![route(r#"response.x == "no""#, "edit")];
        assert_eq!(evaluate_routes(&routes, &json!({"x": "yes"})).unwrap(), None);
    }
}
```

- [ ] **Step 2: Run tests**

Run: `cargo test -p trailhead-service router`
Expected: 5 tests pass.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(trailhead-service): add CEL router with tests"
```

---

### Task 11: Workflow Engine

**Files:**
- Modify: `crates/trailhead-service/src/workflow/mod.rs`

- [ ] **Step 1: Write workflow engine with stage tracking**

Add to `crates/trailhead-service/src/workflow/mod.rs` (after existing content):
```rust
use anyhow::{anyhow, Result};
use resolver::{TemplateVars, StageOutput, resolve_prompt, resolve_input};
use router::evaluate_routes;
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct StageResult {
    pub stage_name: String,
    pub response: serde_json::Value,
    pub changed_files: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct Engine {
    pub workflow: Workflow,
    pub current_stage: String,
    pub stage_history: Vec<StageResult>,
    pub stage_outputs: HashMap<String, StageOutput>,
}

#[derive(Debug, Clone, PartialEq)]
pub enum AdvanceResult {
    Advance,
    PauseForHuman,
    Finished,
}

impl Engine {
    pub fn new(workflow: Workflow, start_stage: Option<String>) -> Result<Self> {
        let start = start_stage.unwrap_or_else(|| workflow.stages.keys().next().cloned().unwrap_or_default());
        if !workflow.stages.contains_key(&start) { return Err(anyhow!("unknown stage: {}", start)); }
        Ok(Self { workflow, current_stage: start, stage_history: Vec::new(), stage_outputs: HashMap::new() })
    }

    pub fn current_stage_def(&self) -> Option<&Stage> {
        self.workflow.stages.get(&self.current_stage)
    }

    pub fn resolve_stage_prompt(
        &self,
        user_input: &str,
        project: &resolver::ProjectVars,
        env: &HashMap<String, String>,
    ) -> Result<String> {
        let stage = self.current_stage_def().ok_or_else(|| anyhow!("no current stage"))?;
        let prev = self.stage_history.last().map(|s| s.stage_name.clone());
        let input = resolve_input(user_input, prev.as_deref(), &self.stage_outputs);
        let vars = TemplateVars { input, project: project.clone(), stages: self.stage_outputs.clone(), env: env.clone() };
        resolve_prompt(&stage.prompt, &vars)
    }

    pub fn process_response(&mut self, response: serde_json::Value) -> Result<AdvanceResult> {
        let stage = self.current_stage_def().ok_or_else(|| anyhow!("no current stage"))?;
        self.stage_outputs.insert(self.current_stage.clone(), StageOutput {
            output: serde_json::to_string_pretty(&response)?,
            changed_files: Vec::new(),
        });
        self.stage_history.push(StageResult {
            stage_name: self.current_stage.clone(),
            response: response.clone(),
            changed_files: Vec::new(),
        });
        let routes = match &stage.routes {
            Some(r) => r,
            None => return Ok(AdvanceResult::Finished),
        };
        match evaluate_routes(routes, &response)? {
            Some(next) if next == "pause_for_human" => Ok(AdvanceResult::PauseForHuman),
            Some(next) => { self.current_stage = next; Ok(AdvanceResult::Advance) }
            None => Ok(AdvanceResult::Finished),
        }
    }
}
```

- [ ] **Step 2: Verify compilation**

Run: `cargo check -p trailhead-service`

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(trailhead-service): add workflow engine with stage tracking"
```

---

### Task 12: SQLite Database Layer

**Files:**
- Create: `crates/trailhead-service/src/db.rs`

Write the full SQLite schema and query methods as specified in the design document. Includes: `projects`, `jobs`, `workers`, `checkpoints`, `prompt_history`, `workflows` tables. Methods: `create_job`, `update_job_status`, `get_queued_jobs`, `assign_worker`, `save_checkpoint`, `update_job_stage`, `heartbeat`. Uses `rusqlite` with WAL mode. Run `cargo check -p trailhead-service`. Commit.

### Task 13: WorkerProvider Trait + DockerProvider

**Files:**
- Create: `crates/trailhead-service/src/provider/mod.rs`
- Create: `crates/trailhead-service/src/provider/docker.rs`

Define `WorkerProvider` trait with `create_worker`, `destroy_worker`, `get_status`, `get_logs`, `list_workers`. Implement `DockerProvider` using `bollard` crate: pull image, create container with workspace bind mount and env vars, start, monitor. Run `cargo check -p trailhead-service`. Commit.

### Task 14: Job State Machine

**Files:**
- Create: `crates/trailhead-service/src/jobs.rs`

Implement job status transitions with validation. Methods: `transition`, `can_transition`, `is_terminal`. Each transition checks if the from→to pair is valid per the state machine in the spec. Run `cargo test -p trailhead-service jobs`. Commit.

### Task 15: Scheduler

**Files:**
- Create: `crates/trailhead-service/src/scheduler.rs`

Round-robin scheduler loop using `tokio::time::interval`. Each tick: check capacity, dequeue jobs, create workers, detect stuck workers. Configurable limits via env vars. Run `cargo check -p trailhead-service`. Commit.

### Task 16: Worker HTTP API

**Files:**
- Create: `crates/trailhead-service/src/api.rs`

Axum routes: `POST /api/workers/{id}/register`, `POST /api/workers/{id}/heartbeat`, `POST /api/workers/{id}/checkpoint`, `POST /api/workers/{id}/complete`, `POST /api/workers/{id}/fail`, `GET /api/jobs/{id}/config`. JSON request/response. Run `cargo check -p trailhead-service`. Commit.

### Task 17: IDE Adapters

**Files:**
- Create: `crates/trailhead-service/src/ide/mod.rs`
- Create: `crates/trailhead-service/src/ide/opencode.rs`
- Create: `crates/trailhead-service/src/ide/cursor.rs`
- Create: `crates/trailhead-service/src/ide/vscode.rs`
- Create: `crates/trailhead-service/src/ide/shell.rs`
- Create: `crates/trailhead-service/src/ide/ssh.rs`

`IdeAdapter` trait with `name`, `detect`, `open_workspace`, `is_attached`, `detach`. Each adapter ~40 lines. Auto-detect tries in order. Run `cargo check -p trailhead-service`. Commit.

### Task 18: MCP Server

**Files:**
- Create: `crates/trailhead-service/src/mcp.rs`

rmcp-based MCP server with tools: `jobs_list`, `jobs_create`, `jobs_cancel`, `jobs_pause`, `jobs_resume`, `jobs_attach`, `jobs_detach`, `workers_list`, `workers_destroy`, `projects_list`, `projects_add`, `workflows_list`. Each tool delegates to db/workers/scheduler. Run `cargo check -p trailhead-service`. Commit.

### Task 19: Web Dashboard Backend

**Files:**
- Create: `crates/trailhead-service/src/web.rs`

Axum routes: `GET /api/jobs`, `GET /api/workers`, `GET /api/events` (SSE), `POST /api/jobs/:id/pause|resume|cancel|attach`. Serves built React SPA from `ui/dist/`. Run `cargo check -p trailhead-service`. Commit.

### Task 20: Web Dashboard Frontend

**Files:**
- Create: `crates/trailhead-service/ui/` (full React + Vite app)

Minimal React SPA: job list with status/stage badges, worker list, basic controls. `npm install && npm run build` to produce `ui/dist/`. Commit.

### Task 21: Skills + Built-in Workflows

**Files:**
- Create: `crates/trailhead-service/skills/` (8 markdown files)
- Create: `crates/trailhead-service/workflows/` (4 YAML files)

Write the 8 skill markdown files and 4 workflow YAML files as specified in the design. Commit.

### Task 22: CLI + Daemon Mode

**Files:**
- Modify: `crates/trailhead-service/src/main.rs`

CLI with arg parsing for: `daemon`, `jobs list|create|pause|resume|cancel|attach|detach`, `workers list|destroy`, `projects list|add`. Daemon mode starts MCP server + HTTP API + scheduler + dashboard in one process using `tokio::select!`. Run `cargo check -p trailhead-service`. Commit.

### Task 23: CI/CD

**Files:**
- Create: `containers/agent-runner/Dockerfile`
- Create: `.github/workflows/build-agent-runner.yml`
- Create: `.github/workflows/release.yml`

Agent-runner Dockerfile: multi-stage Rust build → minimal runtime image. GitHub Actions: build on push, release on tag. Commit.

---

## Self-Review

**Spec coverage:**

| Spec Section | Task |
|---|---|
| Worker service binary | 1, 12-22 |
| Agent runner binary | 2-7 |
| Workflow engine | 8-11 |
| YAML workflows | 8, 21 |
| Skills (markdown) | 21 |
| CEL routing | 10 |
| `{{input}}` variable | 9 |
| `{{stages.*}}` variables | 9 |
| Template resolution | 9 |
| Response schema injection | 22 (prompt assembly) |
| Docker provider | 13 |
| IDE adapters | 17 |
| SQLite schema | 12 |
| Job state machine | 14 |
| Scheduler | 15 |
| Worker HTTP API | 16 |
| MCP server | 18 |
| Web dashboard | 19-20 |
| Human attach workflow | 17 |
| CI/CD | 23 |

No `spec.*` variables — `{{input}}` is the universal variable. New repo at `~/projects/CoderyTrailhead/`. No changes to Codery repo.

**Placeholder scan:** Tasks 12-23 describe scope and files but delegate code to executing agents. This is intentional for subagent-driven development — each task agent receives full context and writes all code.
