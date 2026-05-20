# Trailhead Service - Agent Guide

## Purpose

Trailhead Service = AI workflow orchestration. Runs multi-stage LLM workflows across ephemeral worker containers. Workers code on USER projects, not Trailhead itself.

## Architecture

```
Trailhead (Rust, runs on host)
├── Scheduler  : event-driven job scheduling, spawns workers via Docker
├── Database   : SQLite (jobs, workflows, workers, checkpoints)
├── MCP Server : exposes tools for IDE integration
└── Web API    : REST endpoints for external control

Worker Container (opencode-ai)
├── Clones/boots user project
├── Runs workflow stages
├── Reports back via checkpoint API
└── Destroyed when done
```

## Core Data Model

**Job**: Single workflow execution
- `project_id`: which repo to work on
- `workflow_name`: which workflow YAML to run
- `status`: queued → running → completed/failed/cancelled
- `workspace_path`: per-job override (bind mount location)
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
- `workspace_path`: where code is mounted
- `job_id`: links back to job

## Feature Status

### Implemented (✅)
- Job CRUD via REST API and MCP
- Docker worker spawning/cleanup
- SQLite persistence
- Workflow YAML parser
- MCP tool server
- Per-job workspace_path override
- Job state transitions (pause/resume/cancel)
- Worker listing/destruction
- Project management

### Partial (⚠️)
- Workflow seeding: `seed_builtin_workflows()` exists but workflows must be created manually via API
- IDE attachment: SSH adapter exists, limited testing
- Checkpoint system: schema exists, not fully wired to scheduler
- SSE events: endpoint returns empty stream

### Planned (🚧)
- Auto-seed workflows from directory on startup
- Human-in-the-loop approvals between stages
- Kubernetes worker provider (swap Docker)
- Real SSE event streaming
- Retry with exponential backoff
- Token usage tracking

## API Endpoints

```
GET  /api/v1/jobs              - list jobs
GET  /api/v1/version           - get service version
POST /api/v1/jobs              - create job {project_id, description, workflow?, branch?, workspace_path?}
GET  /api/v1/jobs/{id}         - job details
POST /api/v1/jobs/{id}/pause   - pause job
POST /api/v1/jobs/{id}/resume  - resume job
POST /api/v1/jobs/{id}/cancel  - cancel job
POST /api/v1/jobs/{id}/attach  - attach IDE {ide?: string}

GET  /api/v1/workers           - list workers
POST /api/v1/workers/{id}/destroy

GET  /api/v1/projects          - list projects
POST /api/v1/projects          - add project {repo_url, branch?}

GET  /api/v1/workflows         - list workflows
POST /api/v1/workflows         - create workflow {name, content}
POST /api/v1/workflows/validate - parse check {content}
```

## MCP Tools

```
jobs_list()           - list all jobs
jobs_create(params)   - create job {project_id, description, workflow?}
jobs_cancel(id)       - cancel job
jobs_pause(id)        - pause job
jobs_resume(id)       - resume job
jobs_attach(params)   - attach IDE {job_id, ide?}
jobs_detach(id)       - detach

workers_list()        - list workers
workers_destroy(id)   - destroy worker

projects_list()       - list projects
projects_add(params)  - add project {name, repo, branch?}

workflows_list()      - list workflow names
workflows_show(name)  - show workflow YAML content

secrets_list()        - list secrets in /opt/codery/secrets
secrets_set(params)   - set secret {name, value}
secrets_delete(name)  - delete secret

submit_result(params) - submit stage output {job_id, stage, output}
```

MCP server runs at `/mcp/sse`.

## Configuration

**Environment:**
- `TRAILHEAD_DB`: SQLite path (default: `/opt/codery/trailhead.db`)
- `WORKSPACE_BASE`: default workspace root (default: `/opt/codery/workspaces`)

**Config file:** `/opt/codery/trailhead/trailhead.toml`
```toml
[worker]
image = "opencodeai/worker:latest"

[workflow]
dir = "/opt/codery/trailhead/workflows"
```

**Per-job workspace path:**
```json
POST /api/v1/jobs
{
  "project_id": "xxx",
  "description": "test job",
  "workspace_path": "/home/gem/projects/Unbought"
}
```
If set, worker uses this path directly. Otherwise: `{WORKSPACE_BASE}/{project_id}`.

## Deployment

Service runs on **host machine**, not in containers. Managed by supervisord:

```ini
[program:trailhead]
command=/usr/local/bin/trailhead-service daemon --port 4050
autostart=true
autorestart=true
```

Logs: `/var/log/supervisord/`.

Port 4050 firewall-opened for Docker bridge network (172.16.0.0/12).

## Database Schema

**Key columns:**
- `jobs.workspace_path`: per-job workspace override
- `workers.workspace_path`: worker's mounted path
- `workflows.content_hash`: for change detection
- `checkpoints.commit_message`: for git commits

**Migrations:** Executed individually to handle existing columns:
```rust
const MIGRATIONS: &[&str] = &[
    "ALTER TABLE workflows ADD COLUMN content_hash TEXT",
    "ALTER TABLE checkpoints ADD COLUMN commit_message TEXT DEFAULT ''",
    "ALTER TABLE jobs ADD COLUMN workspace_path TEXT",
    "ALTER TABLE workers ADD COLUMN workspace_path TEXT",
];
```

## Common Tasks

**Create job with custom workspace:**
```bash
curl -X POST http://localhost:4050/api/v1/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "test-project",
    "description": "Fix bug in authentication",
    "workflow": "bugfix",
    "workspace_path": "/home/gem/projects/Unbought"
  }'
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

## Testing

**E2E test approach:**
1. Create dummy git repo
2. Bind mount to container
3. Set `workspace_path` to mount point
4. Worker accesses code without full clone

**Probe tests:** `tests/probes/`
- Use fixtures in `tests/probes/fixtures/`
- Test schema migrations
- Verify workspace resolution

**Known gap:** No comprehensive E2E test suite yet. Manual testing via `curl` + worker logs.

## Known Issues

1. **Workflow seeding not automatic:** Must `POST /api/v1/workflows` manually on first run
2. **Migration failures:** Silent failures if column exists—check logs
3. **SSE events empty:** `/api/v1/events` returns no data
4. **Worker logs:** Not captured centrally—check `docker logs`
5. **No retry loop:** Scheduler picks up jobs once, no retry-on-error

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

## For Agents Working on This Code

1. **Always use workspace_path** for E2E tests—don't require full git clones
2. **Migrations**: add to `MIGRATIONS` array, execute individually
3. **New MCP tools**: add to `TrailheadMcpServer` impl with `#[tool]` macro
4. **Worker providers**: implement `WorkerProvider` trait (see `docker.rs`)
5. **Schema changes**: update both CREATE TABLE in fixtures + MIGRATIONS
