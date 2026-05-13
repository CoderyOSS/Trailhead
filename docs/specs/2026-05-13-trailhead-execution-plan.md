# Trailhead Execution Plan (Test-First)

> **Mode:** Subagent-driven development. Fresh subagent per task. Two-stage review (spec + quality) after each.
> **Branch:** Direct on main.
> **Parallelism:** Sequential within phases. Agent-runner and workflow engine are independent crates but share one git repo — run sequentially.
> **Test-first:** Failing E2E tests written before each phase's implementation.

---

## Build & Test Commands

| Action | Command |
|--------|---------|
| Cargo check | `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check 2>&1'` |
| Cargo test | `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo test 2>&1'` |
| Cargo check one crate | Same but `cargo check -p <crate> 2>&1` |
| E2E tests | `cd tests/probes && bun test` |
| E2E tests one dir | `cd tests/probes && bun test workflow/` |

---

## Phase 0: Test Infrastructure

### Task 0: Set up E2E test directory and CoderyProbes

**Files:**
- Create: `tests/probes/package.json`
- Create: `tests/probes/probes.yml`
- Create: `tests/probes/adapter.ts`
- Create: `tests/probes/helpers.ts`
- Create: `tests/probes/fixtures/` (directory)

**Steps:**
- [ ] Init `tests/probes/` with `bun init`
- [ ] Symlink CoderyProbes: `ln -s ~/projects/CoderyProbes tests/probes/node_modules/@codery/probes`
- [ ] Write `probes.yml` with SQL, HTTP client, FS interface configs
- [ ] Write `adapter.ts` — wire protocol adapter for trailhead-service HTTP API
- [ ] Write `helpers.ts` — test utilities, proof recording
- [ ] Verify `cd tests/probes && bun test` runs (0 tests pass)
- [ ] Commit: `chore: set up E2E test infrastructure with CoderyProbes`

---

## Phase 1: Foundation

### Task 1: Scaffold Cargo Workspace

**Steps:**
- [ ] Create workspace `Cargo.toml` with 3 members
- [ ] Create `crates/trailhead-core/` with types (JobId, WorkerId, JobStatus, WorkerStatus, TokenUsage, HeartbeatPayload, CheckpointPayload)
- [ ] Create `crates/agent-runner/Cargo.toml` with deps
- [ ] Create `crates/trailhead-service/Cargo.toml` with deps
- [ ] Create stub `main.rs` for each binary crate
- [ ] Create `.gitignore`
- [ ] Verify: `cargo check`
- [ ] Commit: `feat: scaffold Cargo workspace with three crates`

**Full code:** See implementation plan Task 1.

---

## Phase 2: Agent Runner — Tests First, Then Implementation

### Task 2: Write failing agent-runner E2E tests

**Files:**
- Create: `tests/probes/agent-runner/tools.test.ts`
- Create: `tests/probes/agent-runner/session.test.ts`

**What tests verify:**
- `tools.test.ts`: Compile agent-runner, run with bash/read/write/edit commands against test workspace, verify output via FS probe
- `session.test.ts`: Run agent-runner, verify session JSON written to workspace, verify session load/resume

**Steps:**
- [ ] Write failing `tools.test.ts` — tests for bash tool execution, file read/write/edit, glob, grep
- [ ] Write failing `session.test.ts` — tests for session creation, save, load
- [ ] Verify tests fail: `cd tests/probes && bun test agent-runner/`
- [ ] Commit: `test: add failing agent-runner E2E tests`

### Task 3: Message Types + Provider Stub

**Steps:**
- [ ] Create `agent/` module with Message, Role, ToolCall, ToolResult, FinishReason, LlmResponse
- [ ] Create `provider/` module with TokenUsage, ToolDef, RequestConfig, LlmProvider trait
- [ ] Create empty `tools/` and `session/` stubs
- [ ] Verify: `cargo check -p agent-runner`
- [ ] Commit

**Full code:** See implementation plan Tasks 2-3.

### Task 4: Anthropic Provider

**Steps:**
- [ ] Implement AnthropicProvider (reqwest POST to Messages API)
- [ ] Create OpenAI stub (bail!("not yet implemented"))
- [ ] Verify: `cargo check -p agent-runner`
- [ ] Commit

**Full code:** See implementation plan Task 3.

### Task 5: Tool Trait + All Six Tools

**Steps:**
- [ ] Write Tool trait, ToolContext, ToolRegistry
- [ ] Implement BashTool, FileReadTool, FileWriteTool, FileEditTool, GlobTool, GrepTool
- [ ] Verify: `cargo check -p agent-runner`
- [ ] Commit

**Full code:** See implementation plan Tasks 4-5.

### Task 6: Agent Loop

