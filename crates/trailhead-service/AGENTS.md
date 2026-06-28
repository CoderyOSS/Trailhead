# Trailhead Backend - Agent Guide

## Purpose

Trailhead is an AI workflow orchestration service. It schedules multi-stage LLM workflows, spawns ephemeral worker instances (one per stage), and manages job lifecycle.

## Architecture

```
trailhead-service (Rust, runs on VPS host)
├── Scheduler  : event-driven job scheduling, spawns workers via WorkerProvider
├── Database   : SQLite (jobs, workflows, workers, checkpoints)
├── MCP Server : exposes tools for IDE integration (port 4050)
├── Web API    : REST endpoints for external control (port 4050)
└── Embedded SPA : Flutter frontend at frontend/, built into binary via build.rs
```

## Worker Lifecycle

**One worker per stage.** Scheduler spawns a fresh worker for each stage
execution (`scheduler.rs:232` `create_worker`), runs the stage prompt via
`run_stage()`, then destroys the worker (`scheduler.rs:586`). The next stage
triggers a new worker on the next scheduling tick.

- Filesystem state persists across stages via the host project bind-mount.
- In-memory state, installed packages, and opencode sessions do NOT carry
  between stages — each stage starts from clean context.
- Stage outputs persisted in `stage_history` column → template variables like
  `{{stages.foo.output}}` resolve in later stages.

## Worker Providers

Pluggable backends implementing the `WorkerProvider` trait in `src/provider/`.
One sandbox/pod/process = one stage execution (per Worker Lifecycle above).

| Provider  | Status         | Module                  | Notes                                                          |
|-----------|----------------|-------------------------|----------------------------------------------------------------|
| Docker    | Active         | `provider/docker.rs`    | Default; bollard; bind-mounts `project_path`                   |
| Daytona   | In development | planned `provider/daytona.rs` | Cloud VM sandboxes via Daytona REST API                   |
| MicroK8s  | In development | planned `provider/microk8s.rs`| Kubernetes pods via kube-rs; MicroK8s is reference distro |
| localhost | In development | planned `provider/local.rs`   | Host child processes; no OS-level sandboxing in Phase 1   |

Selected via `--worker-provider` flag or `trailhead.toml` `worker_provider` key.
Single provider per daemon (not per-job). See root `AGENTS.md` and
`openspec/changes/multi-provider-workers/design.md` for full details.

## Build & Test Commands

| Action | Command |
|--------|---------|
| Check | `cargo check -p trailhead-service` |
| Test | `cargo test -p trailhead-service` |
| Full workspace test | `cargo test --workspace` |
| Clippy | `cargo clippy --workspace -- -D warnings` |

Compilation happens on the **apps container** (which has a C compiler). Run via:
```bash
ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check'
```

## Key Conventions

- **State machine**: Job state transitions defined in `src/jobs.rs` — always use `transition()` for validation
- **Database**: SQLite via rusqlite in `src/db.rs`. Add new columns via `MIGRATIONS` array
- **Workflow engine**: YAML-based state machines in `src/workflow/parser.rs`. Stages are `IndexMap<String, Stage>`
- **Scheduler**: Event-driven via `tokio::sync::watch`. Drives job lifecycle in `src/scheduler.rs`. One worker per stage — destroys worker at end of each stage (`scheduler.rs:586`), spawns new worker for next stage.
- **Routes in web.rs**: API routes (`/api/v1/*`) + fallback serves embedded Flutter SPA at `ui/static/`

## Active Changes

- **multi-provider-workers**: `openspec/changes/multi-provider-workers/` — adds
  Daytona VM, MicroK8s pod, and localhost process providers alongside the existing
  Docker provider. See `design.md` for integration details.

## Frontend

Flutter frontend lives at `frontend/` (separate project, independent version). Web build output is embedded in the Rust binary at compile time via `build.rs` + `rust-embed`.

## Embed Pipeline

1. `flutter build web --release` produces `frontend/build/web/`
2. `build.rs` copies it to `crates/trailhead-service/ui/static/`
3. `rust_embed::Embed` includes `ui/static/` in the binary
4. `web.rs` `serve_spa()` serves embedded assets via axum fallback handler

To build the release binary and print the host deploy commands, run the
repo-root script:

```bash
./scripts/build-trailhead.sh
```

See `frontend/AGENTS.md` and the root `AGENTS.md` for the full deployment
instructions.
