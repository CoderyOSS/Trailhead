# Trailhead AGENTS.md

## Build & Test Environment

**Rust compilation happens in the apps container.** Sandbox lacks cargo registry write permissions.

```bash
ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check 2>&1'
```

Prefix all cargo commands with the ssh wrapper above.

E2E probe tests run from sandbox directly: `cd tests/probes && bun test`

## Commands

| Action | Command |
|--------|---------|
| Check workspace | `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo check 2>&1'` |
| Check one crate | same but `cargo check -p trailhead-service 2>&1` |
| Build | `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo build 2>&1'` |
| Clippy | `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo clippy 2>&1'` |
| Unit tests | `ssh gem@apps 'export PATH="$HOME/.cargo/bin:$PATH" && cd /home/gem/projects/CoderyTrailhead && cargo test 2>&1'` |
| Tests one crate | same but `cargo test -p trailhead-service 2>&1` |
| E2E probes | `cd tests/probes && bun test` |

## Project Structure

Cargo workspace with single crate (`trailhead-service`). Worker containers run `opencode serve` — no custom agent-runner binary.

```
~/projects/CoderyTrailhead/
├── Cargo.toml                          # Workspace root
├── crates/
│   └── trailhead-service/              # Runs on VPS host
│       ├── Cargo.toml
│       ├── src/
│       │   ├── main.rs                 # CLI: daemon, jobs, workers, projects
│       │   ├── db.rs                   # SQLite schema + queries
│       │   ├── jobs.rs                 # Job state machine
│       │   ├── scheduler.rs            # Round-robin scheduling loop
│       │   ├── workers.rs              # Worker lifecycle
│       │   ├── worker/                 # Worker container management (opencode-based)
│       │   ├── workflow/               # Parser, resolver (minijinja), router (CEL)
│       │   ├── provider/               # WorkerProvider trait + Docker impl
│       │   ├── ide/                    # IDE adapters (opencode, cursor, vscode, shell, ssh)
│       │   ├── mcp.rs                  # MCP server (rmcp)
│       │   ├── web.rs                  # Dashboard API (axum)
│       │   └── api.rs                  # Worker-facing HTTP API
│       ├── skills/                     # Built-in skill markdown files
│       │   ├── plan.md
│       │   ├── plan_detail.md
│       │   ├── implement.md
│       │   ├── test.md
│       │   ├── fix.md
│       │   ├── review.md
│       │   ├── create_pr.md
│       │   └── pause.md
│       ├── workflows/                  # Built-in workflow YAML files
│       │   ├── feature.yaml
│       │   ├── quick-fix.yaml
│       │   ├── exploration.yaml
│       │   └── refactor.yaml
│       └── ui/                         # Dashboard frontend (Vite + React)
│           ├── index.html
│           ├── package.json
│           ├── vite.config.ts
│           └── src/
│               ├── main.tsx
│               ├── App.tsx
│               ├── JobList.tsx
│               ├── WorkerList.tsx
│               └── types.ts
├── containers/
│   └── worker/                         # Dockerfile for opencode-based worker containers
├── tests/
│   └── probes/                         # E2E test suite (CoderyProbes)
├── docs/
│   └── specs/                          # Design + implementation plan
└── .github/workflows/                  # CI/CD
```

### Build Separation

| Crate | Binary | Runs Where | Build Target |
|-------|--------|------------|-------------|
| `trailhead-service` | `trailhead-service` | VPS host | Full binary with all features |

Worker containers use pre-built `opencode` binary — no Rust compilation needed for workers.

## Key Configuration

### Scheduler (env vars)

| Variable | Default | Purpose |
|----------|---------|---------|
| `MAX_GLOBAL_WORKERS` | 3 | Max concurrent workers across all projects |
| `MAX_WORKERS_PER_PROJECT` | 1 | Max concurrent workers per project |
| `HEARTBEAT_TIMEOUT_SECS` | 180 | Mark worker failed after no heartbeat |
| `JOB_TIMEOUT_SECS` | 3600 | Max total job duration |
| `MAX_RETRIES` | 3 | Retry limit before `failed_final` |
| `SCHEDULER_INTERVAL_SECS` | 30 | Scheduler tick interval |

### Execution Boundaries

| Boundary | Default | Scope |
|----------|---------|-------|
| Max tool calls per stage | 200 | Per-stage in workflow |
| Max tokens per stage | 8096 | Per-stage in workflow |
| Stage timeout | 600s | Per-stage in workflow |
| Bash timeout | 120s | Global config |
| Max files changed before checkpoint | 20 | Global config |

### Database

SQLite WAL mode at `/opt/codery/trailhead.db`.