**Steps:**
- [ ] Implement run_agent_loop with tool dispatch, max_tool_calls enforcement
- [ ] Verify: `cargo check -p agent-runner`
- [ ] Commit

**Full code:** See implementation plan Task 6.

### Task 7: Session Persistence + CLI

**Steps:**
- [ ] Implement Session struct with save/load
- [ ] Write CLI main with `run` and `resume` subcommands
- [ ] Verify: `cargo check -p agent-runner`
- [ ] Run E2E tests: `cd tests/probes && bun test agent-runner/`
- [ ] Commit

**Full code:** See implementation plan Task 7.

**Gate:** All agent-runner E2E tests must pass before proceeding.

---

## Phase 3: Workflow Engine — Tests First, Then Implementation

### Task 8: Write failing workflow E2E tests

**Files:**
- Create: `tests/probes/workflow/parser.test.ts`
- Create: `tests/probes/workflow/resolver.test.ts`
- Create: `tests/probes/workflow/router.test.ts`
- Create: `tests/probes/workflow/engine.test.ts`
- Create: `tests/probes/fixtures/workflows/` (test YAML files)

**What tests verify:**
- `parser.test.ts`: Valid/invalid YAML parsing via HTTP API or direct invocation
- `resolver.test.ts`: Template variable resolution with input, stages, project vars
- `router.test.ts`: CEL expression evaluation with various conditions
- `engine.test.ts`: Full workflow stage advancement, routing, pause_for_human

**Steps:**
- [ ] Create test fixture YAML files in `fixtures/workflows/`
- [ ] Write failing parser tests
- [ ] Write failing resolver tests
- [ ] Write failing router tests
- [ ] Write failing engine tests
- [ ] Verify tests fail: `cd tests/probes && bun test workflow/`
- [ ] Commit: `test: add failing workflow E2E tests`

### Task 9: Workflow YAML Parser

**Steps:**
- [ ] Implement parse_workflow with validation
- [ ] Write Rust unit tests (parse_simple, reject_empty, reject_unknown_route)
- [ ] Verify: `cargo test -p trailhead-service parser`
- [ ] Run E2E: `cd tests/probes && bun test workflow/parser.test.ts`
- [ ] Commit

**Full code:** See implementation plan Task 8.

### Task 10: Template Resolver

**Steps:**
- [ ] Implement resolve_prompt with minijinja (input, stages, project, env vars)
- [ ] Write Rust unit tests
- [ ] Verify: `cargo test -p trailhead-service resolver`
- [ ] Run E2E: `cd tests/probes && bun test workflow/resolver.test.ts`
- [ ] Commit

**Full code:** See implementation plan Task 9.

### Task 11: CEL Router

**Steps:**
- [ ] Implement evaluate_routes and evaluate_condition
- [ ] Write Rust unit tests (string eq, boolean, numeric, compound, no match)
- [ ] Verify: `cargo test -p trailhead-service router`
- [ ] Run E2E: `cd tests/probes && bun test workflow/router.test.ts`
- [ ] Commit

**Full code:** See implementation plan Task 10.

### Task 12: Workflow Engine

**Steps:**
- [ ] Implement Engine struct with stage tracking, process_response, resolve_stage_prompt
- [ ] Verify: `cargo check -p trailhead-service`
- [ ] Run E2E: `cd tests/probes && bun test workflow/`
- [ ] Commit

**Full code:** See implementation plan Task 11.

**Gate:** All workflow E2E tests must pass before proceeding.

---

## Phase 4: Trailhead Service — Tests First, Then Implementation

### Task 13: Write failing service E2E tests

**Files:**
- Create: `tests/probes/service/db.test.ts`
- Create: `tests/probes/service/jobs.test.ts`
- Create: `tests/probes/service/api.test.ts`
- Create: `tests/probes/service/scheduler.test.ts`
- Create: `tests/probes/service/web.test.ts`
- Create: `tests/probes/fixtures/seed.sql` (initial DB seed data)

**What tests verify:**
- `db.test.ts`: SQL probe seeds tables, verifies schema, tests queries
- `jobs.test.ts`: Job state machine transitions via API, verified via SQL probe
- `api.test.ts`: Worker HTTP API endpoints (register, heartbeat, checkpoint, complete, fail)
- `scheduler.test.ts`: Scheduling behavior (capacity, dequeuing, stuck detection)
- `web.test.ts`: Dashboard API endpoints (job list, worker list, SSE events)

**Steps:**
- [ ] Write seed SQL fixture
- [ ] Write failing DB tests
- [ ] Write failing jobs tests
- [ ] Write failing API tests
- [ ] Write failing scheduler tests
- [ ] Write failing web dashboard tests
- [ ] Verify tests fail: `cd tests/probes && bun test service/`
- [ ] Commit: `test: add failing trailhead-service E2E tests`

### Task 14: SQLite Database Layer

