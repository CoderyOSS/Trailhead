# Trailhead Service - Agent Guide

## Project Layout

```
CoderyTrailhead/
├── AGENTS.md                       ← This file (repo-level orchestration)
├── frontend/                       ← Flutter SPA (web + iOS)
│   ├── AGENTS.md                   ← Frontend-specific instructions
│   └── ...
├── crates/trailhead-service/       ← Rust backend
│   ├── AGENTS.md                   ← Backend-specific instructions
│   └── ...
├── openspec/                       ← OpenSpec change proposals
└── containers/worker/              ← Docker worker container
```

For frontend work, read `frontend/AGENTS.md`. For backend work, read `crates/trailhead-service/AGENTS.md`.

## Knowledge Graph (graphify)

The repo ships a committed knowledge graph in `graphify-out/` (graph.json, graph.html, GRAPH_REPORT.md, manifest.json, .graphify_labels.json). Treat any codebase question as a graphify query first:

```bash
graphify query "how does X work"           # BFS traversal
graphify path "AuthModule" "Database"      # shortest path between nodes
graphify explain "SwinTransformer"         # plain-language node explainer
```

A **post-commit hook** (`.git/hooks/post-commit`, not tracked by git) regenerates and re-commits the graph after every code change (`.rs/.dart/.toml/.ts/.yaml/.json/etc.`). Doc/markdown changes do not trigger it — run `/graphify --update` manually for those. The inner `[graphify]` commit uses `--no-verify` and never blocks the original commit.

**Fresh clone setup** (hook is not shared via git):
1. Run `/graphify .` once to build the initial graph
2. Re-create the hook: see `hooks/post-commit` template in repo history (commit `93f7a5f`), or run `graphify hook install` then add the auto-recommit block

## ⚠️ CRITICAL: Design Prototype vs Real Product

| Directory | What it is | Language | Do NOT edit |
|-----------|-----------|----------|-------------|
| `frontend/` | **THE REAL PRODUCT** — Flutter app | Dart | |
| `design/` | **DESIGN PROTOTYPE** — HTML/JS exploration | React/JSX | ✓ |
| `design/export/`, `design/handoff/` | Build outputs of prototype | JSX | ✓ |

When asked to implement UI features, **ALWAYS work in `frontend/`**. The `design/`
files look similar (Canvas, WorkerNode, GraphCanvas) but are **NOT** the source of
truth. They are a reference for design direction only.

## Purpose

Trailhead Service = AI workflow orchestration. Runs multi-stage LLM workflows across ephemeral worker containers. Workers code on USER projects, not Trailhead itself.

## Agent Environment Setup

**Critical:** Trailhead runs on the **host machine**, not inside this container. Access via:
- MCP: `trailhead` server at `http://host.docker.internal:4050/mcp/sse`
- API: `http://host.docker.internal:4050/api/v1/*`

**MCP Tools Available:**
- `jobs_create` / `jobs_list` / `jobs_cancel` / `jobs_pause` / `jobs_resume` / `jobs_retry` / `jobs_attach` / `jobs_detach`
- `workers_list` / `workers_destroy`
- `projects_list` / `projects_add`
- `workflows_list` / `workflows_show`
- `secrets_list` / `secrets_set` / `secrets_delete`

**Event-Driven Scheduling (v0.1.0+):** Jobs launch **instantly** on creation via `tokio::sync::watch` channel. No 30s polling delay.

## Architecture

```
Trailhead (Rust, runs on host)
├── Scheduler  : event-driven job scheduling, spawns workers via Docker
├── Database   : SQLite (jobs, workflows, workers, checkpoints)
├── MCP Server : exposes tools for IDE integration
└── Web API    : REST endpoints for external control

Worker Container (opencode-ai)
├── project directory bind-mounted at /workspace
├── Runs workflow stages via opencode
├── Scheduler drives completion (not the worker)
└── Destroyed when done
```

## Core Data Model

**Job**: Single workflow execution
- `project_id`: which repo to work on
- `workflow_name`: which workflow YAML to run
- `status`: queued → running → completed/failed/cancelled
- `project_path`: host path to the git project, bind-mounted into worker at `/workspace`
- `current_stage`: which step we're on
- `attempt`: retry counter (max_attempts=3)

**Workflow**: Multi-stage YAML definition
```yaml
name: my-workflow
stages:
  - name: analyze
    prompt: "Read the code and report bugs"
  - name: fix
    prompt: "Fix the bugs you found"
```

**Worker**: Docker container instance
- `provider`: "docker" (k8s planned)
- `status`: creating → running → destroying
- `project_path`: host project path mounted at `/workspace`
- `job_id`: links back to job

## Feature Status

### Implemented (✅)
- Job CRUD via REST API and MCP
- Docker worker spawning/cleanup
- SQLite persistence
- Workflow YAML parser
- MCP tool server
- Per-job project_path override
- Job state transitions (pause/resume/cancel/retry)
- Automatic retry with backoff for failed_retryable jobs
- Worker listing/destruction
- Project management

