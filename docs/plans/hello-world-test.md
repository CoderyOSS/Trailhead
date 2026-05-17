# Hello-World Test Plan

## Goal

End-to-end test: create a job via MCP, scheduler launches a Docker worker container, worker runs `opencode serve` with hello-world prompt, calls `submit_result`, job completes.

## Prerequisites

- [x] trailhead-service deployed on VPS host (port 4050)
- [x] MCP connected and tools working
- [ ] Workflows auto-seeded in database
- [ ] Worker Docker image built on host
- [ ] Worker container can reach trailhead-service MCP

## Step 1: Code Changes

### 1a. `crates/trailhead-service/src/db.rs` — Workflow auto-seeding with content hash

Add `content_hash TEXT` column to `workflows` table:
```sql
ALTER TABLE workflows ADD COLUMN content_hash TEXT
```
Use `ALTER TABLE` with try/ignore for backward compatibility with existing DB.

New method `seed_builtin_workflows(dir: &Path)`:
- Read `*.yaml` files from `dir`
- **Normalize YAML content before hashing**:
  - Trim leading/trailing whitespace
  - Remove unnecessary newline characters (collapse consecutive `\n` to single `\n`)
  - Remove empty lines and whitespace-only lines
  - Sort YAML keys alphanumerically at every level (using `serde_yaml::Value` → sort `Mapping` keys → re-serialize)
  - This ensures identical logical YAML produces the same hash regardless of formatting differences
- Compute SHA-256 hash of normalized content
- Query DB for existing workflow by name
- If not exists → INSERT with hash
- If exists but hash differs → UPDATE content + hash
- If exists and hash matches → skip

### 1b. `crates/trailhead-service/src/main.rs` — Call seed in daemon_cmd

After `Database::open()`, before `Scheduler::new()`:
```rust
db.seed_builtin_workflows(std::path::Path::new("/opt/codery/trailhead/workflows"))?;
```

### 1c. `crates/trailhead-service/src/provider/docker.rs` — Worker container networking

Add `extra_hosts` to `HostConfig` in `create_worker()`:
```rust
extra_hosts: Some(vec!["host.docker.internal:host-gateway".into()]),
```

This lets worker containers reach `host.docker.internal:4050` (trailhead-service MCP), same as sandbox container.

## Step 2: Build Worker Image on Host

Worker Dockerfile is at `containers/worker/Dockerfile`. Scheduler uses `opencode-worker:latest`.

```bash
# From sandbox, SCP worker files to host
scp -r containers/worker/ deploy@<host>:/tmp/worker/

# On host, build image
ssh deploy@<host> "docker build -t opencode-worker:latest /tmp/worker/"
```

## Step 3: Deploy Code Changes

```bash
git add -A && git commit -m "feat: auto-seed workflows, worker extra_hosts"
github-push
# Wait for CI build (auto-release v0.1.x)
# Trigger deploy workflow
```

## Step 4: Verify Workflows Seeded

```
trailhead_workflows_list()
```

Expected: `["hello-world", "feature", "quick-fix", "exploration", "refactor"]`

## Step 5: Add Project

```
trailhead_projects_add(name="trailhead", repo="https://github.com/CoderyOSS/Trailhead")
```

## Step 6: Create Hello-World Job

```
trailhead_jobs_create(
  project_id=<from step 5>,
  description="hello world test",
  workflow="hello-world"
)
```

## Step 7: Watch Scheduler

Default scheduler interval: 30s. Job lifecycle:
1. `queued` → scheduler picks up
2. `scheduled` → scheduler launches worker container
3. `running` → worker executes opencode serve, sends prompt
4. Worker calls `submit_result` MCP tool
5. `completed` → job done

Monitor:
```
trailhead_jobs_list()
trailhead_workers_list()
```

## Known Concerns

- **Scheduler interval**: 30s default. Job won't start instantly.
- **Workspace directory**: `/opt/codery/workspaces/{project_id}` must exist on host for bind mount. Scheduler should create it, or it needs manual `mkdir -p`.
- **opencode-ai@latest**: Dockerfile installs latest opencode. Version could break. Pin version later.
- **No auto-retry for failed workers**: If worker container crashes, job stays in `running` until timeout (3600s default).
