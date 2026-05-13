# Trailhead Phase 1 Design Specification

## Goal

Build a standalone worker-service binary and agent-runner binary that together enable CoderyCI to execute autonomous, workflow-driven coding tasks in ephemeral Docker containers. Workers are disposable. State is durable. Humans can attach to paused jobs using any IDE.

## Architecture Overview

Three components in a Cargo workspace:

| Component | Binary | Runs Where | Purpose |
|---|---|---|---|
| Trailhead Service | `trailhead-service` (new) | VPS host | Job scheduling, worker lifecycle, workflow engine, MCP, dashboard |
| Agent Runner | `agent-runner` (new) | Inside worker containers | LLM calls, tool execution, session persistence |

Trailhead service is a **peer** to CoderyCI Core (not subordinate). It runs as its own process under supervisord, serves its own MCP server and web dashboard, and owns its SQLite database. It uses Docker (via bollard) today, with a provider trait that supports cloud APIs (Hetzner, AWS, etc.) in future phases.

---

## Component Design

### 1. Trailhead Service (`crates/trailhead-service/`)

#### 1.1 Binary Structure

```
crates/trailhead-service/
├── Cargo.toml
├── src/
│   ├── main.rs           # CLI: serve, daemon, jobs, workers
│   ├── db.rs             # SQLite schema + queries (rusqlite)
│   ├── scheduler.rs      # Round-robin scheduling loop
│   ├── jobs.rs           # Job state machine
│   ├── workers.rs        # Worker lifecycle management
│   ├── workflow/
│   │   ├── mod.rs        # Engine: parse, resolve, step tracking
│   │   ├── parser.rs     # YAML → Workflow structs
│   │   ├── resolver.rs   # Template variable resolution
│   │   └── router.rs     # CEL expression evaluation → next stage
│   ├── provider/
│   │   ├── mod.rs        # WorkerProvider trait
│   │   └── docker.rs     # DockerProvider (bollard)
│   ├── ide/
│   │   ├── mod.rs        # IdeAdapter trait + auto-detect
│   │   ├── opencode.rs
│   │   ├── cursor.rs
│   │   ├── vscode.rs
│   │   ├── shell.rs
│   │   └── ssh.rs
│   ├── mcp.rs            # MCP server (rmcp)
│   ├── web.rs            # Dashboard API (axum)
│   └── api.rs            # Worker-facing HTTP API
├── skills/               # Built-in skills (markdown files)
│   ├── plan.md
│   ├── plan_detail.md
│   ├── implement.md
│   ├── test.md
│   ├── fix.md
│   ├── review.md
│   ├── create_pr.md
│   └── pause.md
├── workflows/            # Built-in workflows (YAML)
│   ├── feature.yaml
│   ├── quick-fix.yaml
│   ├── exploration.yaml
│   └── refactor.yaml
└── ui/                   # Dashboard frontend (Vite + React)
    ├── index.html
    ├── package.json
    ├── vite.config.ts
    └── src/
        ├── main.tsx
        ├── App.tsx
        ├── JobList.tsx
        ├── WorkerList.tsx
        └── types.ts
```

#### 1.2 CLI Commands

```text
trailhead-service daemon [--port 4050] [--db /opt/codery/trailhead.db]
trailhead-service jobs list [--status queued|running|paused|...]
trailhead-service jobs create --project <id> --description "..." --workflow <name>
trailhead-service jobs pause <id>
trailhead-service jobs resume <id>
trailhead-service jobs cancel <id>
trailhead-service jobs attach <id> [--ide auto|opencode|cursor|vscode|shell|ssh]
trailhead-service jobs detach <id>
trailhead-service workers list
trailhead-service workers destroy <id>
trailhead-service projects list
trailhead-service projects add --name <id> --repo <url> --branch <branch>
```

#### 1.3 Dependencies (Cargo.toml)

```toml
[dependencies]
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

#### 1.4 WorkerProvider Trait

```rust
#[async_trait]
trait WorkerProvider: Send + Sync {
    async fn create_worker(&self, spec: &WorkerSpec) -> Result<WorkerHandle>;
    async fn destroy_worker(&self, id: &str) -> Result<()>;
    async fn get_status(&self, id: &str) -> Result<WorkerStatus>;
    async fn get_logs(&self, id: &str, tail: usize) -> Result<String>;
    async fn list_workers(&self) -> Result<Vec<WorkerHandle>>;
}

