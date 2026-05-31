## Context

Trailhead frontend is a Flutter SPA with three modes: Build, Active, History. The shell (rail + top bar + sidebar + canvas) is implemented with mock data. This change adds:

1. History mode showing a RunsTable when no job is selected, and the workflow canvas when a job is selected.
2. Workflow canvas rendering at least one entrypoint node (worker node).
3. "New workflow" button creating a new workflow with an entrypoint node.

## Goals

- History mode: RunsTable replaces the canvas when no job selected; sidebar hidden. When job selected, sidebar appears and canvas shows (with entrypoint node).
- RunsTable: flat + grouped toggle, filter pills, sortable columns, row selection.
- Worker node widget: 192x80px default, status rail, label, model badge, skills chips, progress bar, selection glow.
- New workflow: creates "Untitled" workflow with one entrypoint node, adds to list, selects it, switches to Build mode.

## Non-Goals

- Backend API connection (still mock data).
- Real workflow graph editing (drag, connect edges, delete nodes).
- Stage drawer, filmstrip, snapshot cards.
- Search in RunsTable.

## Architecture

### Data Model Changes

```dart
class WorkflowNode {
  final String id;
  final String kind;      // "worker" | "routing"
  final String label;
  final String? sub;
  final String? model;
  final List<String> skills;
  final double x;
  final double y;
}
```

`WorkflowSummary` gains `final List<WorkflowNode> nodes;`. Every workflow — including new ones — has at least one node: entrypoint.

### State Providers

- `selectedNodeProvider` — tracks selected node ID on canvas.
- `runsTableViewModeProvider` — "flat" | "grouped".

### File Changes

| File | Action |
|------|--------|
| `lib/main.dart` | History layout: hide sidebar when no job selected, show `RunsTable` instead of `GraphCanvas` |
| `lib/providers/mode_provider.dart` | Add `selectedNodeProvider`, `runsTableViewModeProvider` |
| `lib/providers/mock_data.dart` | Add `WorkflowNode` to mock workflows; add `by` field to `JobSummary`; add mock node data |
| `lib/models/workflow_node.dart` | New: `WorkflowNode` class |
| `lib/widgets/runs_table.dart` | New: `RunsTable` widget |
| `lib/widgets/view_toggle.dart` | New: grouped/flat toggle |
| `lib/widgets/canvas/worker_node.dart` | New: `WorkerNode` widget |
| `lib/widgets/canvas/graph_canvas.dart` | Render nodes from `workflowProvider.nodes` |
| `lib/widgets/workflows_sidebar.dart` | Wire "new workflow" button |

### Layout: History Mode

```
no job selected:
  [ModeRail] [TopBar] [RunsTable (full width)]

job selected:
  [ModeRail] [JobsSidebar] [TopBar] [GraphCanvas]
```

### RunsTable

- Header: title + subtitle + filter pills (all / passed / failed / cancelled) + grouped/flat toggle.
- Table columns: status dot, run id, input, status tag, started, duration, tokens, cost, by.
- Grouped mode: insert group header row per workflow name.
- Row tap: sets `selectedJobProvider` → layout switches to sidebar + canvas.
- Footer: count summary.

### Worker Node

192x80px default, rounded rectangle (`AppRadius.md`):
- **Status rail**: 3px left edge, color keyed to run status (or `border2` if no status).
- **Label row**: `StatusDot` (if running) + label (mono 13px, weight 600) + model badge (mono 9px, bg4).
- **Sub**: 11.5px, `fg2`, single line.
- **Skills row**: mono 9px chips, first 3 + overflow count.
- **Progress bar**: 2px bottom strip when running (accent gradient).
- **Status badge**: top-right pill for passed/failed/skipped.
- **Selected**: accent border + outer glow shadow (`0 0 0 1px accent, 0 0 0 4px accent-22%, 0 6px 16px black-40`).
- **Running**: accent glow shadow.

Entrypoint node defaults:
- id: "entrypoint", label: "entrypoint", kind: "worker"
- x: 400, y: 300

### New Workflow Flow

1. Generate ID: `wf_untitled_${DateTime.now().millisecondsSinceEpoch}`
2. Create `WorkflowSummary` with name "Untitled", version 1, nodes: `[entrypointNode]`
3. Append to `workflowsProvider`
4. Set `workflowProvider` to new workflow
5. Set `modeProvider` to `AppMode.build`

## Decisions

- **Option A chosen**: Extend `WorkflowSummary` with inline `nodes` list. Simplest for mock data; refactor to lazy provider when API client arrives.
- **Option A chosen**: Absolute world coords for nodes, pan/zoom via `Transform` on container. Matches existing `CanvasController` and reference Canvas.jsx.

## Risks / Trade-offs

- No real graph editing yet — nodes are static on canvas. Acceptable scope.
- Mock `by` field added to `JobSummary` for table completeness.