**Files:** `crates/trailhead-service/src/db.rs`

**Scope:**
- Schema: projects, jobs, workers, checkpoints, prompt_history, workflows tables
- WAL mode
- Methods: create_job, update_job_status, get_queued_jobs, assign_worker, save_checkpoint, update_job_stage, heartbeat
- All rusqlite with bundled feature

**Steps:**
- [ ] Implement full db.rs
- [ ] Verify: `cargo check -p trailhead-service`
- [ ] Run E2E: `cd tests/probes && bun test service/db.test.ts`
- [ ] Commit

### Task 15: WorkerProvider Trait + DockerProvider

**Files:**
- `crates/trailhead-service/src/provider/mod.rs`
- `crates/trailhead-service/src/provider/docker.rs`

**Scope:**
- WorkerProvider trait: create_worker, destroy_worker, get_status, get_logs, list_workers
- DockerProvider using bollard: pull image, create container, inject env vars, start, monitor

**Steps:**
- [ ] Implement trait + Docker impl
- [ ] Verify: `cargo check -p trailhead-service`
- [ ] Commit

### Task 16: Job State Machine

**Files:** `crates/trailhead-service/src/jobs.rs`

**Scope:**
- Status transitions with validation per design spec state machine
- Methods: transition, can_transition, is_terminal
- Test all valid and invalid transitions

**Steps:**
- [ ] Implement jobs.rs
- [ ] Verify: `cargo test -p trailhead-service jobs`
- [ ] Run E2E: `cd tests/probes && bun test service/jobs.test.ts`
- [ ] Commit

### Task 17: Scheduler

**Files:** `crates/trailhead-service/src/scheduler.rs`

**Scope:**
- Round-robin loop with tokio::time::interval
- Capacity checks (MAX_GLOBAL_WORKERS, MAX_WORKERS_PER_PROJECT)
- Stuck worker detection (HEARTBEAT_TIMEOUT_SECS)
- Configurable via env vars

**Steps:**
- [ ] Implement scheduler.rs
- [ ] Verify: `cargo check -p trailhead-service`
- [ ] Run E2E: `cd tests/probes && bun test service/scheduler.test.ts`
- [ ] Commit

### Task 18: Worker HTTP API

**Files:** `crates/trailhead-service/src/api.rs`

**Scope:**
- Axum routes: register, heartbeat, checkpoint, complete, fail, config, skill
- JSON request/response
- Delegates to db/workers/jobs

**Steps:**
- [ ] Implement api.rs
- [ ] Verify: `cargo check -p trailhead-service`
- [ ] Run E2E: `cd tests/probes && bun test service/api.test.ts`
- [ ] Commit

### Task 19: IDE Adapters

**Files:** `crates/trailhead-service/src/ide/` (mod.rs, opencode.rs, cursor.rs, vscode.rs, shell.rs, ssh.rs)

**Scope:**
- IdeAdapter trait: name, detect, open_workspace, is_attached, detach
- 5 adapters, ~40 lines each
- Auto-detect order: OpenCode → Cursor → VS Code → Shell

**Steps:**
- [ ] Implement trait + all adapters
- [ ] Verify: `cargo check -p trailhead-service`
- [ ] Commit

### Task 20: MCP Server

**Files:** `crates/trailhead-service/src/mcp.rs`

**Scope:**
- rmcp-based MCP server
- Tools: jobs_list, jobs_create, jobs_cancel, jobs_pause, jobs_resume, jobs_attach, jobs_detach, workers_list, workers_destroy, projects_list, projects_add, workflows_list, workflows_show
- Each tool delegates to db/workers/scheduler

**Steps:**
- [ ] Implement mcp.rs
- [ ] Verify: `cargo check -p trailhead-service`
- [ ] Commit

### Task 21: Web Dashboard Backend

**Files:** `crates/trailhead-service/src/web.rs`

**Scope:**
- Axum routes: GET /api/jobs, GET /api/workers, GET /api/events (SSE), POST actions
- Serves built React SPA from ui/dist/

**Steps:**
- [ ] Implement web.rs
- [ ] Verify: `cargo check -p trailhead-service`
- [ ] Run E2E: `cd tests/probes && bun test service/web.test.ts`
- [ ] Commit

### Task 22: Web Dashboard Frontend

**Files:** `crates/trailhead-service/ui/` (full React + Vite app)

**Scope:**
- Job list with status/stage badges
- Worker list
- Basic controls (pause, resume, cancel)
- Build produces ui/dist/

**Steps:**
- [ ] Create React app with Vite
- [ ] Implement components: App, JobList, WorkerList, types
- [ ] Build: `cd ui && npm install && npm run build`
- [ ] Commit

### Task 23: Skills + Built-in Workflows

