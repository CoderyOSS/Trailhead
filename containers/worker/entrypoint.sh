#!/bin/bash
set -e

echo "trailhead-worker: generating config" >&2

cp /etc/opencode/AGENTS.md /workspace/AGENTS.md

if [ -n "$RESPONSE_SCHEMA" ]; then
    echo "$RESPONSE_SCHEMA" | base64 -d >> /workspace/AGENTS.md
fi

if [ -z "$OPENCODE_CONFIG" ]; then
    echo "trailhead-worker: ERROR: OPENCODE_CONFIG not set" >&2
    exit 1
fi

echo "$OPENCODE_CONFIG" > /workspace/opencode.json
echo "trailhead-worker: wrote opencode.json" >&2

echo "trailhead-worker: starting opencode serve on port 8080" >&2
exec opencode serve --port 8080 --hostname 0.0.0.0
