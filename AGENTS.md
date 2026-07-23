> **PROJECT PURPOSE:**
> Production-grade, node-based workflow engine for both developer environments and production server operation at scale. Powered by Elixir for resilience, reliability, scalability, and limitless concurrency. Inspired by Node-RED, but with serious engineering might at its core.
>
> **Use cases:**
> - Visually arrange logic to power anything that runs Elixir: factory automation, web apps, home automation, device orchestration.
> - ---
> - *(AI harness nodes and MCP integration — deferred. See roadmap below.)*

# Carta Service - Agent Guide

> **Naming:** "Carta" is the canonical project name. "Trailhead" and "THRT"
> are legacy references from the original prototype. All new code, configs,
> and documentation must use "Carta". Old references may persist in
> `design/` (do-not-edit prototype) and history; update them when found
> outside those scopes.

## Project Layout

```
CartaClient/
├── AGENTS.md                       ← This file (repo-level orchestration)
├── frontend/                       ← Flutter SPA (web + iOS)
│   ├── AGENTS.md                   ← Frontend-specific instructions
│   └── ...
├── openspec/                       ← OpenSpec change proposals
└── design/                         ← Design prototype (reference only)
```

For frontend work, read `frontend/AGENTS.md`. For the runtime backend, read `/home/gem/projects/Carta/AGENTS.md`.

## Runtime Architecture

The runtime engine is **Carta** (`/home/gem/projects/Carta`), an Elixir service
that stores workflow YAML and executes node graphs. The Flutter frontend at
`carta.rancidgrandmas.online` is served by a Bun proxy that forwards
`/api/*` to Carta.

The earlier Rust prototype has been retired entirely. The runtime is
exclusively Carta (Elixir).

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

**Critical:** Carta runs in the **apps container**, not on the host machine.
Access via:

- Web UI: `https://carta.rancidgrandmas.online/`
- API: `https://carta.rancidgrandmas.online/api/v1/*` (proxied to Carta)
- Carta direct: `https://carta.rancidgrandmas.online/`

Carta is managed as a Launchy app named `cbe1` on internal port `8060`. The
`cartaclient` Launchy app serves the Flutter build with a Bun proxy to Carta.

## Architecture

```
Carta Flutter (apps container, port 8040)
├── Bun static server + /api/* proxy
└── serves build/web

Carta (apps container, port 8060)
├── Store          : YAML persistence in Carta/flows/
├── Engine         : deploy / undeploy flow supervisors
├── Api            : CRUD + runtime HTTP endpoints
└── Nodes          : task, genserver
```

**Deployment modes:**
- **Web (current)**: Flutter SPA → Bun proxy (same-origin) → Carta. No CORS needed.
- **Native iOS (planned)**: Flutter app → Carta directly (like MongoDB Compass → remote DB). Requires CORS on Carta.

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
`Carta.Node.Server` processes. Messages are routed along edges.

*(Job/Worker lifecycle re-implementation on Carta planned — see roadmap.)*

## Worker Providers

> **Planned module.** Work containers (Docker, Daytona VMs, MicroK8s pods,
> localhost processes) for isolated stage execution. Not yet implemented in Carta.
> Design reference: `openspec/changes/multi-provider-workers/design.md`.

## Feature Status

### Implemented (✅)
- Workflow CRUD via REST API
- Carta YAML parser + node graph execution
- Workflow YAML storage in Carta

