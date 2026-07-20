# Trailhead Frontend - Agent Guide

## Purpose

Flutter SPA for Trailhead workflow visualization and management. Follows the Codery design system (dark slate theme variant).

## Current State

- Flutter project targeting **web** (served by Bun proxy) and **iOS** (native app)
- Dark slate background (`#0c0d10` page, `#14161b` main content)
- **Riverpod** for state management (`flutter_riverpod`)
- **Mode rail** + **top bar** implemented, driven by `modeProvider`
- Workflows loaded from backend at startup (Build mode); jobs list loaded from `/api/v1/jobs` (Active/History modes)

### Implemented

| Component | File | Notes |
|-----------|------|-------|
| Design tokens | `lib/theme/tokens.dart` | Colors, spacing, radii from slate dark theme |
| SVG icons | `lib/widgets/icons.dart` | 12 Lucide stroke icons via `flutter_svg` |
| Mode rail | `lib/widgets/mode_rail.dart` | 52px ConsumerWidget rail, reads/writes `modeProvider` |
| Top bar | `lib/widgets/top_bar.dart` | ConsumerWidget — BuildBar, JobBar (active: job dropdown + YAML/stop/reload + status chip), HistoryListBar per mode |
| App button | `lib/widgets/app_button.dart` | ghost/secondary/trail/primary/danger variants |
| Status tag | `lib/widgets/status_tag.dart` | StatusDot (with pulse) + StatusTag (colored pill) |
| State providers | `lib/providers/mode_provider.dart` | `modeProvider`, `selectedJobProvider`, `workflowProvider` |
| Mock data | `lib/providers/mock_data.dart` | `JobSummary`, `WorkflowSummary`, `JobState` + mock instances |
| App shell | `lib/main.dart` | ProviderScope + ConsumerWidget shell: rail + top bar + content |
| Static server | `serve.js` | Bun server for dev preview at trailhead-dev subdomain |
| **Graph canvas** | `lib/widgets/canvas/graph_canvas.dart` | Pan, zoom (gesture), snap-to-grid, dot grid, bezier connections |
| **Worker node** | `lib/widgets/canvas/worker_node.dart` | 168x36 capsule, direction F, selection glow, rail; inject trigger cap (glow + spinner) when deployed in Active mode |
| **Branch node** | `lib/widgets/canvas/routing_node.dart` | Per-port output routing, case rows |
| **Map node** | `lib/widgets/canvas/fan_node.dart` | 168x36 single-line map capsule |
| **Dot grid** | `lib/widgets/canvas/dot_grid_painter.dart` | 32px grid, scales with zoom |
| **Connections** | `lib/widgets/canvas/connection_painter.dart` | Bezier edges with arrowheads |
| **Node context menu** | `lib/widgets/canvas/node_context_menu.dart` | Right-click/long-press actions |
| **Operator picker** | `lib/widgets/canvas/operator_picker.dart` | Insert operator on edge or after node |
| **YAML drawer** | `lib/widgets/yaml_drawer.dart` | Right slide-over, syntax-highlighted workflow YAML |
| **Runs table** | `lib/widgets/runs_table.dart` | Grouped/flat history view |
| **View toggle** | `lib/widgets/view_toggle.dart` | Grouped/flat toggle |
| **Canvas controller** | `lib/providers/canvas_controller.dart` | `CanvasViewport` (zoom + pan), `setZoom()`, `zoomBy()` |

### Not Yet Implemented

- Snapshot filmstrip (bottom strip)
- Per-node executions feed in the drawer's job tab (still `mockStageExecutions`)
- Routing (multiple pages)
- **Zoom control UI overlay** — zoom exists in controller but no `−`/`+`/reset bar yet

## Backend Connectivity (Build mode)

Workflows are read from and written to the THRT backend (`/api/v1/workflows/*`).
The frontend uses **relative URLs** — in production it is served from the same
Bun proxy that forwards to THRT. No connection configuration is needed.

The dev preview (`serve.js` Bun server) proxies `/api/*` to THRT via the
`BACKEND_URL` env var (default `http://localhost:8060`). Override for local dev:

```bash
BACKEND_URL=http://localhost:8060 bun run serve.js
```

Runtime actions (deploy, status, inject) are also sent through the same-origin
proxy to `/api/v1/workflows/:name/deploy|status|inject|log-flags|logs/stream`.
`serve.js` also bridges WebSocket upgrades to THRT for the log stream.