**Files:**
- `crates/trailhead-service/skills/` (8 markdown files)
- `crates/trailhead-service/workflows/` (4 YAML files)

**Scope:**
- Skills: plan, plan_detail, implement, test, fix, review, create_pr, pause
- Workflows: feature, quick-fix, exploration, refactor

**Steps:**
- [ ] Write 8 skill markdown files per design spec
- [ ] Write 4 workflow YAML files per design spec
- [ ] Commit

### Task 24: CLI + Daemon Mode

**Files:** `crates/trailhead-service/src/main.rs`

**Scope:**
- CLI: daemon, jobs list|create|pause|resume|cancel|attach|detach, workers list|destroy, projects list|add
- Daemon mode: MCP + HTTP API + scheduler + dashboard via tokio::select!

**Steps:**
- [ ] Implement full CLI with arg parsing
- [ ] Implement daemon mode
- [ ] Verify: `cargo check -p trailhead-service`
- [ ] Run all E2E: `cd tests/probes && bun test service/`
- [ ] Commit

**Gate:** All service E2E tests must pass before proceeding.

---

## Phase 5: Integration + CI/CD

### Task 25: Write failing integration test

**Files:** `tests/probes/integration/full-job.test.ts`

**Scope:**
- Complete job lifecycle: create → schedule → run → complete
- SQL probe verifies state transitions
- HTTP probe verifies API responses
- FS probe verifies workspace changes

**Steps:**
- [ ] Write failing integration test
- [ ] Verify fails: `cd tests/probes && bun test integration/`
- [ ] Commit: `test: add failing full-job integration test`

### Task 26: CI/CD

**Files:**
- `containers/agent-runner/Dockerfile`
- `.github/workflows/build-agent-runner.yml`
- `.github/workflows/release.yml`

**Scope:**
- Multi-stage Rust build Dockerfile for agent-runner
- Build on push workflow
- Release on tag workflow

**Steps:**
- [ ] Write agent-runner Dockerfile
- [ ] Write build workflow
- [ ] Write release workflow
- [ ] Run full E2E suite: `cd tests/probes && bun test`
- [ ] Commit

**Gate:** All tests pass. Phase 1 complete.

---

## Subagent Workflow Per Task

```
1. Dispatch implementer subagent
   - Provide: full task spec + relevant failing test files + context
   - Subagent: implements, runs cargo check/test, runs bun test, self-reviews, commits

2. Dispatch spec compliance reviewer
   - Provide: task spec + git diff
   - Checks: all requirements met, nothing missing, nothing extra

3. If spec issues → implementer fixes → re-review

4. Dispatch code quality reviewer
   - Provide: git diff + neighboring files for convention check
   - Checks: style, error handling, no unwrap, no comments, idiomatic

5. If quality issues → implementer fixes → re-review

6. Mark task complete, proceed
```

---

## Progress Tracking

| Phase | Task | Description | Status |
|-------|------|-------------|--------|
| 0 | 0 | Test infrastructure | ⬜ Pending |
| 1 | 1 | Scaffold workspace | ⬜ Pending |
| 2 | 2 | Agent-runner E2E tests (failing) | ⬜ Pending |
| 2 | 3 | Message types + provider stub | ⬜ Pending |
| 2 | 4 | Anthropic provider | ⬜ Pending |
| 2 | 5 | Tool trait + all six tools | ⬜ Pending |
| 2 | 6 | Agent loop | ⬜ Pending |
| 2 | 7 | Session + CLI | ⬜ Pending |
| 3 | 8 | Workflow E2E tests (failing) | ⬜ Pending |
| 3 | 9 | Workflow YAML parser | ⬜ Pending |
| 3 | 10 | Template resolver | ⬜ Pending |
| 3 | 11 | CEL router | ⬜ Pending |
| 3 | 12 | Workflow engine | ⬜ Pending |
| 4 | 13 | Service E2E tests (failing) | ⬜ Pending |
| 4 | 14 | SQLite database layer | ⬜ Pending |
| 4 | 15 | WorkerProvider + DockerProvider | ⬜ Pending |
| 4 | 16 | Job state machine | ⬜ Pending |
| 4 | 17 | Scheduler | ⬜ Pending |
| 4 | 18 | Worker HTTP API | ⬜ Pending |
| 4 | 19 | IDE adapters | ⬜ Pending |
| 4 | 20 | MCP server | ⬜ Pending |
| 4 | 21 | Web dashboard backend | ⬜ Pending |
| 4 | 22 | Web dashboard frontend | ⬜ Pending |
| 4 | 23 | Skills + built-in workflows | ⬜ Pending |
| 4 | 24 | CLI + daemon mode | ⬜ Pending |
| 5 | 25 | Integration test (failing) | ⬜ Pending |
| 5 | 26 | CI/CD | ⬜ Pending |
