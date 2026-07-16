> **PROJECT PURPOSE:**
> Production-grade, node-based workflow engine for both developer environments and production server operation at scale. Powered by Elixir for resilience, reliability, scalability, and limitless concurrency. Inspired by Node-RED, but with serious engineering might at its core.
>
> **Use cases:**
> - Visually arrange logic to power anything that runs Elixir: factory automation, web apps, home automation, device orchestration.
> - ---
> - *(AI harness nodes and MCP integration — deferred. See roadmap below.)*

# Trailhead Service - Agent Guide

## Project Layout

```
CoderyTrailhead/
├── AGENTS.md                       ← This file (repo-level orchestration)
├── frontend/                       ← Flutter SPA (web + iOS)
│   ├── AGENTS.md                   ← Frontend-specific instructions
│   └── ...
├── openspec/                       ← OpenSpec change proposals
└── design/                         ← Design prototype (reference only)
```

For frontend work, read `frontend/AGENTS.md`. For the runtime backend, read `/home/gem/projects/THRT/AGENTS.md`.

## Runtime Architecture

The runtime engine is **THRT** (`/home/gem/projects/THRT`), an Elixir service
that stores workflow YAML and executes node graphs. The Flutter frontend at
`trailhead.rancidgrandmas.online` is served by a Bun proxy that forwards
`/api/*` to THRT.

The earlier Rust prototype has been retired entirely. The runtime is
exclusively THRT (Elixir).

## Knowledge Graph (graphify)

Binary at `~/.local/bin/graphify` (run `graphify --help` for the full command
list). The repo ships a committed knowledge graph in `graphify-out/` (graph.json,
graph.html, GRAPH_REPORT.md, manifest.json, .graphify_labels.json). Treat any
codebase question as a graphify query first:

```bash
graphify query "how does X work"           # BFS traversal
graphify path "AuthModule" "Database"      # shortest path between two nodes
graphify explain "SwinTransformer"         # plain-language node explainer
graphify add <url>                          # fetch URL into ./raw, update graph
graphify merge-graphs <g1> <g2>            # union-merge cross-repo graphs
graphify diagnose multigraph               # detect same-endpoint edge collapse
graphify install [--platform P]            # install skill into a platform config
```

A **post-commit hook** (`.git/hooks/post-commit`, not tracked by git) regenerates and re-commits the graph after every code change (`.rs/.dart/.toml/.ts/.yaml/.json/etc.`). Doc/markdown changes do not trigger it — run `/graphify --update` manually for those. The inner `[graphify]` commit uses `--no-verify` and never blocks the original commit.

**Fresh clone setup** (hook is not shared via git):
1. Run `/graphify .` once to build the initial graph
2. Re-create the hook: see `hooks/post-commit` template in repo history (commit `93f7a5f`), or run `graphify hook install` then add the auto-recommit block

## ⚠️ CRITICAL: Design Prototype vs Real Product

| Directory | What it is | Language | Do NOT edit |
|-----------|-----------|----------|-------------|
| `frontend/` | **THE REAL PRODUCT** — Flutter app | Dart | |
| `design/` | **DESIGN PROTOTYPE** — HTML/JS exploration | React/JSX | ✓ |
| `design/export/`, `design/handoff/` | Build outputs of prototype | JSX | ✓ |

When asked to implement UI features, **ALWAYS work in `frontend/`**. The `design/`
files look similar (Canvas, WorkerNode, GraphCanvas) but are **NOT** the source of
truth. They are a reference for design direction only.

## Agent Environment Setup

**Critical:** Trailhead runs in the **apps container**, not on the host machine.
Access via:

- Web UI: `https://trailhead.rancidgrandmas.online/`
- API: `https://trailhead.rancidgrandmas.online/api/v1/*` (proxied to THRT)
- THRT direct: `https://thrt.rancidgrandmas.online/`

THRT is managed as a Launchy app named `thrt` on internal port `8060`. The
`trailhead` Launchy app serves the Flutter build with a Bun proxy to THRT.

## Architecture

