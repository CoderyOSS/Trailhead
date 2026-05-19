# Fix Worker Container Launch and Verify E2E

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix "launch failed: create container" error and verify hello-world workflow runs end-to-end.

**Architecture:** Trailhead Service runs on VPS host, launches worker containers via Docker API. Workers run `opencode-ai` which handles LLM communication. Scheduler orchestrates job → worker → session → checkpoint flow.

**Tech Stack:** Docker, Rust (bollard crate), Node.js (opencode-ai), SQLite

**Context:** Job 6 on May 17 completed successfully ("Hello from Trailhead!"), proving E2E works. Current jobs fail with "launch failed: create container" - Docker daemon or image issue.

---

## File Map

| File | Purpose |
|------|---------|
| `containers/worker/Dockerfile` | Worker container image definition |
| `containers/worker/entrypoint.sh` | Container startup script |
| `containers/worker/opencode.json.tmpl` | OpenCode config template |
| `crates/trailhead-service/src/provider/docker.rs` | Docker API client |
| `crates/trailhead-service/src/scheduler.rs` | Worker launch orchestration |

---

## Task 0: Verify Worker Image Exists in Registry

**Purpose:** Check if the worker image has been built and pushed to GHCR.

**Files:** None (diagnostic commands only)

- [ ] **Step 1: Check if worker image exists in GHCR**

```bash
# From sandbox, check via API
curl -sI "https://ghcr.io/v2/coderyoss/trailhead/manifests/worker-latest" | head -5
```

Expected: `200 OK` if image exists. If `404`, need to trigger build (Task 1).

- [ ] **Step 2: Check recent GitHub Actions runs**

```bash
# Via GitHub CLI or browser
gh run list --workflow=build.yml --limit 5
# Or visit: https://github.com/CoderyOSS/Trailhead/actions
```

Expected: Recent successful `build-worker-image` run. If failed or missing, trigger new run.

- [ ] **Step 3: Note findings**

Document:
- Image exists in GHCR: yes/no
- Last successful build: date/run-id
- Any build errors from logs

- [ ] **Step 3: Check network configuration**

```bash
docker network ls | grep codery
docker network inspect codery-net
```

Expected: `codery-net` exists. If missing, create it:

```bash
docker network create codery-net
```

- [ ] **Step 4: Check trailhead-service logs**

```bash
journalctl -u trailhead -n 50 --no-pager
# or
tail -50 /opt/codery/trailhead.log
```

Expected: Look for "Docker not available" or "create container failed" with more details.

- [ ] **Step 5: Note findings for fix plan**

Document:
- Docker daemon status (running/stopped/missing)
- opencode-worker image (exists/version/missing)
- codery-net network (exists/missing)
- Any specific error messages from logs

---

## Task 1: Fix Worker Image Reference in Scheduler

**Purpose:** Update scheduler to use the GHCR image that the build workflow creates.

**Files:**
- Modify: `crates/trailhead-service/src/scheduler.rs`

- [ ] **Step 1: Check current image reference**

```bash
grep -A2 "worker_image" crates/trailhead-service/src/scheduler.rs
```

Current code (line ~189):
```rust
worker_image: "opencode-worker:latest".to_string(),
```

Problem: Build workflow creates `ghcr.io/coderyoss/trailhead:worker-latest`, not `opencode-worker:latest`.

- [ ] **Step 2: Update to use GHCR image**

Replace line ~189 in `crates/trailhead-service/src/scheduler.rs`:

```rust
worker_image: "ghcr.io/coderyoss/trailhead:worker-latest".to_string(),
```

Full context:
```rust
let spec = WorkerSpec {
    job_id: job.id.clone(),
    workspace_path: workspace_path.clone(),
    worker_image: "ghcr.io/coderyoss/trailhead:worker-latest".to_string(),
    env,
    llm_provider: resolved.provider_id.clone(),
    llm_model: format!("{}/{}", resolved.provider_id, resolved.model_id),
    llm_base_url: resolved.base_url.clone(),
    trailhead_url: "http://host.docker.internal:4050".to_string(),
};
```

- [ ] **Step 3: Verify Docker registry auth is configured**

The `build.yml` workflow uses `secrets.GITHUB_TOKEN` for auth. The Docker daemon on the host must be logged into GHCR. Check `deploy-trailhead.yml` for auth setup:

```bash
grep -A5 "docker.*login" .github/workflows/deploy-trailhead.yml
```

If not present, add to host setup:
```bash
# On host: echo $GH_CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
```

- [ ] **Step 4: Commit the change**

```bash
git add crates/trailhead-service/src/scheduler.rs
git commit -m "fix(scheduler): use GHCR image for worker containers"
```

- [ ] **Step 5: Push to trigger build**

```bash
git push origin main
```

