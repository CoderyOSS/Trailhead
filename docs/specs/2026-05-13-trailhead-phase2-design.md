# Trailhead Phase 2: Deployment, Provider Config & Hello World Pipeline

**Date:** 2026-05-13
**Status:** Design approved

## Goal

Get trailhead-service deployed and running a hello world pipeline end-to-end: service receives job → launches agent-runner in Docker container → agent calls LLM (DeepSeek V4 Pro) → returns response.

## Current State

All Phase 1 code written (Tasks 0-26) but has wiring gaps preventing end-to-end execution.

## 1. Deployment

trailhead-service runs on VPS host under supervisord (not containerized).

### Supervisord Config
File: `proxy/supervisor/conf.d/trailhead.conf` in Codery repo.

### CI Workflow
1. Trigger: push to main touching trailhead-service code
2. Build: cargo build --release -p trailhead-service
3. Deploy: SSH to VPS, upload binary, symlink, supervisorctl restart

### VPS File Layout
- /opt/codery/trailhead/bin/current/ → symlink to active binary
- /opt/codery/trailhead/trailhead.db (SQLite)
- /opt/codery/trailhead/trailhead.toml (LLM config)

## 2. LLM Configuration

### Config File (trailhead.toml)

OpenCode-style provider/agent pattern. Provider connections define how to reach an API. Model selection uses provider_id/model_id format. Model metadata in code, not user config.

```toml
model = "deepseek/deepseek-v4-pro"

[provider.deepseek]
api = "openai-compatible"
base_url = "https://api.deepseek.com/v1"
env = ["DEEPSEEK_API_KEY"]

[provider.anthropic]
api = "anthropic"
base_url = "https://api.anthropic.com"
env = ["ANTHROPIC_API_KEY"]
```

### Precedence
1. Workflow YAML stage.model / stage.provider
2. Environment variables LLM_MODEL, LLM_PROVIDER, LLM_API_KEY, LLM_BASE_URL
3. Config file trailhead.toml defaults

### API Key Handling
Config stores env var names in env array. Service reads actual key at runtime.

## 3. OpenAI-Compatible Provider

### Design
Raw HTTP via reqwest + serde. Supports any /v1/chat/completions endpoint.

### DeepSeek reasoning_content
- reasoning_content chunks arrive first in streaming, then content chunks
- Multi-turn with tool calls MUST include reasoning_content (400 error if omitted)
- Safe to always include reasoning_content in serialized messages

### Message Changes
Message struct gains reasoning_content: Option<String>.

## 4. API Wiring

### JobConfigResponse
Includes model, provider, base_url, api_key fields. All values resolved from config + stage overrides.

### job_config Handler
1. Load workflow YAML for job's project
2. Resolve current stage
3. Resolve prompt via minijinja
4. Load skill content
5. Resolve effective model/provider
6. Return stage tools, max_tokens, timeout from workflow (not hardcoded)

### Stage Schema
skill is Optional. Stages can be prompt-only.

### TokenUsage Dedup
Single source in trailhead-core with prompt_tokens/completion_tokens/total_tokens.

## 5. Hello World Pipeline

### Workflow
```yaml
name: hello-world
stages:
  greet:
    prompt: "Say 'Hello from Trailhead!' and nothing else."
    max_tokens: 256
    timeout_secs: 60
```

### E2E Test
1. Create project with hello-world workflow
2. Create job
3. Verify job_config returns resolved stage config