```
Trailhead Flutter (apps container, port 8040)
├── Bun static server + /api/* proxy
└── serves build/web

THRT (apps container, port 8060)
├── Store          : YAML persistence in THRT/flows/
├── Engine         : deploy / undeploy flow supervisors
├── Api            : CRUD + runtime HTTP endpoints
└── Nodes          : task, genserver
```

**Deployment modes:**
- **Web (current)**: Flutter SPA → Bun proxy (same-origin) → THRT. No CORS needed.
- **Native iOS (planned)**: Flutter app → THRT directly (like MongoDB Compass → remote DB). Requires CORS on THRT.

## Core Data Model

**Workflow**: Node graph YAML definition
```yaml
name: my-flow
nodes:
  - id: a
    type: task
    config:
      expr: "Map.put(payload, :count, Map.get(payload, :count, 0) + 1)"
edges:
  - from: a
    to: b
```

**Flow runtime**: A deployed workflow becomes a supervised tree of per-node
`THRT.Node.Server` processes. Messages are routed along edges.

*(Job/Worker lifecycle re-implementation on THRT planned — see roadmap.)*

## Worker Providers

> **Planned module.** Work containers (Docker, Daytona VMs, MicroK8s pods,
> localhost processes) for isolated stage execution. Not yet implemented in THRT.
> Design reference: `openspec/changes/multi-provider-workers/design.md`.

## Feature Status

### Implemented (✅)
- Workflow CRUD via REST API
- THRT YAML parser + node graph execution
- Workflow YAML storage in THRT

### Planned (🚧)
- Job/worker lifecycle re-implementation on THRT
- Human-in-the-loop approvals between stages
- Real SSE event streaming
- Token usage tracking
- Native iOS client with direct THRT connection

## API Endpoints

```
GET    /api/v1/workflows                 - list workflows
POST   /api/v1/workflows                 - create workflow {name, content}
GET    /api/v1/workflows/{name}          - get workflow content + metadata
PUT    /api/v1/workflows/{name}          - replace workflow content {content}
DELETE /api/v1/workflows/{name}          - delete workflow
POST   /api/v1/workflows/{name}/deploy   - deploy flow to runtime
DELETE /api/v1/workflows/{name}/deploy   - undeploy flow
GET    /api/v1/workflows/{name}/status   - runtime node status
POST   /api/v1/workflows/{name}/trigger  - inject message {node_id, payload}
```

## MCP Integration

Deferred. See roadmap.

## Configuration

**THRT Environment:**
- `PORT`: HTTP port (default `4000`; Launchy sets `8060`)
- `FLOWS_DIR`: directory for persisted workflow YAML (default `./flows`)
- `HOME`: must be `/home/gem/projects` so the Erlang cookie is found

## Active Changes

*None currently.*

## Recently Landed

- **THRT runtime + same-origin proxy (2026-07-15)**: Active runtime is
  THRT (`/home/gem/projects/THRT`). Frontend served by Bun proxy at
  `trailhead.rancidgrandmas.online`, forwarding `/api/*` to THRT on
  `localhost:8060`. Added Deploy button, Inject dialog, and node
  status badges.

## Deployment

THRT and the Flutter frontend both run inside the **apps container** as Launchy
apps. They are not managed by the host supervisor.

| App | Subdomain | Internal Port | Directory | Command |
|-----|-----------|---------------|-----------|---------|
| `thrt` | `thrt.rancidgrandmas.online` | 8060 | `/home/gem/projects/THRT` | `elixir --sname thrt -S mix run --no-halt` |
| `trailhead` | `trailhead.rancidgrandmas.online` | 8040 | `/home/gem/projects/CoderyTrailhead/frontend` | `bun run serve.js` |

To pick up code changes:

1. `cd /home/gem/projects/THRT && mix compile`
2. Restart the `thrt` Launchy app (`remove_app` + `add_app`).
3. `cd /home/gem/projects/CoderyTrailhead/frontend && ~/projects/flutter/bin/flutter build web --release`
4. Restart the `trailhead` Launchy app.

## Store Schema

THRT persists workflows as individual YAML files in `THRT/flows/` (configured by
`FLOWS_DIR`). Each file is named `{name}.yaml`.

