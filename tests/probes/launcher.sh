#!/usr/bin/env bash
set -euo pipefail

BINARY="/home/gem/projects/CoderyTrailhead/target/release/trailhead-service"
SQL_PORT=4051
CONFIG_PATH="/tmp/trailhead-e2e-config.toml"
PORT=4050

cat > "$CONFIG_PATH" <<'TOMEOF'
model = "deepseek/deepseek-chat"

[provider.deepseek]
api = "openai-compatible"
base_url = "https://api.deepseek.com/v1"
env = ["DEEPSEEK_API_KEY"]
TOMEOF

pkill -f 'trailhead-service daemon' 2>/dev/null || true
sleep 0.3

export DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY:-}"
export MAX_GLOBAL_WORKERS=0
export SCHEDULER_INTERVAL_SECS=3600

nohup "$BINARY" daemon --port "$PORT" --db "http://localhost:$SQL_PORT" --config "$CONFIG_PATH" > /tmp/trailhead-test.log 2>&1 &

sleep 1

for i in $(seq 1 20); do
    if curl -s -o /dev/null -w '%{http_code}' "http://localhost:$PORT/api/v1/jobs" 2>/dev/null | grep -q "200"; then
        echo "trailhead-service ready on :$PORT"
        exit 0
    fi
    sleep 0.5
done

echo "ERROR: trailhead-service failed to start" >&2
cat /tmp/trailhead-test.log 2>/dev/null || true
exit 1
