# Design: Local-Install Projects, Flow Tabs, Port Nodes

## Context

The frontend's workflow dropdown and project picker were built without a clear
direction: the dropdown listed every flow from one flat THRT store dir, and the
picker only set a per-workflow `project:` YAML key affecting `mod.*` type
resolution. Neither reflected a coherent project model.

This change lands on a methodology inspired by two tools:

- **VS Code**: a working directory (project) scopes everything the UI shows.
- **Ansible**: start with a single YAML file; grow into multiple files. Ansible
  maps to Trailhead as: `ansible.cfg` → `trailhead.yaml`, playbook →
  `flows/<name>.yaml` (1 file = 1 flow), roles → `subflows/<name>.yaml`
  (existing mechanism).
- **npm/Mix local installs**: THRT is a dependency *of the project*, not a
  global service that imports projects.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Install model | **Local-only**: THRT = Mix dependency of the project (path dep `{:thrt, path: "../THRT"}` in dev) | Independent projects, no conflicts; Mix loads the project's `_build` ebin dirs at boot, so custom code is in scope of `Engine.exec/3` with zero extra machinery |
| Multi-file graph model | **1 flow = 1 YAML file**, many independent flows per project, **port nodes** for cross-flow messages | Kills merge/write-back complexity: no includes, no ordering, no import paths. Matches existing supervision (each flow = own supervisor under `THRT.FlowsSup`) |
| Port pairing | **By channel name** (`config.channel`), runtime registry lookup | No cross-file edges in any YAML; graph build never sees other files ("purely cosmetic" at build time) |
| Flow surface | **Node-RED-style tabs** across the TopBar | All project flows visible, horizontal scroll, drag-reorder, no close (delete only), `+` to create |
| Folder picker | **None** | Local install fixes the project location at boot (cwd) |
| Instance visibility | Settings modal shows mode, project dir, THRT source, install dir | Users run many local instances; need to know which one they're talking to |
| Scaffold (`mix thrt.new`) | **Deferred** to its own change | Mix archive packaging is orthogonal |

## Dev process

1. THRT dev checkout lives at `/home/gem/projects/THRT`.
2. New project: `mix new my_proj` + add `{:thrt, path: "../THRT"}` dep +
   `trailhead.yaml` + conventional dirs (until `mix thrt.new` automates it).
3. `mix deps.get && mix compile` — Mix builds THRT into the project's `_build`
   and tracks path-dep source changes.
4. Run: `mix run --no-halt` in the project dir. cwd = project →
   `THRT.Project.dir()` (default `File.cwd!()`) is correct with zero config.
5. THRT dev iteration: edit THRT source, recompile in the project.

The currently deployed instance (THRT running from its own checkout) is already
a valid local install — its `flows/` keeps working, no migration.

## Project layout (unchanged convention)

```
mix.exs            # {:thrt, ...} dep
trailhead.yaml     # node_modules, links, flow_order
flows/*.yaml       # deployable flows — 1 file = 1 flow
subflows/*.yaml    # reusable parameterized subflows
skills/
lib/               # project's custom Elixir code (node modules)
```

`trailhead.yaml` gains one consumed key: `flow_order: [name, ...]` (tab order,
written by the flow-order endpoint).

## THRT backend changes

### New/changed modules

- **`THRT.PortRegistry`** (new): `Registry` with duplicate keys,
  channel → pids. Started in the application supervision tree.
- **`THRT.Nodes.Port.In`** (new, actor): requires `config.channel`. Registers
  its pid under the channel at init, unregisters on terminate. Received
  messages pipe into its own flow's graph via normal `Engine.exec`.
- **`THRT.Nodes.Port.Out`** (new, actor): requires `config.channel`. On
  message: look up channel pids in `PortRegistry`, mailbox-send the envelope
  to each (fresh envelope id per send, same as edge sends). Zero subscribers →
  drop + stat bump, no crash. Broadcast fan-out, no cross-flow ordering
  guarantees.
- **`THRT.Engine.validate_node_config`**: new clauses for both port kinds —
  missing/blank/non-string `channel` fails fast at deploy/validate.
- **Project endpoint**: `GET /api/v1/project` →
  `{dir, mode: "local", thrt_source, install_dir, flow_order}`.
  `install_dir` from `:code.lib_dir(:thrt)`; `thrt_source` from the path-dep
  source when resolvable (best-effort, may equal `install_dir`).
- **Subflow CRUD**: `GET/POST /api/v1/subflows`,
  `GET/PUT/DELETE /api/v1/subflows/{name}` — mirrors the workflows CRUD shape
  (`{name, content, content_hash, updated_at}`) against
  `THRT.Project.subflows_dir()`.
- **Flow order**: `PUT /api/v1/project/flow-order` with `[names]` body —
  persists `flow_order:` into `trailhead.yaml` (read-modify-write, preserving
  other keys), unknown names rejected 422.

### Deprecated (kept, inert)

- `project:` flow YAML key — parser keeps accepting it; type resolution
  always uses the open project. Frontend stops emitting it.
- `~/.trailhead/projects.yaml` recents — file left alone, no longer surfaced.

### Not built

`POST /api/v1/project/open`, `GET /api/v1/fs/browse`, recents endpoints —
no folder switching in local-install mode.

## Frontend changes

- **TopBar tabs** replace `_WorkflowSelect` and `ProjectPicker` (both deleted):
  - One tab per flow in the project; subflows open as tabs too (distinct
    icon/color). Subflow tabs open from two places: the `+` menu
    ("new flow" / "new subflow") and an "edit subflow" button on subflow
    nodes' drawer. Existing subflows are listed via the subflow CRUD.
  - Horizontal scrolling overflow; drag to reorder → `PUT flow-order`.
  - No close button; delete via context/long-press menu with confirm.
  - `+` button at the right end creates `untitled[-N]` flow.
  - Active tab drives the canvas (existing `workflowProvider` mechanics);
    per-tab deploy status dot.
- **Settings modal**: new "Instance" section — mode (`local`), project dir,
  THRT source path, install dir (from `GET /api/v1/project`).
- **Removed**: `workflow.project` field emission in `workflow_to_yaml.dart`
  (parse retained for backward compat, ignored on write).
- **Unchanged**: YAML drawer, validation banner, Active/jobs mode, log
  drawer, autosave/validation flow per tab.

## Port node UX

- Node picker: `port.in` / `port.out` entries with labels/descriptions.
- Drawer: channel text field with required-validation (fail-fast server-side
  covers the rest).
- Canvas: port nodes show a channel chip (display-only). Peer counts and
  cross-tab edge visualization are deferred — they'd need registry-count
  plumbing beyond the per-flow status poll.

## Testing

- `mix test` additions:
  - `PortRegistry`: register/lookup/unregister-on-exit.
  - Port nodes: 1→N fan-out across two deployed flows, zero-subscriber drop,
    envelope id freshness.
  - Config validation: missing/blank `channel` rejected.
  - Subflow CRUD round-trip; flow-order persistence + unknown-name rejection;
    project endpoint shape.
- Manual E2E:
  - Tabs: create/rename/delete/reorder, horizontal scroll, persistence across
    reload.
  - Subflow tab editing round-trip.
  - Two flows wired via matching port channels: inject into flow A, watch
    flow B's log stream receive.
  - Settings shows correct instance info.

## Out of scope

- `mix thrt.new` scaffold/archive (separate change).
- Multi-instance frontend (one frontend ↔ one THRT pairing stays).
- fs watching / hot reload of YAML edited externally.
- Port buffering/queueing across undeployed flows.