### Partial (⚠️)
- IDE attachment: SSH adapter exists, limited testing
- Checkpoint system: schema exists, not fully wired to scheduler
- SSE events: endpoint returns empty stream

### Planned (🚧)
- Human-in-the-loop approvals between stages
- Kubernetes worker provider (swap Docker)
- Real SSE event streaming
- Token usage tracking

## API Endpoints

```
GET  /api/v1/jobs              - list jobs
GET  /api/v1/version           - get service version
POST /api/v1/jobs              - create job {project_id, description, workflow?, branch?, project_path?}
GET  /api/v1/jobs/{id}         - job details
POST /api/v1/jobs/{id}/pause   - pause job
POST /api/v1/jobs/{id}/resume  - resume job
POST /api/v1/jobs/{id}/cancel  - cancel job
POST /api/v1/jobs/{id}/retry   - retry a failed_retryable job
POST /api/v1/jobs/{id}/attach  - attach IDE {ide?: string}

GET  /api/v1/workers           - list workers
POST /api/v1/workers/{id}/destroy

GET  /api/v1/projects          - list projects
POST /api/v1/projects          - add project {repo_url, branch?}

GET  /api/v1/workflows         - list workflows (all rows)
GET  /api/v1/workflows/{name}  - get workflow content + metadata
POST /api/v1/workflows         - create workflow {name, content} (upsert)
PUT  /api/v1/workflows/{name}  - replace workflow content {content}
DELETE /api/v1/workflows/{name} - delete workflow (idempotent)
POST /api/v1/workflows/import  - batch import {files: [{name, content}]}
POST /api/v1/workflows/validate - parse check {content} (scheduler schema)
```

## MCP Tools

```
jobs_list()           - list all jobs
jobs_create(params)   - create job {project_id, description, workflow?}
jobs_cancel(id)       - cancel job
jobs_pause(id)        - pause job
jobs_resume(id)       - resume job
jobs_retry(id)        - retry a failed_retryable job (also auto-retried by scheduler)
jobs_attach(params)   - attach IDE {job_id, ide?}
jobs_detach(id)       - detach

workers_list()        - list workers
workers_destroy(id)   - destroy worker

projects_list()       - list projects
projects_add(params)  - add project {name, repo, branch?}

workflows_list()      - list workflow names
workflows_show(name)  - show workflow YAML content
workflows_create(params) - create/replace workflow {name, content}
workflows_replace(params) - replace workflow content {name, content} (alias of create)
workflows_delete(name)- delete workflow (idempotent)
workflows_import(params) - batch import {files: [{name, content}]}

secrets_list()        - list secrets in /opt/codery/secrets
secrets_set(params)   - set secret {name, value}
secrets_delete(name)  - delete secret

submit_result(params) - mark job complete {job_id, stage, output} (scheduler-driven; workers do not call this)
```

MCP server runs at `/mcp/sse`.

## Configuration

**Environment:**
- `TRAILHEAD_DB`: SQLite path (default: `/opt/codery/trailhead.db`)
- `PROJECT_BASE`: default project root base (default: `/opt/codery/workspaces`, also reads legacy `WORKSPACE_BASE`)
- `RETRY_DELAY_SECS`: base retry delay in seconds per attempt (default: `30`)

**Config file:** `/opt/codery/trailhead/trailhead.toml`
```toml
model = "deepseek/deepseek-v4-flash"

[provider.deepseek]
api = "deepseek"
env = ["DEEPSEEK_API_KEY"]
base_url = "https://api.deepseek.com/v1"
```

**Per-job project path:**
```json
POST /api/v1/jobs
{
  "project_id": "xxx",
  "description": "test job",
  "project_path": "/home/gem/projects/Unbought"
}
```
If set, the project directory is bind-mounted directly. Otherwise: `{PROJECT_BASE}/{project_id}`. The caller is responsible for having the directory in the desired state before creating the job — the scheduler does no git operations on the host.

## Active Changes

- **multi-provider-workers**: `openspec/changes/multi-provider-workers/` — adds
  Daytona VM, k3s pod, and localhost process providers alongside the existing
  Docker provider. See `design.md` for integration details.

## Recently Landed

- **DB-only workflows + frontend YAML integration (v0.4.0)**: Removed
  `seed_builtin_workflows()` and `/opt/codery/trailhead/workflows/` disk
  sync. Workflows live only in SQL, mutable, opaque content (no scheduler
  parser validation on save). New endpoints: `GET/PUT/DELETE
  /workflows/{name}`, `POST /workflows/import`. CLI: `trailhead-service
  workflows <list|show|import|delete>`. Frontend Build mode reads/writes
  workflows via API with debounced autosave.

## Deployment

Service runs on **host machine**, not in containers. Managed by supervisord:

```ini
[program:trailhead]
command=/opt/codery/trailhead/bin/current daemon --db /opt/codery/trailhead.db --config /opt/codery/trailhead/trailhead.toml
user=root
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/trailhead.log
```

Binary installed to `/opt/codery/trailhead/bin/` with `current` symlink pointing to the active version.

