# Compact Worker Node + Fan Container + Operator Picker Cleanup

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Shrink worker node to 160×32, add collapsed fan container node (160×64), and prune operator picker to worker/branch/fan.

**Architecture:** Refactor existing `WorkerNode` widget, create new `FanNode` widget, update `OperatorType` enum and picker rows, wire new node kind into `GraphCanvas`, clean up routing meta.

**Tech Stack:** Flutter, Riverpod

---

### Task 1: Add `crustGradient` token

**Files:**
- Modify: `lib/theme/tokens.dart`

- [ ] **Step 1: Add gradient constant after `loafGradient`**

```dart
static const Gradient crustGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFe8923a), Color(0xFFf0a85c)],
);
```

- [ ] **Step 2: Verify `flutter analyze` passes**

---

### Task 2: Shrink WorkerNode to 160×32

**Files:**
- Modify: `lib/widgets/canvas/worker_node.dart`

- [ ] **Step 1: Change dimensions and remove extraneous content**

Update:
- `width: 192` → `width: 160`
- `height: 96` → `height: 32`
- Remove `sub` text, `model` chip, skills chips row
- Keep: status rail, centered label, progress bar (adjusted), status badge, delete button, selection/running shadows
- Padding: change to `EdgeInsets.fromLTRB(10, 0, 8, 0)` (horizontal only, vertically centered)
- Label: keep centered, remove `Expanded` wrapper if unnecessary

- [ ] **Step 2: Adjust progress bar position**

Inside 32px height: `left: 6, right: 6, bottom: 3` still valid.

- [ ] **Step 3: Run `flutter analyze`**

---

### Task 3: Create FanNode widget

**Files:**
- Create: `lib/widgets/canvas/fan_node.dart`

- [ ] **Step 1: Implement collapsed FanNode**

Widget signature:
```dart
class FanNode extends StatelessWidget {
  final WorkflowNode node;
  final JobState? status;
  final bool selected;
  final VoidCallback? onEnter;
  final VoidCallback? onExit;
  final VoidCallback? onDelete;
  
  const FanNode({...});
}
```

Structure:
- SizedBox: 160 × 64
- Same shell pattern as WorkerNode: status rail, border, shadows, selection ring, running glow
- Header (26px): Row with `forEach` icon (13px), "map" label (mono 10.5px bold), count chip (mono 9.5px, pill with bg4 + border)
- Body: Column with body label (mono 13px bold) and "over ingest.files" subtitle (mono 9.5px fg3)
- Static mock values hardcoded

- [ ] **Step 2: Run `flutter analyze`**

---

### Task 4: Purge operator picker

**Files:**
- Modify: `lib/widgets/canvas/operator_picker.dart`

- [ ] **Step 1: Replace OperatorType enum**

Remove `map`, `loop`, `join`. Keep `worker`, `branch`. Add `fan`:
```dart
enum OperatorType {
  worker(kind: 'worker', label: 'worker', desc: 'skills · prompt · result', icon: TrailheadIconData.zap),
  branch(kind: 'branch', label: 'branch', desc: 'conditional routing', icon: TrailheadIconData.gitBranch),
  fan(kind: 'fan', label: 'fan', desc: 'fan-out a list, fan-in results', icon: TrailheadIconData.forEach);
}
```

- [ ] **Step 2: Update icon box logic in `_OperatorRowState.build`**

Change `isWorker` check to: `widget.type == OperatorType.worker`
- worker: accent bg, accent icon
- branch/fan: `AppColors.bg3` bg, `AppColors.fg2` icon

- [ ] **Step 3: Run `flutter analyze`**

---

### Task 5: Clean up RoutingNode meta

**Files:**
- Modify: `lib/widgets/canvas/routing_node.dart`

- [ ] **Step 1: Remove unused entries from `_routingMeta`**

Keep only `branch`.

- [ ] **Step 2: Run `flutter analyze`**

---

### Task 6: Wire FanNode into GraphCanvas

**Files:**
- Modify: `lib/widgets/canvas/graph_canvas.dart`

- [ ] **Step 1: Add import**

```dart
import 'fan_node.dart';
```

- [ ] **Step 2: Update node widget dispatch**

Change ternary:
```dart
final nodeWidget = node.kind == 'worker'
    ? WorkerNode(...)
    : node.kind == 'fan'
        ? FanNode(...)
        : RoutingNode(...);
```

- [ ] **Step 3: Update output handle positions**

- Worker: `(160, 16)` (right edge, vertical center of 32px body)
- Fan: `(160, 32)` (right edge, vertical center of 64px body)
- Routing: keep existing

- [ ] **Step 4: Run `flutter analyze`**

---

### Task 7: Add fan node to mock data

**Files:**
- Modify: `lib/providers/mock_data.dart`

- [ ] **Step 1: Add a fan node to `mockWorkflow.nodes`**

Add after entrypoint:
```dart
WorkflowNode(id: 'commenter', kind: 'fan', label: 'comment-files', x: 220, y: 0),
```

- [ ] **Step 2: Add edge from entrypoint to commenter**

```dart
WorkflowEdge(id: 'edge_1', sourceId: 'entrypoint', targetId: 'commenter'),
```

- [ ] **Step 3: Run `flutter analyze`**

---

### Task 8: Build and verify

- [ ] **Step 1: Build web release**

```bash
~/flutter/bin/flutter build web --release
```

Expected: `✓ Built build/web`

---

## Spec Coverage Check

| Spec Section | Task |
|---|---|
| Compact Worker Node (160×32) | Task 2 |
| Fan Container — Collapsed (160×64) | Task 3 |
| Operator Picker Cleanup | Task 4 |
| Routing Node Cleanup | Task 5 |
| Graph Canvas Wiring | Task 6 |
| Mock Data | Task 7 |
| New Token (`crustGradient`) | Task 1 |

No gaps. No placeholders. All type names consistent.