### Key files
- `lib/services/workflows_api.dart` — HTTP client for `/workflows/*` CRUD endpoints
- `lib/services/thrt_api.dart` — HTTP client for runtime deploy/status/inject/validate/log-flags
- `lib/services/log_socket.dart` — WebSocket wrapper with auto-reconnect (log stream)
- `lib/providers/thrt_provider.dart` — deployed-flow set + polled status map + inject buffers
- `lib/providers/log_provider.dart` — log socket lifecycle + per-flow frame ring buffers (cap 200)
- `lib/utils/yaml_to_workflow.dart` — parses stored YAML into canvas model
- `lib/utils/workflow_to_yaml.dart` — serializes canvas model to YAML
- `lib/providers/api_provider.dart` — `workflowsApiProvider` (relative URL)
- `lib/widgets/drawer_panel.dart` — active mode: forced-open 2-column panel (logs left, node details right); builder mode: NodeDrawer only
- `lib/widgets/log_drawer/log_drawer.dart` — per-point toggle rail + stream container
- `lib/widgets/log_drawer/log_stream_view.dart` — aggregated timestamp-ordered log stream
- `lib/widgets/node_drawer/payload_editor.dart` — Elixir code field (flutter_code_editor) + live validation pip
- `serve.js` — Bun dev preview + THRT proxy (HTTP + WebSocket bridge)

### Autosave
Canvas edits trigger debounced (800ms) `PUT /workflows/{name}` via the autosave
listener in `lib/main.dart`. The `workflowDirtyProvider` tracks unsaved state.

### Job snapshots (Active mode)

A job runs an **independent copy** of the workflow, not the live workflow:

- THRT stores the launched YAML on the job row and returns it as `content`
  on `/api/v1/jobs/*`.
- On launch or job select, the YAML is parsed into `jobDocumentsProvider`
  (keyed by job id) — see `lib/providers/mode_provider.dart`.
- Canvas and drawer bind to `canvasWorkflowProvider` (job snapshot in Active
  mode, `workflowProvider` otherwise). All mutations go through
  `updateCanvasWorkflow` / `updateCanvasNode`, which target the job snapshot
  in Active mode — they bypass autosave, so job edits never persist to the
  stored workflow.
- Node repositioning is allowed in Active mode (job-local only).
- The JobBar **reload** button kills the job, re-syncs to the current stored
  workflow, and relaunches (fresh snapshot, job-local edits discarded).
- Inject buffers are job-scoped via `injectBufferKey` (thrt_provider.dart).

## Build Commands

| Action | Command |
|--------|---------|
| Run web dev | `~/projects/flutter/bin/flutter run -d chrome` |
| Build web release | `~/projects/flutter/bin/flutter build web --release` |
| Run tests | `~/projects/flutter/bin/flutter test` |
| Analyze | `~/projects/flutter/bin/flutter analyze` |
| Run iOS build | `~/projects/flutter/bin/flutter build ios --release --no-codesign` (macOS only) |

**Agent rule:** After any code change, run `~/projects/flutter/bin/flutter build web --release` and refresh `trailhead.rancidgrandmas.online`.

## iOS Development

See [`ios/README.md`](ios/README.md) for the full iOS build/test/device recipe. iOS builds require macOS + Xcode — not possible from this Linux sandbox.

## Dev Preview

The Flutter web build is served live at **trailhead.rancidgrandmas.online** via a Bun static server in the apps container.

**Iterate cycle:**
```bash
~/projects/flutter/bin/flutter build web --release
# Refresh browser — changes are live
```

The dev preview proxies `/api/*` to the THRT runtime (`http://localhost:8060`).

**App config:** `trailhead` app, internal port 8040, directory `/home/gem/projects/CoderyTrailhead/frontend`, command `bun run serve.js`.

**Production** (`trailhead.rancidgrandmas.online`): served by Bun proxy + THRT runtime.

## Code Style