Logs: `/var/log/supervisor/trailhead.log`.

Port 4050 firewall-opened for Docker bridge network (172.16.0.0/12).

## Database Schema

**Key columns:**
- `jobs.project_path`: per-job project directory override (bind-mounted into worker)
- `workers.project_path`: project path used by this worker
- `workflows.content_hash`: for change detection
- `checkpoints.commit_message`: for git commits

**Migrations:** Executed individually to handle existing columns:
```rust
const MIGRATIONS: &[&str] = &[
    "ALTER TABLE workflows ADD COLUMN content_hash TEXT",
    "ALTER TABLE checkpoints ADD COLUMN commit_message TEXT DEFAULT ''",
    "ALTER TABLE jobs ADD COLUMN workspace_path TEXT",
    "ALTER TABLE workers ADD COLUMN workspace_path TEXT",
    "ALTER TABLE projects ADD COLUMN name TEXT DEFAULT ''",
    "ALTER TABLE jobs RENAME COLUMN workspace_path TO project_path",
    "ALTER TABLE workers RENAME COLUMN workspace_path TO project_path",
];
```

## Common Tasks

**Create job with explicit project path:**
```bash
curl -X POST http://localhost:4050/api/v1/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "test-project",
    "description": "Fix bug in authentication",
    "workflow": "bugfix",
    "project_path": "/home/gem/projects/Unbought"
  }'
```

**Retry stuck failed_retryable jobs:**
```bash
curl -X POST http://localhost:4050/api/v1/jobs/<job-id>/retry
```

**List running jobs:**
```bash
trailhead-service jobs list --status running
```

**Destroy stuck worker:**
```bash
trailhead-service workers destroy <worker-id>
```

**Add workflow via API:**
```bash
curl -X POST http://localhost:4050/api/v1/workflows \
  -H "Content-Type: application/json" \
  -d '{
    "name": "hello-world",
    "content": "name: hello-world\nstages:\n  - name: greet\n    prompt: \"Say hello\""
  }'
```

**Import workflows from disk (one-time bootstrap or batch load):**
```bash
trailhead-service workflows import /path/to/yaml/dir
trailhead-service workflows list
trailhead-service workflows show hello-world
trailhead-service workflows delete old-workflow
```
Workflows live in SQL only — disk files are not watched or auto-seeded.

## Testing

**E2E test approach:**
1. Use `test-workspace/` dummy git repo
2. Set `project_path` to its absolute host path when creating jobs
3. Worker receives it as bind mount at `/workspace`

**Probe tests:** `tests/probes/`
- Use fixtures in `tests/probes/fixtures/`
- Test schema migrations
- Verify workspace resolution

**Known gap:** No comprehensive E2E test suite yet. Manual testing via `curl` + worker logs.

## Known Issues

1. **Migration failures:** Silent failures if column exists—check logs
2. **SSE events empty:** `/api/v1/events` returns no data
3. **Worker logs:** Not captured centrally—check `docker logs`

## File Layout

```
crates/trailhead-service/
├── src/
│   ├── main.rs       - CLI entry point, daemon setup
│   ├── db.rs         - SQLite schema, migrations
│   ├── scheduler.rs  - Event-driven job scheduling, worker spawning
│   ├── provider/     - Worker provider abstraction
│   │   └── docker.rs - Docker provider
│   ├── workflow/     - YAML parsing
│   ├── jobs.rs       - State machine
│   ├── ide.rs        - IDE adapters (SSH)
│   ├── mcp.rs        - MCP server + tools
│   ├── web.rs        - REST handlers
│   └── api.rs        - Internal API routes
├── workflows/        - Built-in workflow definitions
└── Cargo.toml

tests/probes/         - Integration tests
```

## Versioning

Version is stored in `crates/trailhead-service/Cargo.toml`. Build and deploy are **manual-only** — use the `cut_release` tool in the `github-app` MCP server to cut a release.

**Semver convention:**

| Bump | When |
|------|------|
| `patch` | Bug fixes, docs, config changes, dependency updates |
| `minor` | New features, new API endpoints, new MCP tools (backward compatible) |
| `major` | Breaking changes, removed endpoints, incompatible schema/API changes |

**Release flow:**
1. Review `git log` since the last `trailhead-service-v*` tag to determine bump type
2. Call `cut_release(account, repo, bump, message)` from the `github-app` MCP — this bumps `Cargo.toml`, commits + pushes, and triggers the build workflow automatically
3. Monitor the build run; when complete, call `deploy-trailhead` (`workflow_dispatch`) to deploy

## For Agents Working on This Code

1. **Always use project_path** for E2E tests — point to `test-workspace/` on the host
2. **Migrations**: add to `MIGRATIONS` array, execute individually
3. **New MCP tools**: add to `TrailheadMcpServer` impl with `#[tool]` macro
4. **Worker providers**: implement `WorkerProvider` trait (see `docker.rs`)
5. **Schema changes**: update both CREATE TABLE in fixtures + MIGRATIONS