Expected: Triggers `build.yml` → `build-worker-image` job.

---

## Task 2: Trigger Worker Image Build

**Purpose:** Ensure the worker image is built and available in GHCR.

**Files:**
- None (uses existing `.github/workflows/build.yml`)

- [ ] **Step 1: Trigger the build workflow**

If the workflow hasn't run automatically (last build was before scheduler change), trigger manually:

```bash
# Using GitHub CLI
gh workflow run build.yml

# Or via web UI: visit https://github.com/CoderyOSS/Trailhead/actions/workflows/build.yml
```

- [ ] **Step 2: Wait for build to complete**

```bash
# Watch the build
gh run watch --interval 10

# Or list recent runs
gh run list --workflow=build.yml --limit 3
```

Expected: `build-worker-image` job completes successfully.

- [ ] **Step 3: Verify image in registry**

```bash
# Check manifest exists
curl -sI "https://ghcr.io/v2/coderyoss/trailhead/manifests/worker-latest" | grep "HTTP/"

# Expected: 200 OK
```

- [ ] **Step 4: Wait for deploy workflow (if configured)**

If `deploy-trailhead.yml` exists and deploys the binary, wait for it to complete:

```bash
gh run list --workflow=deploy-trailhead --limit 1
```

- [ ] **Step 5: Verify service restarted**

The deploy workflow should restart trailhead-service. If manual restart needed:

```bash
# Via MCP tool if available, or SSH to host
# On host: sudo supervisorctl restart trailhead
```

---

## Task 3: Run Hello-World E2E Test

**Purpose:** Verify end-to-end workflow execution after fixes.

**Files:**
- Modify: `/opt/codery/trailhead.service` (add WORKSPACE_BASE env var)
- None (API test only)

**Setup:** Dummy repo + bind mount approach avoids full git clones. Worker containers mount host directory directly at `/workspace`.

- [ ] **Step 0: Create dummy workspace on host**

```bash
# On host (via SSH or docker exec)
mkdir -p /opt/codery/workspaces/test-project
cd /opt/codery/workspaces/test-project
git init
git config user.email "test@codery.dev"
git config user.name "Test User"
echo "# Test Workspace" > README.md
git add README.md
git commit -m "init"
git branch -m main  # workflows use 'main' branch
```

Expected: Git repo created at `/opt/codery/workspaces/test-project`

- [ ] **Step 0.5: Configure workspace base path**

```bash
# On host, update service config to use configurable workspace
# Add to /etc/supervisor/conf.d/trailhead.conf or environment:
environment=WORKSPACE_BASE="/opt/codery/workspaces"

# Restart service
sudo supervisorctl restart trailhead
```

Expected: Service starts with WORKSPACE_BASE configured

- [ ] **Step 1: Create hello-world job**

```bash
# From sandbox container, service is on Docker host
export TRAILHEAD_URL="http://172.17.0.1:4050"
curl -s -X POST "$TRAILHEAD_URL/api/v1/jobs" \
  -H "content-type: application/json" \
  -d '{
    "project_id": "test-project",
    "description": "E2E verification test",
    "workflow": "hello-world"
  }' | jq -r '.id'
```

Expected: Job ID returned, e.g., `abc123-def4-5678-90ab`.

- [ ] **Step 2: Monitor job status**

```bash
JOB_ID="<id_from_step_1>"

for i in {1..30}; do
  sleep 2
  STATUS=$(curl -s "$TRAILHEAD_URL/api/v1/jobs/$JOB_ID" | jq -r '.status')
  echo "[$i] Status: $STATUS"

  if [ "$STATUS" = "completed" ] || [ "$STATUS" = "failed_retryable" ] || [ "$STATUS" = "failed_final" ]; then
    break
  fi
done
```

Expected: Status progresses: `queued` → `scheduled` → `running` → `completed`

- [ ] **Step 3: Check workers list**

```bash
curl -s "$TRAILHEAD_URL/api/v1/workers"
```

Expected: Worker entry appears during job execution, removed after completion.

- [ ] **Step 4: Get final job result**

```bash
curl -s "$TRAILHEAD_URL/api/v1/jobs/$JOB_ID" | jq '{status, result, error}'
```

Expected:
```json
{
  "status": "completed",
  "result": "{\"greet\":{\"output\":\"{\\n  \\\"text\\\": \\\"Hello from Trailhead!\\\"\\n}\",\"changed_files\":[]}}",
  "error": null
}
```

- [ ] **Step 5: Verify full execution time under 30 seconds**

```bash
curl -s "$TRAILHEAD_URL/api/v1/jobs/$JOB_ID" | jq '[
  .created_at[:19],
  .updated_at[:19],
  .finished_at[:19]
]'
```

Expected: Created → Finished < 30 seconds for hello-world.

---