struct WorkerSpec {
    job_id: String,
    workspace_path: PathBuf,
    agent_runner_image: String,
    env: HashMap<String, String>,
}

struct WorkerHandle {
    id: String,
    provider_id: String,
    status: WorkerStatus,
    ip_address: Option<String>,
}

enum WorkerStatus {
    Creating,
    Running,
    Idle,
    Stopping,
    Stopped,
    Failed(String),
}
```

DockerProvider: pulls agent-runner image, creates container with workspace bind mount, injects env vars (`WORKER_ID`, `WORKER_SERVICE_URL`, `JOB_ID`, `LLM_PROVIDER`, `LLM_MODEL`, `LLM_API_KEY`), starts container, monitors via Docker API.

#### 1.5 IdeAdapter Trait

```rust
trait IdeAdapter: Send + Sync {
    fn name(&self) -> &str;
    fn detect(&self) -> bool;
    fn open_workspace(&self, path: &Path, ctx: &JobContext) -> Result<()>;
    fn is_attached(&self, job_id: &str) -> bool;
    fn detach(&self, job_id: &str) -> Result<()>;
}

struct JobContext {
    job_id: String,
    current_step: String,
    last_agent_output: String,
    changed_files: Vec<String>,
    workspace_path: PathBuf,
}
```

Adapters:

| Adapter | Launch | Detect |
|---|---|---|
| **OpenCode** | `opencode /path` | `which opencode` |
| **Cursor** | `cursor /path` | `which cursor` |
| **VS Code** | `code /path` | `which code` |
| **Shell** | `cd /path && $SHELL` | Always |
| **SSH** | Print connection instructions | Check SSH access |

Auto-detect order: OpenCode → Cursor → VS Code → Shell.

#### 1.6 Job State Machine

```text
queued → scheduled → provisioning → running → checkpointing → completed
                 ↘                    ↕           ↗
                  → paused ← paused_for_human
                        ↘ → resuming → running
                  → failed_retryable → scheduled (retry)
                  → failed_final
                  → cancelled
