# Compact Worker Node + Fan Container + Operator Picker Cleanup

## Overview

Refactor the graph canvas node system to match the updated design guide. Three tightly related changes: shrink the worker node, add a new fan-out container node, and prune the operator picker to only the types that exist in the current design.

## 1. Compact Worker Node

**File:** `lib/widgets/canvas/worker_node.dart`

### Dimensions
- Width: **160** (was 192)
- Height: **32** (was 96) — exactly one 32px grid gap tall

### Visual treatment
Same atoms as today, repositioned:
- **Status rail**: 3px left border, clipped by rounded corners
- **Label**: centered monospace, 13px, weight 600, `AppColors.fg0`, single-line ellipsis
- **Selection ring**: accent outline + 4px spread glow + drop shadow (same shadows, adjusted for smaller size)
- **Running glow**: accent blur glow + drop shadow
- **Progress bar**: 2px tall, positioned `left: 6, right: 6, bottom: 3` inside the 32px body
- **Status badge**: solid pill straddling top border, positioned `top: -8, right: 8`
- **Delete button**: 18px circle, `top: -8, right: -8`, shown when `selected && onDelete != null`

### Removed content
- `sub` subtitle line
- `model` chip
- Skills chip row
- `Spacer()`

The node becomes a single-line label with the same status affordances.

## 2. Fan Container Node — Collapsed

**File:** `lib/widgets/canvas/fan_node.dart` (new)

### Dimensions
- Width: **160**
- Height: **64** (two 32px grid gaps tall)

### Structure
Two stacked regions inside a rounded shell:

**Header** (26px tall, full width):
- Background: diagonal gradient mixing accent into `bg4`/`bg3` when idle; full accent gradient (`AppColors.crustGradient`) when `selected || running`
- Left: `forEach` icon (13px) + "map" label (mono 10.5px, weight 700)
- Right: count chip (mono 9.5px, weight 700, rounded pill). Content: `×${count}` in builder; `${done} / ${count}` when job is active. A small 5px dot pulses when running.
- **No chevron** — expand-to-modal is deferred to a later pass.

**Body** (remaining 38px):
- Top line: body label (mono 13px, weight 600, `AppColors.fg0`, ellipsis)
- Bottom line: "over `ingest.files`" (mono 9.5px, `AppColors.fg3`, ellipsis)

### Shell
- `AppColors.bg2` background
- Border: `AppColors.accent` when `selected || running`; `AppColors.border2` otherwise
- Box shadow: accent spread ring + drop shadow when selected; accent blur glow + drop shadow when running; subtle drop shadow otherwise
- Border radius: 13px
- Status rail: 3px left border (same as worker)
- Running animation: breathing glow keyframe (same as worker)

### Static mock data (hardcoded inside widget)
- `over: "ingest.files"`
- `count: 7`
- `concurrency: 8`
- `joinMode: "all"`
- `bodyLabel: "comment-file"`

## 3. Operator Picker Cleanup

**File:** `lib/widgets/canvas/operator_picker.dart`

### New enum
```dart
enum OperatorType {
  worker(kind: 'worker', label: 'worker', desc: 'skills · prompt · result', icon: TrailheadIconData.zap),
  branch(kind: 'branch', label: 'branch', desc: 'conditional routing', icon: TrailheadIconData.gitBranch),
  fan(kind: 'fan', label: 'fan', desc: 'fan-out a list, fan-in results', icon: TrailheadIconData.forEach);
}
```

### Removed
- `map` (replaced by `fan`)
- `loop`
- `join`

### Row styling
- `worker` icon box: accent-tinted background (`AppColors.accent.withAlpha(0.14)`), accent icon color
- `branch` / `fan` icon box: `AppColors.bg3` background, `AppColors.fg2` icon color

## 4. Routing Node Cleanup

**File:** `lib/widgets/canvas/routing_node.dart`

Remove from `_routingMeta`:
- `map`
- `loop`
- `join`
- `switch`

Keep only `branch`.

## 5. Graph Canvas Wiring

**File:** `lib/widgets/canvas/graph_canvas.dart`

- Update node kind check: `kind == 'worker'` → `WorkerNode`, `kind == 'fan'` → `FanNode`, else → `RoutingNode`
- Update output handle positions:
  - Worker: `(160, 16)` (right edge, vertical center of 32px body)
  - Fan: `(160, 32)` (right edge, vertical center of 64px body)
  - Routing: keep `(RoutingNode.pillRight, RoutingNode.pillVCenter)`

## 6. Data Model

No schema changes. `WorkflowNode.kind` string already accepts any value. Add one mock `fan` node to `mockWorkflow` in `lib/providers/mock_data.dart` so the canvas shows it on load.

## New Tokens

`AppColors.crustGradient` — accent linear gradient for fan header and worker progress bar. Defined as:
```dart
static const Gradient crustGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFe8923a), Color(0xFFf0a85c)],
);
```

## Files Changed

| File | Change |
|---|---|
| `lib/theme/tokens.dart` | Add `crustGradient` |
| `lib/widgets/canvas/worker_node.dart` | Shrink to 160×32, remove sub/model/skills |
| `lib/widgets/canvas/fan_node.dart` | New widget, collapsed fan container |
| `lib/widgets/canvas/operator_picker.dart` | Enum to worker/branch/fan, remove loop/join/map |
| `lib/widgets/canvas/routing_node.dart` | Purge _routingMeta entries |
| `lib/widgets/canvas/graph_canvas.dart` | Wire fan kind, update handle positions |
| `lib/providers/mock_data.dart` | Add fan node to mockWorkflow |

## Out of Scope

- Expanded fan node / modal workflow editor
- Dynamic fan fields (backend integration)
- Fan node expand/collapse animation
- Chevron interaction on fan header