- Standard `flutter_lints` package (no third-party lints)
- When adding new packages, add to `pubspec.yaml` first, then run `~/flutter/bin/flutter pub get`
- Riverpod for state management (`flutter_riverpod`, manual providers — no codegen)
- Use `vyuh_node_flow` for graph rendering (when added)

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart              # TrailheadApp (ProviderScope) + TrailheadShell (ConsumerWidget)
│   ├── models/
│   │   ├── workflow_document.dart  # WorkflowDocument (workflow + viewport snapshot)
│   │   ├── workflow_edge.dart      # WorkflowEdge (from, to, case, loop)
│   │   └── workflow_node.dart      # WorkflowNode (id, kind, label, pos, outputs)
│   ├── providers/
│   │   ├── canvas_controller.dart   # CanvasViewport + CanvasController (zoom/pan)
│   │   ├── mode_provider.dart       # modeProvider, selectedJobProvider, workflowProvider
│   │   ├── mock_data.dart           # JobSummary, WorkflowSummary, JobState + mock data
│   │   ├── node_menu_provider.dart  # Node context menu anchor state
│   │   └── operator_picker_provider.dart  # Operator picker anchor state
│   ├── theme/
│   │   └── tokens.dart        # AppColors, AppSpacing, AppRadius
│   ├── utils/
│   │   └── workflow_to_yaml.dart  # workflowToYaml() for YAML drawer
│   └── widgets/
│       ├── app_button.dart    # AppButton (ghost/secondary/trail/primary/danger)
│       ├── canvas/
│       │   ├── branch_node.dart        # BranchNode widget (per-port routing)
│       │   ├── connection_painter.dart # Bezier edges with arrowheads
│       │   ├── dot_grid_painter.dart   # 32px dot grid, scales with zoom
│       │   ├── fan_node.dart           # MapNode (168x36 capsule)
│       │   ├── graph_canvas.dart       # Main canvas: pan, zoom, nodes, edges, snap
│       │   ├── node_context_menu.dart  # Right-click/long-press node actions
│       │   ├── operator_picker.dart    # Insert operator popover
│       │   ├── worker_node.dart        # WorkerNode (168x36 direction F capsule)
│       │   └── zoom_controls.dart      # Zoom bar: − / % / + / fit (TODO)
│       ├── delete_button.dart # Circular delete button with icon
│       ├── icons.dart         # TrailheadIcon (12 Lucide SVG stroke icons)
│       ├── mode_rail.dart     # ModeRail (ConsumerWidget) + AppMode enum
│       ├── runs_table.dart    # Grouped/flat history runs table
│       ├── status_tag.dart    # StatusDot + StatusTag
│       ├── top_bar.dart       # TopBar (ConsumerWidget) + BuildBar/JobBar/HistoryListBar
│       ├── view_toggle.dart   # Grouped/flat view toggle
│       └── yaml_drawer.dart   # Right slide-over, syntax-highlighted YAML
├── serve.js                   # Bun static server for dev preview
├── assets/
│   └── images/
│       └── trailhead-logo.png
├── test/
│   └── widget_test.dart
├── ios/
├── pubspec.yaml
└── AGENTS.md
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management (manual StateProviders + FutureProvider for async loads) |
| `flutter_svg` | SVG icon rendering (Lucide stroke paths) |
| `http` | HTTP client for backend API (`/api/v1/workflows/*`) |
| `yaml` | YAML parser for stored workflow content |
| `cupertino_icons` | iOS-style icons |
| `flutter_code_editor` | Multiline code field with line numbers (payload editor) |
| `flutter_highlight` | Syntax highlight themes for the code field |
| `highlight` | Language grammars (Elixir) for the code field |
| `web_socket_channel` | WebSocket client for the per-flow log stream |

## Design System

The frontend follows the Codery design system at `design.rancidgrandmas.online`.

Theme: **dark** with **slate** variant. Key tokens:

| Token | CSS Variable | Flutter Constant | Hex |
|-------|-------------|-----------------|-----|
| Page background | `--co-bg-0` | `AppColors.bg0` | `#0c0d10` |
| App shell | `--co-bg-1` | `AppColors.bg1` | `#14161b` |
| Surface | `--co-bg-2` | `AppColors.bg2` | `#1a1d23` |
| Hover | `--co-bg-3` | `AppColors.bg3` | `#22262d` |
| Active | `--co-bg-4` | `AppColors.bg4` | `#2b303a` |
| Accent (orange) | `--co-accent` | `AppColors.accent` | `#e8923a` |
| Accent ink | `--co-accent-ink` | `AppColors.accentInk` | `#2d1810` |
| Text strong | `--co-fg-0` | `AppColors.fg0` | `#f3f4f6` |
| Text muted | `--co-fg-2` | `AppColors.fg2` | `#a5a9b1` |
| Border | `--co-border-1` | `AppColors.border1` | `#21242a` |

## Backend

The backend runtime is **THRT** (`/home/gem/projects/THRT`) — an Elixir service that stores workflow YAML and executes node graphs.