```

| From | To | Trigger |
|---|---|---|
| `queued` | `scheduled` | Scheduler picks job |
| `scheduled` | `provisioning` | Provider creating worker |
| `provisioning` | `running` | Worker registers via API |
| `running` | `checkpointing` | Stage completes, saving state |
| `checkpointing` | `running` | Next stage starts |
| `running` | `paused` | Explicit pause or human gate |
| `running` | `paused_for_human` | Workflow routes to `pause_for_human` |
| `running` | `completed` | Workflow ends (null route) |
| `running` | `failed_retryable` | Heartbeat timeout or agent error |
| `failed_retryable` | `scheduled` | Retry within attempt limit |
| `failed_retryable` | `failed_final` | Max attempts exceeded |
| any | `cancelled` | Explicit cancel |
| `paused` | `resuming` | Resume command |
| `resuming` | `running` | Worker registered, state restored |

#### 1.7 Scheduler

Simple round-robin, runs every 30 seconds:

1. Count active workers. If at `max_global_workers`, stop.
2. Query `jobs WHERE status = 'queued' ORDER BY created_at ASC`.
3. For each candidate: check `max_workers_per_project` (default: 1), check `max_global_workers` (default: 3).
4. Transition to `scheduled`, create worker via provider.
5. Detect stuck workers (no heartbeat for `heartbeat_timeout_secs`).
6. Collect completed workers, update job state, destroy worker.

Configuration:

```text
MAX_GLOBAL_WORKERS=3
MAX_WORKERS_PER_PROJECT=1
HEARTBEAT_TIMEOUT_SECS=180
JOB_TIMEOUT_SECS=3600
MAX_RETRIES=3
SCHEDULER_INTERVAL_SECS=30
```

#### 1.8 MCP Server

Worker-service MCP server via rmcp:

**Job management:** `jobs_list`, `jobs_create`, `jobs_cancel`, `jobs_pause`, `jobs_resume`, `jobs_attach`, `jobs_detach`, `jobs_status`

**Worker management:** `workers_list`, `workers_status`, `workers_destroy`

**Project management:** `projects_list`, `projects_add`, `projects_remove`

**Workflow management:** `workflows_list`, `workflows_show`

Registered in OpenCode's `opencode.json` alongside CoderyCI's MCP server.

#### 1.9 Web Dashboard

Axum + React SPA:

- `GET /` — Dashboard SPA
- `GET /api/jobs` — All jobs with status/stage/worker info
- `GET /api/jobs/:id` — Job detail with stage history
- `GET /api/workers` — Active workers
- `GET /api/events` — SSE stream (job state changes, worker events)
- `POST /api/jobs/:id/pause|resume|cancel|attach` — Job actions

Shows: job list with status/stage/elapsed time, worker list, workflow progress visualization, log viewer.

#### 1.10 Worker-Facing HTTP API

Agent-runner calls these endpoints:

```text
POST   /api/workers/{id}/register     — worker booted, ready
POST   /api/workers/{id}/heartbeat    — periodic status update
POST   /api/workers/{id}/checkpoint   — stage completed, save state
POST   /api/workers/{id}/complete     — job finished successfully
POST   /api/workers/{id}/fail         — job failed with error
GET    /api/jobs/{id}/spec            — fetch stage config
GET    /api/jobs/{id}/skill/{name}    — fetch skill markdown
```

Heartbeat payload:
```json
{
  "status": "running",
  "current_stage": "edit",
  "token_usage": { "input": 15000, "output": 3000 },
  "files_changed": 5,
  "tool_calls_made": 42,
  "message": "Editing src/main.rs"
}
```

Checkpoint payload:
```json
{
  "stage": "plan",
  "response": { "complexity": "simple", "plan": "..." },
  "session_path": "/workspace/.codery/session.json",
  "git_sha": "abc1234",
  "token_usage": { "input": 8000, "output": 2000 },
  "files_changed": [],
  "next_stage": "edit"
}
```

---

### 2. Workflow Engine

#### 2.1 Workflow YAML Format

A workflow is a state machine. Each stage runs a skill, the skill returns structured JSON, routing expressions evaluate against that JSON to pick the next stage.

```yaml
name: feature
description: "Implement a feature from spec"

stages:
  plan:
    skill: plan
    prompt: |
      Create an implementation plan for: {{input}}
      Project: {{project.repo}} ({{project.branch}})
    response_schema:
      type: object
      properties:
        complexity: { type: string, enum: [simple, complex] }
        plan: { type: string }
      required: [complexity, plan]
    tools: [bash, read, glob, grep]
    max_tokens: 8000
    timeout_secs: 600
    routes:
      - when: 'response.complexity == "simple"'
        next: edit
      - when: 'response.complexity == "complex"'
        next: plan_detail
      - when: 'true'
        next: pause_for_human

  edit:
    skill: implement
    prompt: |
      Implement the following plan: {{input}}
    response_schema:
      type: object
      properties:
        success: { type: boolean }
        files_changed: { type: integer }
      required: [success, files_changed]
    tools: [bash, read, write, edit, glob, grep]
    checkpoint: true
    routes:
      - when: 'response.success && response.files_changed > 0'
        next: test
      - when: 'true'
        next: edit

  test:
    skill: test
    prompt: |
      Run the test suite and fix any failures.
    response_schema:
      type: object
      properties:
        passed: { type: boolean }
        failure_count: { type: integer }
      required: [passed, failure_count]
    tools: [bash, read, write, edit, grep]
    routes:
      - when: 'response.passed'
        next: review
      - when: 'response.failure_count > 3'
        next: pause_for_human
      - when: 'true'
        next: fix

  fix:
    skill: fix
    prompt: |
      Fix the test failures.
      Previous test output: {{stages.test.output}}
    response_schema:
      type: object
      properties:
        fixed: { type: boolean }
        remaining: { type: integer }
      required: [fixed, remaining]
    tools: [bash, read, write, edit, grep]
    routes:
      - when: 'response.fixed'
        next: test
      - when: 'response.remaining > 5'
        next: pause_for_human
      - when: 'true'
        next: edit

  review:
    skill: review
    prompt: |
      Review all changes for correctness and style.
    response_schema:
      type: object
      properties:
        approved: { type: boolean }
        issues: { type: integer }
      required: [approved, issues]
    tools: [bash, read, glob, grep]
    routes:
      - when: 'response.approved'
        next: pr
      - when: 'true'
        next: edit

  pr:
    skill: create_pr
    prompt: "Create a pull request with all changes."
    response_schema:
      type: object
      properties:
        pr_url: { type: string }
      required: [pr_url]
    tools: [bash]
    routes: null

  pause_for_human:
    skill: pause
    prompt: "Pausing for human review."
    routes: null
