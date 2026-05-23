# Trailhead Backend - Agent Guide

## Purpose

Trailhead is an AI workflow orchestration service. It schedules multi-stage LLM workflows, spawns ephemeral Docker worker containers, and manages job lifecycle.

## Architecture

```
trailhead-service (Rust, runs on VPS host)
├── Scheduler  : event-driven job scheduling, spawns workers via Docker
├── Database   : SQLite (jobs, workflows, workers, checkpoints)
├── MCP Server : exposes tools for IDE integration (port 4050)
├── Web API    : REST endpoints for external control (port 4050)
└── Embedded SPA : Flutter frontend at frontend/, built into binary via build.rs
```

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
- **Scheduler**: Event-driven via `tokio::sync::watch`. Drives job lifecycle in `src/scheduler.rs`
- **Routes in web.rs**: API routes (`/api/v1/*`) + fallback serves embedded Flutter SPA at `ui/dist/`

## Frontend

Flutter frontend lives at `frontend/` (separate project, independent version). Web build output is embedded in the Rust binary at compile time via `build.rs` + `rust-embed`.

## Embed Pipeline

1. `flutter build web --release` produces `frontend/build/web/`
2. `build.rs` copies it to `crates/trailhead-service/ui/dist/`
3. `rust_embed::Embed` includes `ui/dist/` in the binary
4. `web.rs` `serve_spa()` serves embedded assets via axum fallback handler

See `frontend/AGENTS.md` for frontend-specific instructions.