### Planned (🚧)
- Job/worker lifecycle re-implementation on Carta
- Human-in-the-loop approvals between stages
- Real SSE event streaming
- Token usage tracking
- Native iOS client with direct Carta connection

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
POST   /api/v1/workflows/{name}/inject   - inject payload {node_id, code, kind?} — kind:"expr" evaluates; default parses literal
PATCH  /api/v1/workflows/{name}/log-flags - hot-toggle {node_id, log_in?, log_out?}
GET    /api/v1/workflows/{name}/logs/stream - WebSocket log stream (per-flow)
POST   /api/v1/validate/elixir-term      - validate source {code, kind?} → {ok, error?, line?} — kind:"expr" is syntax-only
POST   /api/v1/jobs                      - launch flow as job {flow_name, description?} → job incl. YAML snapshot {content}
GET    /api/v1/jobs                      - list jobs (each with content snapshot)
GET    /api/v1/jobs/{id}                 - get job
POST   /api/v1/jobs/{id}/cancel          - undeploy flow, mark job cancelled
DELETE /api/v1/jobs/{id}                 - alias of cancel
GET    /api/v1/configs                  - list config objects (current project; no project param)
POST   /api/v1/configs                  - create {key, source} → 201 / 409 key_exists / 400 bad literal
GET    /api/v1/configs/{key}            - get {key, source, updated_at} / 404
PUT    /api/v1/configs/{key}            - replace {source} → 200 / 404 / 400
DELETE /api/v1/configs/{key}            - delete → 204 / 404
```

## MCP Integration

Deferred. See roadmap.

## Configuration

**Carta Environment:**
- `PORT`: HTTP port (default `4000`; Launchy sets `8060`)
- `FLOWS_DIR`: directory for persisted workflow YAML (default `./flows`)
- `HOME`: must be `/home/gem/projects` so the Erlang cookie is found

## Active Changes

*None currently.*

## Recently Landed

- **Unified resizable drawer + mock executions removed (2026-07-23)**: Node
  details drawer (now "settings drawer") and logs drawer merged into a single
  `UnifiedDrawer` (`lib/widgets/drawer_panel.dart`) in BOTH build and active
  mode — logs are now a view option while editing, not just in active jobs.
  Header: 3-state view switch (logs|settings|both, last-used persisted
  globally) + split-direction toggle (horizontal/vertical panes) + close
  (build only; active stays forced open). Resizable via slim drag handles
  (touch/trackpad/mouse): outer edge (drawer↔graph — width in landscape,
  height in portrait) and inner (logs↔settings split). Sizes/split/layout/
  view-mode persist via `shared_preferences` (new dep; `drawer_provider.dart`,
  keys `drawer.*`); open state is session-only. Landscape = consistent width
  (default 520, clamped [360, 80%]); portrait = consistent height (default
  320, clamped [240, 70%]) replacing the old 50/50 split. Selection no longer
  gates drawer visibility — no selection → settings pane shows an empty state
  under the (selection-independent) tab bar; TopBar gains a "panel" toggle
  (build mode) so logs are reachable without a selection; node double-tap
  still opens the drawer and bumps a logs-only view to both. The mock
  EXECUTIONS section in the job tab (fed by `mockStageExecutions`) is
  deleted — job tab keeps genserver header info + the inject trigger;
  `StageExecution`/`ToolCall` model classes went with it. History mode
  untouched. `nodeDrawerOpenProvider` renamed to `drawerOpenProvider`
  (call sites: main, mode_rail, flow_tabs_provider, graph_canvas,
  yaml_drawer). `flutter analyze` 0 errors; `flutter test` 94 green.
- **Configuration objects (2026-07-23)**: Project-scoped named Elixir literals
  stored via `Carta.FileStore` (YAML files in `configs/`, sibling of `flows/`) —
  `Carta.ConfigStore` is a **stateless module** (not Mnesia/GenServer; cluster
  replication of FileStore deferred to a separate effort). Editable in Settings
  → Configuration Objects. Opt-in per node via `config.config_key`; node
  startup (`Carta.Node.Server.resolve_config/1`) deep-merges the stored term
  over the node's inline `config:` (stored wins, maps recurse, atom-keyed
  stored stringified to match YAML's string keys). Deploy-time validation
  rejects unknown keys with `{:config_key_not_found, node_id, key}` (runs for
  ALL node kinds, gates validate/deploy/job-launch). 5 REST endpoints under
  `/api/v1/configs` — **no `project` param** (current project is implicit,
  like subflows). Frontend: `ConfigsApi`/`configsProvider` mirror the subflows
  client/provider; `WorkflowNode.configKey` + `config.config_key` YAML
  round-trip (universal — a config-only node emits a `config:` block); drawer
  field in `editor_settings_tab.dart`. ConfigsSection cards expand to a
  PayloadEditor; save coalesces (buffer+drain) and keeps the editor mounted
  across collapse/re-expand so typed text isn't lost.

- **`logging_enabled` removed + http client request/response logging (2026-07-22)**:
  Root cause of "http node logs the same thing for in and out": actor graph
  entries are `Runtime.identity` no-ops, so `Engine.exec` logged the same
  envelope at `:in` and `:out` for every actor — and `http.client.request`
  was fire-and-forget (`_ = do_request(...)`, response dropped). Fixes,
  Carta: actor `handle_message` gains a `{:halt, state}` return (message
  fully handled, engine does NOT auto-continue; the node emits later via
  `Node.Server.emit/3`). Actor in-instrumentation (bump_in + `:in` frame)
  moved from `Engine.exec` into `Node.Server.handle_info` (engine skips
  identity entries) — halted actors count in correctly, emit-driven execs
  don't double-count. `http.client.request` rewritten: reads the request
  spec from `env.payload["request"]` (or `:request`; url/method/body/
  headers, string or atom keys; config url/method as fallback), fires the
  request in a `Task`, returns `{:halt, state}`, and emits
  `%{response: %{status:, headers:, body:}}` downstream when the response
  lands — log_in = `%{request:...}`, log_out = `%{response:...}`, original
  payload NOT forwarded. Failures route `%{response: %{status: nil,
  error: msg}}` downstream plus an unconditional `:error` frame
  (`kind: :http_error`). Log frames now stamp `ts` in wall-clock
  **microseconds** (was ms) — fine-grained primary ordering; `seq` remains
  the exact tie-breaker. `logging_enabled` removed completely (it was
  already inert — `LogFlags` checks `log_in`/`log_out` per message on the
  hot path): gone from the frontend model/YAML round-trip, the settings
  tab (log_in/log_out toggles now always visible, both modes), the log
  drawer gates, `flows/test1.yaml`, and test YAML. The stale "function
  hooks compile at deploy — redeploy to apply" hint is gone too (flags are
  runtime-only for ALL node kinds). Frontend bonus fix: `LogStreamView`
  read `workflowProvider` (wrong buffer in Active job mode) — now
  `canvasWorkflowProvider`. `mix test` 346 green (new: halt semantics,
  async emit delivery, request e2e with a local Bandit server, failure
  routing); `flutter test` 77 green.
- **Crash visibility + ghost stats + task validation (2026-07-20)**: Root cause
  of "logging broken / no in's or out's on trigger": a user expr that raises
  (e.g. `Kernel.put_in(payload, [:payload, :meta], 1)` on `%{}`) crashed the
  node's route_fn → GenServer stopped → supervisor restarted it →
  `Stats.init_node` re-**inserted** `{0,0}`, wiping counters every crash —
  status polls showed 0/0 forever and the crash was only in Carta stdout.
  Fixes, Carta: `Stats.init_node` uses `:ets.insert_new` (counters survive
  node restarts; crash asymmetry in:1 out:0 now visible). `Engine.undeploy`
  now calls `Stats.clear_flow/1` (previously only LogFlags) — `/status` no
  longer shows ghost nodes from dead deployments. `Node.Server` emits
  `:error` log frames over `LogBus` on route crashes AND node-callback
  crashes (`%{error, kind: :route_crash | :node_crash, payload}`); LogBus
  `emit/4` accepts `:error`. `Engine.validate_node_configs` gains a Task
  clause (missing/bad/non-string `expr` fails fast — an expr-less task node
  previously crashed the supervisor with a raw
  `{:shutdown, {:failed_to_start_child, ...}}` tuple; the frontend has no
  task expr editor, so GUI-built task nodes always crashed). `api.ex`
  `humanize_reason` unwraps `:shutdown`/`:failed_to_start_child`/
  `:config_error` tuples → readable strings (`:missing_expr` message now
  "task/function node requires config.expr"). Frontend: log stream view
  passes `dir == 'error'` frames unconditionally (no toggle required) and
  styles them `AppColors.danger`. Verified E2E: `mix test` 279 green; inject
  on crashing flow → counters in:2 out:0 persist; error frame received over
  `wss://carta.../logs/stream` through Caddy+Nginx+Bun bridge.
  Infra note: `/var/log/launchy/` in the apps container is EMPTY — Launchy
  pipes app stdout to the container's own stdout (see container logs), the
  documented `carta.log` path does not exist.