```

#### 2.2 Skill Files (Markdown)

Skills are markdown files containing agent instructions. No YAML frontmatter. Pure instructional content.

Example — `skills/plan.md`:

```markdown
You are a senior software engineer tasked with creating an implementation plan.

## Instructions

- Explore the project structure first using glob and grep
- Identify all files and modules relevant to the task
- Produce a clear, step-by-step implementation plan
- Estimate the complexity of the task
- Be specific about which files need changes and why

## Constraints

- Do NOT edit any files
- Do NOT write code
- Only read and analyze the codebase

## Approach

1. Start by listing the project structure
2. Identify the entry points and main modules
3. Search for relevant patterns and dependencies
4. Produce your plan with specific file references
```

Built-in skills ship in `crates/trailhead-service/skills/`. User skills in `.codery/skills/` in the project repo. User skills override built-in skills with the same name.

Built-in skills:

| Skill File | Purpose |
|---|---|
| `plan.md` | Read codebase, produce implementation plan |
| `plan_detail.md` | Deeper analysis for complex tasks |
| `implement.md` | Write code to implement a plan |
| `test.md` | Run tests and fix failures |
| `fix.md` | Fix specific identified issues |
| `review.md` | Review code changes |
| `create_pr.md` | Create a pull request |
| `pause.md` | Signal pause for human intervention |

#### 2.3 Prompt Assembly

The agent-runner receives three layers assembled into the system prompt:

```text
Layer 1: Skill content (markdown file)
  ─── divider ───
Layer 2: Response schema injection
  ─── divider ───
Layer 3: Stage prompt (with resolved template variables)
```

Response schema injection format:

```markdown
## Required Response Format

You MUST respond with valid JSON matching this exact schema.
Do NOT include any text outside the JSON object.
Respond ONLY with the JSON, no markdown fences, no commentary.

{
  "type": "object",
  "properties": {
    "complexity": { "type": "string", "enum": ["simple", "complex"] },
    "plan": { "type": "string" }
  },
  "required": ["complexity", "plan"]
}
```

Injected between skill content and stage prompt. Skill instructions about *how to think and act* are preserved. Only output format is mandated by the schema.

#### 2.4 Template Variables

Available in stage `prompt` fields, resolved by MiniJinja:

| Variable | Description |
|---|---|
| `{{input}}` | User's original message (first stage) or previous stage output (subsequent stages) |
| `{{project.repo}}` | Repo URL |
| `{{project.branch}}` | Target branch |
| `{{project.name}}` | Project identifier |
| `{{stages.<id>.output}}` | Specific stage's JSON response |
| `{{stages.<id>.changed_files}}` | Files modified in that stage |
| `{{env.<NAME>}}` | Environment variables |

#### 2.5 Routing Engine

Routing uses CEL (Common Expression Language) expressions evaluated against the stage's JSON response.

Evaluation:
1. Stage completes. Agent-runner returns structured JSON matching response_schema.
2. Workflow engine iterates `routes` top-to-bottom.
3. Each `when:` CEL expression evaluated with `response.*` bound to the JSON response.
4. First match wins. `next:` determines next stage name.
5. `routes: null` means workflow ends or pauses.

CEL is non-Turing complete. No loops, recursion, or side effects. Safe to evaluate arbitrary expressions from config files.

Schema validation: If agent response doesn't match response_schema:
1. Re-prompt agent once: "Your response did not match the required JSON schema. Respond with valid JSON only."
2. If still invalid → stage fails → `failed_retryable`.

---

### 3. Agent Runner (`crates/agent-runner/`)

#### 3.1 Binary Structure

```
crates/agent-runner/
├── Cargo.toml
└── src/
    ├── main.rs           # CLI: run, resume
    ├── lib.rs
    ├── provider/
    │   ├── mod.rs        # LlmProvider trait
    │   ├── anthropic.rs  # Anthropic Messages API via reqwest
    │   └── openai.rs     # OpenAI-compatible via async-openai
    ├── agent/
    │   ├── mod.rs        # Tool loop
    │   └── message.rs    # Message, ToolCall, ToolResult types
    ├── tools/
    │   ├── mod.rs        # Tool trait + registry
    │   ├── bash.rs
    │   ├── file_read.rs
    │   ├── file_write.rs
    │   ├── file_edit.rs
    │   ├── glob.rs
    │   └── grep.rs
    └── session.rs        # JSON session persistence