## Code Style

### Rust
- NEVER use `unwrap()` outside tests. Use `?`, `map_err`, or explicit error handling.
- NEVER add comments unless asked.
- Follow existing patterns in neighboring files for imports, error types, module organization.

### TypeScript (E2E tests)
- NEVER use type assertions (`as X`, `<X>`). Use type guards or discriminated unions.
- NEVER use `any`. Use `unknown` and narrow explicitly.
- NEVER add comments unless asked.

### All languages
- NEVER add emoji unless explicitly asked.
- Follow conventions of neighboring files.
- Read surrounding context before writing code in a file.

## E2E Testing with CoderyProbes

CoderyProbes (`~/projects/CoderyProbes`) is the E2E testing framework. It provides HTTP, SQL, filesystem, TCP, and WebSocket probes for testing real system behavior.

### Test-Driven Workflow

1. **Write failing tests first** — define expected behavior before implementation
2. **Run tests during implementation** — verify work against the failing tests
3. **Tests pass when implementation complete**

### Test Suite Organization

Tests live in `tests/probes/`. Organize by component and feature:

```
tests/probes/
├── probes.yml                     # CoderyProbes config (interfaces, launcher)
├── adapter.ts                     # Wire protocol adapter for trailhead-service
├── helpers.ts                     # Test utilities, proof recording
├── fixtures/                      # Shared test data (seed SQL, YAML configs)
├── workflow/                      # Tests for workflow engine
│   ├── parser.test.ts             # YAML parsing + validation
│   ├── resolver.test.ts           # Template variable resolution
│   ├── router.test.ts             # CEL expression routing
│   └── engine.test.ts             # Full workflow execution
├── service/                       # Tests for trailhead-service
│   ├── api.test.ts                # Worker HTTP API endpoints
│   ├── jobs.test.ts               # Job lifecycle / state machine
│   ├── scheduler.test.ts          # Scheduling behavior
│   ├── db.test.ts                 # Database operations
│   └── web.test.ts                # Dashboard API
└── integration/                   # Cross-component E2E
    └── full-job.test.ts           # Complete job: create → schedule → run → complete
```

### Naming Conventions

- One test file per component/feature
- File name = component being tested: `tools.test.ts`, `parser.test.ts`
- Directory groups related tests: `workflow/`, `service/`
- Fixtures in `fixtures/` — shared seed data, config files

### CoderyProbes Usage

CoderyProbes is symlinked into `tests/probes/node_modules/@codery/probes`.

**Framework changes go in `~/projects/CoderyProbes`, not in test files.** If an E2E test needs a new capability, implement it in CoderyProbes and commit there. No reinstall needed — symlink picks up changes.

After editing CoderyProbes source, run `cd tests/probes && bun test` to verify.

#### Exports — Which to Use

| Export | When | Auto-init | Auto-save proof records |
|--------|------|-----------|------------------------|
| `p` | Test suites (default) | Yes (top-level await, walks CWD for probes.yml) | Yes (exit + beforeExit hooks + bunfig preload) |
| `probes()` | Standalone scripts only | No | **No — must call `.proof.save()` manually** |
| `probesSession()` | Manual config init | No | Yes (exit + beforeExit hooks) |
| `group()` | Shared instance pool | No | No |

**ALWAYS use `p` in test files.** Import from `"@codery/probes"` directly:

```ts
import { p } from "@codery/probes";
```

**NEVER use `probes()` factory in test files.** It creates isolated instances without auto-save. Proof records (`proof-records.md`) will NOT be generated.

#### Proof Records

Proof records are written to `tests/probes/proof-records.md`. They contain timestamped event logs of all probe interactions, grouped by test section.

`bun test` does NOT fire `process.on("exit")`. Proof saving uses three mechanisms:
1. `process.on("beforeExit")` — fires when bun's event loop drains
2. `bunfig.toml` preload (`setup.ts`) — registers `afterAll(() => p.proof.save())` per test file
3. `process.on("exit")` — works under `bun run` but not `bun test`

#### Preload Setup

`tests/probes/bunfig.toml` preloads `setup.ts` before each test file. This ensures proof records are saved after each file's tests complete. Do not remove these files.

### Running E2E Tests

```bash
cd tests/probes && bun test                    # all tests
cd tests/probes && bun test workflow/          # workflow tests only
cd tests/probes && bun test service/api.test.ts  # single file
```

## Design Docs

- `docs/specs/2026-05-12-trailhead-phase1-design.md` — full architecture spec
- `docs/specs/2026-05-12-trailhead-implementation-plan.md` — task-by-task plan with code
