#!/bin/bash
set -e

echo "trailhead-worker: generating config" >&2

cp /etc/opencode/AGENTS.md /workspace/AGENTS.md

if [ -n "$RESPONSE_SCHEMA" ]; then
    echo "$RESPONSE_SCHEMA" | base64 -d >> /workspace/AGENTS.md
    echo "trailhead-worker: appended response schema" >&2
fi

TEMPLATE="/etc/opencode/opencode.json.tmpl"
OUTPUT="/workspace/opencode.json"

cp "$TEMPLATE" "$OUTPUT"

if [ -n "$LLM_PROVIDER" ]; then
    sed -i "s/\"LLM_PROVIDER\"/\"$LLM_PROVIDER\"/g" "$OUTPUT"
fi

KEY_FILE="/etc/secrets/${LLM_PROVIDER}_api_key"
if [ -f "$KEY_FILE" ]; then
    API_KEY=$(cat "$KEY_FILE" | tr -d '\n')
    sed -i "s/\"LLM_API_KEY\"/\"$API_KEY\"/g" "$OUTPUT"
    echo "trailhead-worker: set api key from $KEY_FILE" >&2
else
    echo "trailhead-worker: warning: no key file at $KEY_FILE" >&2
fi

if [ -n "$LLM_BASE_URL" ]; then
    sed -i "s|\"LLM_BASE_URL\"|\"$LLM_BASE_URL\"|g" "$OUTPUT"
else
    sed -i '/"baseURL"/d' "$OUTPUT"
fi

if [ -n "$TRAILHEAD_URL" ]; then
    sed -i "s|\"TRAILHEAD_URL/mcp/sse\"|\"$TRAILHEAD_URL/mcp/sse\"|g" "$OUTPUT"
fi

echo "trailhead-worker: starting opencode serve on port 8080" >&2

exec opencode serve --port 8080 --hostname 0.0.0.0