```

#### 3.2 Dependencies

```toml
[dependencies]
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

#### 3.3 LLM Provider Trait

```rust
#[async_trait]
trait LlmProvider: Send + Sync {
    async fn send(
        &self,
        messages: &[Message],
        tools: &[ToolDef],
        config: &RequestConfig,
    ) -> Result<LlmResponse>;
    fn name(&self) -> &str;
}
```

Anthropic impl: reqwest POST to Messages API, parse tool call/text blocks. ~250 lines.
OpenAI impl: async-openai crate, custom base URL for OpenAI-compatible endpoints. ~80 lines.
Provider selection via `LLM_PROVIDER` env var.

#### 3.4 Tool Trait + Six Tools

```rust
#[async_trait]
trait Tool: Send + Sync {
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    fn parameters_schema(&self) -> serde_json::Value;
    async fn execute(&self, input: serde_json::Value, ctx: &ToolContext) -> Result<String>;
}
```

| Tool | Implementation | Key Details |
|---|---|---|
| `bash` | `tokio::process::Command` | Timeout 120s, working dir = workspace |
| `read` | `std::fs::read_to_string` | Path must be within workspace |
| `write` | `std::fs::write` | Creates parent dirs |
| `edit` | String replace + `similar` diff | old→new, must be unique match |
| `glob` | `glob` crate | Pattern matching |
| `grep` | `regex` crate | Content search with context lines |

All tools enforce workspace boundary — no path traversal.

#### 3.5 Agent Loop

```text
1. Receive: system prompt, allowed tools, max_tokens, timeout
2. Send messages to LLM with tool definitions
3. If Stop → return response text, parse as JSON
4. If ToolUse → execute tool calls, append results, loop
5. If MaxTokens → truncate, return
6. Enforce: max_tool_calls, token budget, timeout per stage
7. Heartbeat after each LLM call, checkpoint at stage boundary
```

#### 3.6 Session Persistence

Session = full message history serialized to JSON at `/workspace/.codery/session.json`. On resume, load and append.

#### 3.7 Execution Boundaries

| Boundary | Default | Configurable |
|---|---|---|
| Max tool calls per stage | 200 | Per-stage in workflow |
| Max tokens per stage | 8096 | Per-stage in workflow |
| Stage timeout | 600s | Per-stage in workflow |
| Bash timeout | 120s | Global config |
| Max files changed before checkpoint | 20 | Global config |

---

### 4. SQLite Database Schema

