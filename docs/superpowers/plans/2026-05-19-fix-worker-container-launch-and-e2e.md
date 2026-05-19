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

## Task 0: SSH to Host and Diagnose Docker

**Purpose:** Access the host where trailhead-service runs to diagnose why container creation fails.

**Files:** None (diagnostic commands only)

- [ ] **Step 1: SSH to apps server and check Docker daemon**

```bash
ssh gem@apps
docker ps
docker info
```

Expected: Docker responds with version info. If "command not found" or "daemon not running", start Docker.

- [ ] **Step 2: Check for opencode-worker image**

```bash
docker images | grep opencode
```

Expected: `opencode-worker` or `opencode-worker:latest` listed. If missing, image needs to be built (Task 1).

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

## Task 1: Build Worker Container Image

**Purpose:** If opencode-worker image is missing, build and tag it.

**Files:**
- Modify: `containers/worker/Dockerfile`
- Modify: `containers/worker/entrypoint.sh`

- [ ] **Step 1: Check Dockerfile from project**

```bash
cd /home/gem/projects/CoderyTrailhead
cat containers/worker/Dockerfile
```

Expected content:
```dockerfile
FROM node:22-bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends git ripgrep && rm -rf /var/lib/apt/lists/*
RUN npm install -g opencode-ai@latest
WORKDIR /workspace
COPY opencode.json.tmpl /etc/opencode/opencode.json.tmpl
COPY AGENTS.md /etc/opencode/AGENTS.md
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENV OPENCODE_SERVER_PASSWORD=""
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

- [ ] **Step 2: Check entrypoint.sh exists and is executable**

```bash
cat containers/worker/entrypoint.sh
ls -l containers/worker/entrypoint.sh
```

Expected: executable script with `chmod +x` in Dockerfile.

- [ ] **Step 3: Build the image**

```bash
cd /home/gem/projects/CoderyTrailhead
docker build -t opencode-worker:latest -f containers/worker/Dockerfile .
```

Expected: Build completes successfully with image ID.

- [ ] **Step 4: Verify image built**

```bash
docker images | grep opencode-worker
```

Expected: `opencode-worker latest <image-id> <size>`

- [ ] **Step 5: Test container startup manually**

```bash
docker run --rm -e DEEPSEEK_API_KEY=sk-test -e LLM_BASE_URL=https://api.deepseek.com/v1 opencode-worker:latest &
sleep 5
docker ps
```

Expected: Container running, listening on port 8080. Clean up:

```bash
docker ps -q | xargs docker stop
```

- [ ] **Step 6: Commit image to registry (optional)**

If using GHCR or another registry:

```bash
# Tag for registry
docker tag opencode-worker:latest ghcr.io/coderyoss/opencode-worker:latest

# Push (requires GH_TOKEN)
echo $GH_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
docker push ghcr.io/coderyoss/opencode-worker:latest
```

---

## Task 2: Fix Worker Spec if Image Name Mismatch

**Purpose:** Ensure scheduler uses correct image name when launching workers.

**Files:**
- Modify: `crates/trailhead-service/src/scheduler.rs`

- [ ] **Step 1: Check current worker image reference**

```bash
grep -n "worker_image\|opencode" crates/trailhead-service/src/scheduler.rs
```

Current code (line ~189):
```rust
let spec = WorkerSpec {
    job_id: job.id.clone(),
    workspace_path: workspace_path.clone(),
    worker_image: "opencode-worker:latest".to_string(),
    // ...
};
```

- [ ] **Step 2: Verify image name matches built image**

If image built in Task 1 is `opencode-worker:latest`, no change needed.
If using registry image, update to:

```rust
worker_image: "ghcr.io/coderyoss/opencode-worker:latest".to_string(),
```

- [ ] **Step 3: Rebuild trailhead-service if changed**

```bash
cargo build --release -p trailhead-service
```

Expected: Build completes without errors.

- [ ] **Step 4: Deploy updated binary**

```bash
# If on apps server:
sudo cp target/release/trailhead-service /opt/codery/trailhead/bin/current
sudo supervisorctl restart trailhead
# or
sudo systemctl restart trailhead
```

- [ ] **Step 5: Verify service started**

```bash
curl -s http://localhost:4050/api/v1/jobs | head -c 100
```

Expected: JSON array of jobs returned.

---

## Task 3: Run Hello-World E2E Test

**Purpose:** Verify end-to-end workflow execution after fixes.

**Files:**
- None (API test only)

- [ ] **Step 1: Create hello-world job**

```bash
export TRAILHEAD_URL="http://localhost:4050"
curl -s -X POST "$TRAILHEAD_URL/api/v1/jobs" \
  -H "content-type: application/json" \
  -d '{
    "project_id": "012f809a-6d05-40b7-bbcd-d92568c2fe72",
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

- [ ] **Step 3: Check worker container**

```bash
docker ps | grep trailhead-worker
```

Expected: Container `trailhead-worker-<job-id>` running during execution.

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
export TRAILHEAD_URL="http://localhost:4050"
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
   cd /home/gem/projects/CoderyTrailhead
   docker build -t opencode-worker:latest -f containers/worker/Dockerfile .
   ```

3. **Network missing:**
   ```bash
   docker network create codery-net
   ```

## Verify E2E

```bash
# Create test job
curl -X POST "http://localhost:4050/api/v1/jobs" \
  -H "content-type: application/json" \
  -d '{"project_id": "...", "description": "test", "workflow": "hello-world"}'

# Monitor status
curl "http://localhost:4050/api/v1/jobs/{id}"
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