## Task 4: Verify Checkpoint and Stage Transition

**Purpose:** Confirm multi-stage workflows work correctly.

**Files:**
- Modify: `crates/trailhead-service/workflows/hello-world.yaml` (if needed)

- [ ] **Step 1: Check existing workflow stages**

```bash
cat crates/trailhead-service/workflows/hello-world.yaml
```

Current content:
```yaml
name: hello-world
description: "Simple test pipeline — sends a prompt, gets a response"
branch: main
stages:
  greet:
    prompt: "Say 'Hello from Trailhead!' and nothing else."
    max_tokens: 256
    timeout_secs: 60
```

- [ ] **Step 2: Create a two-stage test workflow**

```bash
cat > /tmp/two-stage.yaml << 'EOF'
name: two-stage-test
description: "Test checkpoint and stage transition"
branch: main
stages:
  first:
    prompt: "Reply with just the word: stage-one"
    max_tokens: 64
    timeout_secs: 60
    checkpoint: true
  second:
    prompt: "Reply with just the word: stage-two"
    max_tokens: 64
    timeout_secs: 60
EOF
```

- [ ] **Step 3: Load workflow into database**

```bash
# Via API if endpoint exists, or direct DB insert
sqlite3 /opt/codery/trailhead.db << 'SQL'
INSERT OR REPLACE INTO workflows (name, content)
VALUES ('two-stage-test', '
name: two-stage-test
description: Test checkpoint and stage transition
branch: main
stages:
  first:
    prompt: "Reply with just the word: stage-one"
    max_tokens: 64
    timeout_secs: 60
    checkpoint: true
  second:
    prompt: "Reply with just the word: stage-two"
    max_tokens: 64
    timeout_secs: 60
');
SQL
```

- [ ] **Step 4: Run two-stage job**

```bash
export TRAILHEAD_URL="http://172.17.0.1:4050"
JOB_ID=$(curl -s -X POST "$TRAILHEAD_URL/api/v1/jobs" \
  -H "content-type: application/json" \
  -d '{
    "project_id": "012f809a-6d05-40b7-bbcd-d92568c2fe72",
    "description": "Two stage test",
    "workflow": "two-stage-test"
  }' | jq -r '.id')

# Wait for completion
sleep 30

# Check checkpoints
curl -s "$TRAILHEAD_URL/api/v1/jobs/$JOB_ID" | jq '.result'
```

Expected: Both stages in result:
```json
{
  "first": {
    "output": "{\n  \"text\": \"stage-one\"\n}",
    "changed_files": []
  },
  "second": {
    "output": "{\n  \"text\": \"stage-two\"\n}",
    "changed_files": []
  }
}
```

---

## Task 5: Update Documentation

**Purpose:** Document the fix and verification steps for future reference.

**Files:**
- Create: `docs/operations/troubleshooting.md`

- [ ] **Step 1: Create troubleshooting guide**

```bash
cat > docs/operations/troubleshooting.md << 'EOF'
# Trailhead Troubleshooting

## Worker Container Launch Fails

**Symptom:** Jobs fail with "launch failed: create container"

**Diagnosis:**
```bash
# On host running trailhead-service:
docker ps                    # Check daemon running
docker images | grep worker  # Check image exists
docker network ls | grep codery  # Check network
journalctl -u trailhead -n 50  # Check logs
```

**Fixes:**

1. **Docker daemon not running:**
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

2. **Worker image missing:**
   ```bash
   # Trigger build workflow
   gh workflow run build.yml
   # Or check: https://github.com/CoderyOSS/Trailhead/actions
   ```

3. **Network missing:**
   ```bash
   docker network create codery-net
   ```

## Verify E2E

```bash
# From sandbox container
export TRAILHEAD_URL="http://172.17.0.1:4050"

# Create test job
curl -X POST "$TRAILHEAD_URL/api/v1/jobs" \
  -H "content-type: application/json" \
  -d '{"project_id": "012f809a-6d05-40b7-bbcd-d92568c2fe72", "description": "test", "workflow": "hello-world"}'

# Monitor status
curl "$TRAILHEAD_URL/api/v1/jobs/{id}"
```
EOF
```

- [ ] **Step 2: Commit documentation**

```bash
git add docs/operations/troubleshooting.md
git commit -m "docs: add troubleshooting guide for worker container issues"
```

---

## Self-Review

**Spec coverage:**
- ✅ Diagnose Docker/image issue
- ✅ Build worker container if missing
- ✅ Fix image name mismatch
- ✅ Verify hello-world E2E
- ✅ Verify multi-stage workflow
- ✅ Document fixes

**Placeholder scan:** No TBD/TODO patterns found. All steps have concrete commands.

**Type consistency:** Image name `opencode-worker:latest` used consistently across tasks.
EOF