```sql
CREATE TABLE projects (
    id          TEXT PRIMARY KEY,
    repo_url    TEXT NOT NULL,
    branch      TEXT NOT NULL DEFAULT 'main',
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL
);

CREATE TABLE jobs (
    id              TEXT PRIMARY KEY,
    project_id      TEXT NOT NULL REFERENCES projects(id),
    description     TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'queued',
    worker_id       TEXT,
    branch          TEXT,
    workflow_name   TEXT,
    current_stage   TEXT,
    stage_history   TEXT DEFAULT '[]',
    attempt         INTEGER NOT NULL DEFAULT 1,
    max_attempts    INTEGER NOT NULL DEFAULT 3,
    result          TEXT,
    error           TEXT,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL,
    started_at      TEXT,
    finished_at     TEXT
);

CREATE TABLE workers (
    id              TEXT PRIMARY KEY,
    job_id          TEXT REFERENCES jobs(id),
    provider        TEXT NOT NULL,
    provider_id     TEXT,
    status          TEXT NOT NULL DEFAULT 'creating',
    ip_address      TEXT,
    workspace_path  TEXT,
    heartbeat_at    TEXT,
    created_at      TEXT NOT NULL,
    destroyed_at    TEXT
);

CREATE TABLE checkpoints (
    id              TEXT PRIMARY KEY,
    job_id          TEXT NOT NULL REFERENCES jobs(id),
    stage           TEXT NOT NULL,
    response        TEXT NOT NULL,
    session_path    TEXT NOT NULL,
    git_sha         TEXT NOT NULL,
    token_usage     TEXT,
    files_changed   TEXT DEFAULT '[]',
    created_at      TEXT NOT NULL
);

CREATE TABLE prompt_history (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    job_id          TEXT NOT NULL REFERENCES jobs(id),
    stage           TEXT NOT NULL,
    role            TEXT NOT NULL,
    content         TEXT NOT NULL,
    tool_calls      TEXT,
    tool_results    TEXT,
    token_usage     TEXT,
    created_at      TEXT NOT NULL
);

CREATE TABLE workflows (
    name            TEXT PRIMARY KEY,
    content         TEXT NOT NULL,
    source          TEXT NOT NULL,
    project_id      TEXT REFERENCES projects(id),
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_project ON jobs(project_id);
CREATE INDEX idx_workers_job ON workers(job_id);
CREATE INDEX idx_checkpoints_job ON checkpoints(job_id);
```

SQLite WAL mode. Database file at `/opt/codery/trailhead.db`.

---

### 5. IDE / Human Attach

1. Job routes to `pause_for_human` → status `paused_for_human`.
2. Worker alive for grace period (default 30 min).
3. Human runs: `trailhead-service jobs attach <id> --ide cursor`.
4. IDE adapter opens workspace directory.
5. Human edits code, runs tests, optionally writes `.codery/guidance.md`.
6. Human detaches.
7. Worker-service reads Git diff since checkpoint.
8. New worker created, agent-runner resumes with human's changes injected.
9. Workflow continues.

Attach boundary is Git + filesystem. Any IDE that can open a directory works.

---

### 6. Scope Estimates

| Component | Lines (est.) |
|---|---|
| Workflow engine (parser + resolver + router) | ~600-800 |
| WorkerProvider trait + Docker impl | ~500-600 |
| IdeAdapter trait + adapters | ~200-300 |
| Job state machine | ~300-400 |
| Scheduler | ~200-300 |
| SQLite schema + queries | ~300-400 |
| MCP server | ~400-500 |
| Worker HTTP API | ~200-300 |
| Web dashboard backend | ~300-400 |
| Web dashboard frontend | ~500-800 |
| Agent runner (full) | ~1,200-1,500 |
| Skills + Workflows | ~400 |
| **Total** | **~5,000-7,000** |

### 7. Phase 1 Exclusions

- Temporal / durable execution platform
- Cloud provider adapters (Hetzner, AWS)
- Multi-VPS or distributed workers
- Advanced scheduling (priority queues, dependency graphs)
- Parallel agent execution within a single job
- MCP server inside worker containers
- Cost tracking or budget alerts

### 8. Design Principles

1. **Durable orchestration above, disposable execution below.** Service owns state. Workers come and go.
2. **Git as the attach boundary.** Humans and agents share the workspace.
3. **Skills are markdown.** Human-readable, version-controllable, easy to write.
4. **Workflows are state machines.** Stages, routing, schemas. CEL for safe routing.
5. **Provider-agnostic.** LLM providers and cloud providers interchangeable via traits.
6. **IDE-agnostic.** Any IDE that opens a directory.
7. **Boring first.** SQLite, local Docker, round-robin. Scale later.
