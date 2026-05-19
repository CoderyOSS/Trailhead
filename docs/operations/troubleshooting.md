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

4. **Wrong image name in configuration (known issue):**
   The scheduler may use an incorrect image reference (`opencode-worker:latest` instead of `ghcr.io/coderyoss/trailhead:worker-latest`).
   
   **Check logs for:**
   ```
   container create opencode-worker:latest
   ```
   
   **Fix:** Update the scheduler configuration to use the correct image name. See commit 4e6fcd3 for the fix.

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