Metadata returned by the CRUD API:
- `name`: workflow name
- `content`: raw YAML string
- `content_hash`: SHA-256 hash of content (for change detection)
- `updated_at`: file mtime in ISO-8601 UTC

Runtime counters are stored in an in-memory ETS table (`:thrt_stats`) keyed by
`{flow_id, node_id}`.

## Common Tasks

**Deploy a workflow and inject a test message:**
```bash
# create
bash -c 'cat <<EOF > /tmp/flow.json
{"name":"hello-world","content":"name: hello-world\nnodes:\n  - id: a\n    type: task\n    config:\n      expr: \"Map.put(payload, :greeted, true)\"\nedges: []\n"}'
curl -s -X POST https://trailhead.rancidgrandmas.online/api/v1/workflows \
  -H "Content-Type: application/json" -d @/tmp/flow.json

# deploy
curl -s -X POST https://trailhead.rancidgrandmas.online/api/v1/workflows/hello-world/deploy

# status
curl -s https://trailhead.rancidgrandmas.online/api/v1/workflows/hello-world/status

# inject
curl -s -X POST https://trailhead.rancidgrandmas.online/api/v1/workflows/hello-world/trigger \
  -H "Content-Type: application/json" -d '{"node_id":"a","payload":{"hello":"world"}}'
```

**Import workflows from disk (one-time bootstrap or batch load):**
```bash
# THRT.Store expects one YAML file per workflow in FLOWS_DIR.
cp /path/to/yaml/dir/*.yml /home/gem/projects/THRT/flows/
```

## Testing

**E2E test approach:**
1. Author or load a workflow via the Flutter UI or API.
2. Click **Deploy** in the top bar (or `POST .../deploy`).
3. Right-click a source node and choose **Inject** (or `POST .../trigger`).
4. Watch the node status badge update (`in:N out:M`).
5. Tail THRT logs at `/var/log/launchy/thrt.log` inside the apps container.

**Unit tests:**
```bash
cd /home/gem/projects/THRT
mix test --no-start
```

**Known gap:** No automated frontend widget/E2E tests yet. Manual testing via UI + `curl`.

## Known Issues

1. **Running flows do not survive THRT restart** — deployments are in-memory. After restart, reload/redeploy YAML definitions.
2. **Client deployment modes** — Two connection models with different CORS requirements:
   - **Web (current)**: Flutter SPA served by Bun proxy → THRT same-origin. No CORS needed. Simplest deployment.
   - **Native iOS (planned)**: App connects directly to THRT like a database client (e.g. MongoDB Compass → remote server). Requires CORS support on THRT. Not yet implemented.

3. **App container restarts wipe installed Flutter SDK** — install Flutter to `/home/gem/projects/flutter` (bind-mounted) instead of `/home/gem/flutter`.

## File Layout

```
CoderyTrailhead/
├── frontend/                     ← Flutter app
│   ├── lib/
│   │   ├── services/
│   │   │   ├── workflows_api.dart
│   │   │   └── thrt_api.dart
│   │   ├── providers/
│   │   │   └── thrt_provider.dart
│   │   └── widgets/canvas/
│   │       └── graph_canvas.dart
│   └── serve.js                  ← Bun proxy to THRT
└── openspec/                     ← design proposals

/home/gem/projects/THRT/          ← active Elixir runtime
├── lib/thrt/
│   ├── api.ex
│   ├── engine.ex
│   ├── store.ex
│   ├── yaml.ex
│   └── nodes/
│       ├── task.ex
│       └── genserver.ex
└── flows/                        ← persisted YAML
```

## For Agents Working on This Code

1. **Frontend changes** go in `frontend/`; never edit `design/` prototype files.
2. **Runtime changes** go in `/home/gem/projects/THRT/`.
3. **New node types**: implement the `THRT.Node` behaviour and register in `THRT.Engine`.
4. **YAML schema changes**: update `THRT.Yaml` + add tests.
5. **Always test THRT with `mix test --no-start`**.
6. **After frontend changes**, run `~/projects/flutter/bin/flutter build web --release` and restart the `trailhead` Launchy app.