- **Config validation + log ordering + editor fixes (2026-07-20)**: Root cause
  of the "job reload badmap" report was the frontend emitting **duplicate
  `config:` blocks** on transform nodes (expr + logging flags each wrote
  their own) — YAML keeps only the last, silently dropping `expr`, so the
  function node died in init with `:missing_expr`. Fixes, Carta:
  `Engine.prepare` gains `validate_node_configs` — function nodes require a
  syntactically valid `config.expr`, inject nodes require exactly one
  parseable `payload_code` XOR `payload_expr` (`payload_expr` syntax-only at
  validate; eval stays deploy-time). Deploy/validate/job-launch all fail
  fast with `{node_id, reason}`. Job-create errors humanized (readable
  strings, no raw tuples); `format_compile_errors` shares the humanizer.
  Actor `log_out` now emits **before** `route_fn` runs (downstream frames no
  longer precede the injector's out frame — causal inversion fixed);
  `LogBus` events carry monotonic `seq`, forwarded over the WS and used by
  the frontend as same-ms tie-breaker. `links_test` seed flake fixed
  (compiles its own `FakeGlobalActor` beam instead of relying on in-memory
  leakage from another test). Frontend: `workflowToYaml` emits a **single
  config block** with `expr: |` block scalar (also fixes quote escaping);
  `trigger-test` workflow repaired server-side. Transform expr field is now
  a `PayloadEditor` (`isExpr: true`, keyed by node id — unkeyed editors kept
  the previous node's text; same fix applied to `EditorPayloadTab`). Node
  catalog gains `Kernel.put_in/3`, `update_in/3`, `get_in/2` + a generic
  "transform" entry. Log toggles show a "redeploy to apply" hint on deployed
  flows for function-kind nodes (hooks compile at deploy; actor toggles
  still hot-apply). Launch button gates on server-side validation (blocks
  with error list, no PUT). `jobs_api` parses `{"errors":[...]}` bodies into
  readable messages. Node/edge ids are short base36 (`n_x4k9q2`,
  collision-checked). Log drawer header has a clear button; literal-mode
  validation failures hint at expression mode.
- **Deploy-time `payload_expr` + nil-config crash fix (2026-07-19)**: Bare
  `config:` in flow YAML (emitted by the frontend for empty config maps)
  parsed as nil and crashed deploys with `BadMapError` in node init —
  job launch/reload failed with a raw supervisor shutdown tuple. Fixes:
  Carta `Yaml.parse_node` normalizes non-map config to `%{}`; frontend
  `workflowToYaml` only emits `config:` when ≥1 child entry exists. Feature:
  `source.inject` gains `payload_expr` — arbitrary Elixir (e.g.
  `Map.merge/2`) evaluated ONCE at deploy via new `Carta.Expr`; static result
  fires every time (dynamic per-fire values deferred). Mutually exclusive
  with `payload_code` (`:ambiguous_payload`). Inject + validate endpoints
  accept `kind: "expr"` (inject: eval per trigger click; validate:
  syntax-only). Frontend: payload drawer literal/expression toggle
  (`payloadIsExpr` on WorkflowNode), YAML round-trip via `payload_expr`,
  validation pip + trigger paths send `kind`. Note: Carta tests must run
  with `mix test` (app booted) — deploy-touching tests fail under
  `--no-start` (pre-existing Registry startup assumption).
- **Job-scoped workflow snapshots in Active mode (2026-07-19)**: Fixes payload
  edits in Active mode never persisting (root cause: `_ActiveInjectSection`
  buffer was runtime-only, so job restarts redeployed stale disk YAML).
  Carta `Job.Manager` now stores the launched YAML in the job row and exposes
  it as `content` on all `/api/v1/jobs/*` responses. Frontend: launching or
  selecting a job parses that YAML into `jobDocumentsProvider` (keyed by job
  id) — an independent copy. Canvas + drawer bind to the derived
  `canvasWorkflowProvider` (job doc in Active mode, `workflowProvider`
  otherwise); all mutations route through `updateCanvasWorkflow` /
  `updateCanvasNode` (mode_provider.dart), so job edits bypass autosave and
  never touch the stored workflow. Node repositioning is enabled in Active
  mode (job-local). Node drawer gains tab parity in job view: a runtime
  `job` tab (default, old JobLogView) plus the builder's
  node/payload/prompt/result tabs bound to the job doc. JobBar `reload`
  button = kill + re-sync + relaunch (cancel → create → fresh snapshot from
  `newJob.content`), discarding job-local edits. Inject buffer keys are
  job-scoped (`injectBufferKey` in carta_provider.dart).
- **Inject trigger cap on canvas nodes (2026-07-19)**: `source.inject` nodes
  get a trigger button in Active mode when the flow is deployed — the left
  colorized cap gains a pulsing accent glow (same animation as the active
  chip's status dot) and click cursor. Taps are routed in the canvas's node
  `GestureDetector.onTapUp` via `localPosition.dx <= 30` because a nested
  detector on the cap loses the gesture arena to the parent node detector.
  In-flight inject shows a spinner in the cap. Icons: `source.inject` → play
  triangle, `delay` → stopwatch (canvas + node picker). Canvas now also polls
  the current workflow's Carta status every 1s while in Active mode
  (`_pollActiveFlow`), independent of the (unimplemented) jobs backend — this
  is what populates `flowStatusProvider` for badges, the drawer trigger and
  the cap. Shared `triggerNodeInject(WidgetRef, ...)` helper in
  `carta_provider.dart` (drawer + canvas).
- **Namespaced module system + multi-project Carta (2026-07-19)**: Linked
  packages register node types only as `mod.<package>.<type>` (bare linked
  types hard-fail). Package manifests (`carta_package.yaml`) require `name` +
  `version`. Carta registry: `~/.carta/projects.yaml` (project dirs),
  `~/.carta/packages/<pkg>/` (global implicit links). Flow YAML gains
  `project:` binding a workflow to a project dir; `mod.*` types resolve only
  against that project's links + global packages. New endpoints:
  `POST /api/v1/workflows/validate`, `GET /api/v1/projects`. Frontend:
  TopBar project picker, deploy-blocking ValidationBanner (edit view + YAML
  drawer, refreshed after autosave / on workflow switch), YAML drawer reload
  button, `InstalledNode.package/version`. Canvas backspace guard: canvas
  shortcuts ignore key events while a text field holds primary focus.
  Operator picker order: ACTORS → INSTALLED MODULES → FUNCTIONS → Elixir.*.
- **Per-node logging + WebSocket log stream (2026-07-17)**: Removed the
  `sink.log` node. Logging is now a per-node build-time flag
  (`config.logging_enabled`) plus runtime-hot-toggleable `log_in`/`log_out`.
  Backend: `Carta.LogFlags` (ETS), `Carta.LogBus` (Registry pubsub),
  `Carta.LogSocket` (Bandit WebSock handler), codegen emits guarded log hooks
  for actor + function nodes. New endpoints: `POST .../inject` (raw Elixir
  literal), `PATCH .../log-flags` (hot toggle), `GET .../logs/stream` (WS),
  `POST /api/v1/validate/elixir-term`. Frontend: drawer gains top-level
  [NODE | LOG] tabs in active mode; LogDrawer = per-point toggle rail +
  aggregated stream view. `source.inject` payload is now `payload_code`
  (Elixir source string, backend-parsed); drawer gets a payload tab with
  syntax highlighting + live server-side validation.
- **Carta runtime + same-origin proxy (2026-07-15)**: Active runtime is
  Carta (`/home/gem/projects/Carta`). Frontend served by Bun proxy at
  `carta.rancidgrandmas.online`, forwarding `/api/*` to Carta on
  `localhost:8060`. Added Deploy button, Inject dialog, and node
  status badges.

## Deployment

Carta and the Flutter frontend both run inside the **apps container** as Launchy
apps. They are not managed by the host supervisor.

| App | Subdomain | Internal Port | Directory | Command |
|-----|-----------|---------------|-----------|---------|
| `cbe1` | (internal) | 8060 | `/home/gem/projects/Carta` | `elixir --sname cbe1 -S mix run --no-halt` |
| `cartaclient` | `carta.rancidgrandmas.online` | 8040 | `/home/gem/projects/CartaClient/frontend` | `bun run serve.js` |

`cbe1` is the personal Carta Engine instance (cbe1 = Carta Backend Engine #1; future
instances would be `cbe2`, `cbe3`, etc.). `cartaclient` serves the Flutter build and
proxies `/api/*` to `cbe1` on `localhost:8060`.

To pick up code changes:

1. `cd /home/gem/projects/Carta && mix compile`
2. Restart the `cbe1` Launchy app.
3. `cd /home/gem/projects/CartaClient/frontend && ~/projects/flutter/bin/flutter build web --release`
4. Restart the `cartaclient` Launchy app.

## Store Schema

Carta persists workflows as individual YAML files in `Carta/flows/` (configured by
`FLOWS_DIR`). Each file is named `{name}.yaml`.

Metadata returned by the CRUD API:
- `name`: workflow name
- `content`: raw YAML string
- `content_hash`: SHA-256 hash of content (for change detection)
- `updated_at`: file mtime in ISO-8601 UTC

Runtime counters are stored in an in-memory ETS table (`:carta_stats`) keyed by
`{flow_id, node_id}`.

## Common Tasks

**Deploy a workflow and inject a test message:**
```bash
# create
bash -c 'cat <<EOF > /tmp/flow.json
{"name":"hello-world","content":"name: hello-world\nnodes:\n  - id: a\n    type: source.inject\n    config:\n      payload_code: \"%{greeted: true}\"\nedges: []\n"}'
curl -s -X POST https://carta.rancidgrandmas.online/api/v1/workflows \
  -H "Content-Type: application/json" -d @/tmp/flow.json

# deploy
curl -s -X POST https://carta.rancidgrandmas.online/api/v1/workflows/hello-world/deploy

# status
curl -s https://carta.rancidgrandmas.online/api/v1/workflows/hello-world/status

# inject (Elixir literal source — backend parses tuples/maps/atoms/kw lists/structs)
curl -s -X POST https://carta.rancidgrandmas.online/api/v1/workflows/hello-world/inject \
  -H "Content-Type: application/json" -d '{"node_id":"a","code":"%{hello: :world}"}'
```

**Import workflows from disk (one-time bootstrap or batch load):**
```bash
# Carta.Store expects one YAML file per workflow in FLOWS_DIR.
cp /path/to/yaml/dir/*.yml /home/gem/projects/Carta/flows/
```

## Testing

**E2E test approach:**
1. Author or load a workflow via the Flutter UI or API.
2. Click **Deploy** in the top bar (or `POST .../deploy`).
3. In Active mode, double-tap a `source.inject` node → edit payload in the
   drawer's inject section → press **trigger** (or `POST .../inject`).
4. Watch the node status badge update (`in:N out:M`) and the **log** drawer
   stream frames over the per-flow WebSocket.
5. Carta logs go to the apps container's stdout (Launchy pipes; `/var/log/launchy/`
   is empty) — read via container logs (`codery_get_container_info service=apps`).

**Unit tests:**
```bash
cd /home/gem/projects/Carta
mix test
```

(`--no-start` is stale guidance — deploy-touching tests need the booted app's
`Carta.Registry` and fail without it.)

**Known gap:** No automated frontend widget/E2E tests yet. Manual testing via UI + `curl`.

## Known Issues

1. **Running flows do not survive Carta restart** — deployments are in-memory. After restart, reload/redeploy YAML definitions.
2. ~~WebSocket through apps-container Nginx~~ **RESOLVED (2026-07-18)** — WS
   upgrade headers landed in `CoderyOSS/Codery` (`c7db390`) and are live. Log
   stream verified end-to-end: browser → Caddy → Nginx → Bun bridge → Carta
   (`wss://carta.rancidgrandmas.online/api/v1/workflows/:name/logs/stream`
   returns 101 + frames). Log hooks are runtime-only: `exec/3` checks
   `log_in`/`log_out` flags on every message; no redeploy needed for toggles.
   (`logging_enabled` was removed entirely on 2026-07-22 — see Recently
   Landed.)
3. **Client deployment modes** — Two connection models with different CORS requirements:
   - **Web (current)**: Flutter SPA served by Bun proxy → Carta same-origin. No CORS needed. Simplest deployment.
   - **Native iOS (planned)**: App connects directly to Carta like a database client (e.g. MongoDB Compass → remote server). Requires CORS support on Carta. Not yet implemented.

3. **App container restarts wipe installed Flutter SDK** — install Flutter to `/home/gem/projects/flutter` (bind-mounted) instead of `/home/gem/flutter`.

## File Layout

```
CartaClient/
├── frontend/                     ← Flutter app
│   ├── lib/
│   │   ├── services/
│   │   │   ├── workflows_api.dart
│   │   │   └── carta_api.dart
│   │   ├── providers/
│   │   │   └── carta_provider.dart
│   │   └── widgets/canvas/
│   │       └── graph_canvas.dart
│   └── serve.js                  ← Bun proxy to Carta
└── openspec/                     ← design proposals

/home/gem/projects/Carta/          ← active Elixir runtime
├── lib/carta/
│   ├── api.ex
│   ├── engine.ex
│   ├── runtime.ex                  ← call adapters for exec graph entries
│   ├── graphs.ex                   ← ETS store for compiled exec graphs
│   ├── store.ex
│   ├── yaml.ex
│   ├── elixir_term.ex              ← literal-only Elixir source parser
│   ├── expr.ex                     ← deploy-time Elixir expr eval + syntax check
│   ├── log_flags.ex                ← ETS runtime log_in/log_out flags
│   ├── log_bus.ex                  ← Registry pubsub for log frames
│   ├── log_socket.ex               ← Bandit WebSock handler (per-flow)
│   └── nodes/
│       ├── task.ex
│       ├── genserver.ex
│       └── source/inject.ex        ← payload_code (literal) | payload_expr (deploy-time eval)
└── flows/                        ← persisted YAML
```

## For Agents Working on This Code

1. **Frontend changes** go in `frontend/`; never edit `design/` prototype files.
2. **Runtime changes** go in `/home/gem/projects/Carta/`.
3. **New node types**: implement the `Carta.Node` behaviour and register in `Carta.Engine`.
4. **YAML schema changes**: update `Carta.Yaml` + add tests.
5. **Always test Carta with `mix test`** (app booted — `--no-start` breaks deploy tests).
6. **After frontend changes**, run `~/projects/flutter/bin/flutter build web --release` and restart the `cartaclient` Launchy app.
