# Box-Marquee Multi-Selection + Group Drag Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add box/marquee multi-selection triggered by plain mouse-drag or touch long-press-drag on the empty grid; selected group supports drag-to-move.

**Architecture:** Two-set selection model (`base` committed + `live` in-flight, union = `current`) under a Riverpod `StateNotifier`. Background gesture recognizers split by device: mouse plain-drag = marquee, space-hold drag = pan, wheel = zoom; touch 1-finger drag = pan, long-press-drag = marquee, pinch = zoom. Node size logic deduped into a `WorkflowNode` extension.

**Tech Stack:** Flutter 3.7+, Dart, `flutter_riverpod` 2.6.1 (manual providers, no codegen), `flutter_test`.

**Reference spec:** `docs/superpowers/specs/2026-06-18-box-marquee-multiselect-design.md`

---

## File Structure

| File | Status | Responsibility |
|---|---|---|
| `frontend/lib/models/workflow_node.dart` | Modify | Add `WorkflowNodeRect` extension (width/height/rect) |
| `frontend/lib/providers/selection_notifier.dart` | Create | `SelectionState`, `SelectionNotifier`, `selectionProvider` |
| `frontend/lib/providers/marquee_provider.dart` | Create | `MarqueeState`, `marqueeProvider` |
| `frontend/lib/providers/canvas_controller.dart` | Modify | Add `zoomAt(delta, screenCursor)` |
| `frontend/lib/providers/mode_provider.dart` | Modify | Remove `selectedNodeProvider`; add `spaceHeldProvider` |
| `frontend/lib/widgets/canvas/marquee_painter.dart` | Create | `MarqueePainter` (CustomPainter) |
| `frontend/lib/widgets/canvas/graph_canvas.dart` | Modify | Gestures, marquee overlay, group drag, migrate reads |
| `frontend/lib/widgets/canvas/zoom_controls.dart` | Modify | Use `node.width` / `node.height` |
| `frontend/lib/widgets/canvas/connection_painter.dart` | Modify | Use `node.width` / `node.height` |
| `frontend/lib/main.dart` | Modify | Replace `selectedNodeProvider` read with `selectionProvider` |
| `frontend/test/workflow_node_rect_test.dart` | Create | Unit tests for rect extension |
| `frontend/test/selection_notifier_test.dart` | Create | Unit tests for selection state machine |
| `frontend/test/marquee_painter_test.dart` | Create | Golden test for painter |

**Run commands (use these exact paths):**
- Tests: `~/flutter/bin/flutter test test/<file>` (run from `frontend/`)
- All tests: `~/flutter/bin/flutter test`
- Analyze: `~/flutter/bin/flutter analyze`
- Build web: `~/flutter/bin/flutter build web --release`

---

### Task 1: WorkflowNodeRect extension + dedup

**Files:**
- Modify: `frontend/lib/models/workflow_node.dart` (append after line 82)
- Modify: `frontend/lib/widgets/canvas/graph_canvas.dart:50-62` (remove closures, use extension)
- Modify: `frontend/lib/widgets/canvas/zoom_controls.dart:27-39` (remove closures, use extension)
- Modify: `frontend/lib/widgets/canvas/connection_painter.dart:14-23, 39-44, 46-71` (use extension)
- Test: `frontend/test/workflow_node_rect_test.dart`

- [ ] **Step 1: Write the failing test**

Create `frontend/test/workflow_node_rect_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/workflow_node.dart';

void main() {
  group('WorkflowNodeRect', () {
    test('worker rect is 168x36 at (x,y)', () {
      final n = const WorkflowNode(id: 'w', kind: 'worker', label: 'w', x: 10, y: 20);
      expect(n.width, 168.0);
      expect(n.height, 36.0);
      expect(n.rect, const Rect.fromLTWH(10, 20, 168, 36));
    });

    test('fan rect is 168x36 at (x,y)', () {
      final n = const WorkflowNode(id: 'f', kind: 'fan', label: 'f', x: 0, y: 0);
      expect(n.width, 168.0);
      expect(n.height, 36.0);
    });

    test('branch with outputs uses outputs.length', () {
      final n = WorkflowNode(
        id: 'b', kind: 'branch', label: 'b', x: 5, y: 6,
        outputs: const [
          BranchOutput(id: '0', label: 'a'),
          BranchOutput(id: '1', label: 'b'),
          BranchOutput(id: '2', label: 'c'),
        ],
      );
      // BranchNode.padY=9, rowHeight=27 -> 9*2 + 3*27 = 99
      expect(n.width, 130.0);
      expect(n.height, 99.0);
    });

    test('branch with no outputs defaults to 4 rows', () {
      const n = WorkflowNode(id: 'b', kind: 'branch', label: 'b', x: 0, y: 0);
      // 9*2 + 4*27 = 126
      expect(n.height, 126.0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/workflow_node_rect_test.dart` (from `frontend/`)
Expected: FAIL — `The getter 'width' isn't defined for the type 'WorkflowNode'`.

- [ ] **Step 3: Add the extension**

Append to `frontend/lib/models/workflow_node.dart` (after line 82, end of file). Add this import at the top of the file (line 1 area — insert before `class BranchOutput`):

```dart
import 'package:flutter/material.dart' show Rect;
```

Wait — `Rect` is in `dart:ui` re-exported by material. To avoid pulling material into the model, use:

```dart
import 'dart:ui' show Rect;
```

Add at very top of `workflow_node.dart` (before line 1):

```dart
import 'dart:ui' show Rect;
```

Append at end of file:

```dart
extension WorkflowNodeRect on WorkflowNode {
  double get width => switch (kind) {
    'worker' => 168.0,
    'fan'    => 168.0,
    _        => 130.0, // BranchNode.width
  };

  double get height => switch (kind) {
    'worker' => 36.0,
    'fan'    => 36.0,
    _        => outputs.isNotEmpty
        ? 9.0 * 2 + outputs.length * 27.0   // BranchNode.padY*2 + n*rowHeight
        : 9.0 * 2 + 4 * 27.0,              // default 4 rows
  };

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}
```

Note: hardcoding 9.0/27.0/130.0 here duplicates `BranchNode` constants, but those live in `routing_node.dart` (a widget) and cannot be imported by the model layer without an upward dependency. Document this coupling in a comment.

- [ ] **Step 4: Run test to verify it passes**

Run: `~/flutter/bin/flutter test test/workflow_node_rect_test.dart`
Expected: PASS — 4 tests.

- [ ] **Step 5: Dedup `graph_canvas.dart`**

In `frontend/lib/widgets/canvas/graph_canvas.dart`, delete lines 50-62 (the `nodeWidth` and `nodeHeight` closures inside `build`). Then find-and-replace remaining call sites:

| Line | Current | New |
|---|---|---|
| 110 | `nodeHeight(source.kind, outputs: source.outputs)` | `source.height` |
| 111 | `nodeHeight(type.kind)` | `WorkflowNode(id: '', kind: type.kind, label: '').height` *(or compute inline — see note)* |
| 392 | `nodeHeight(node.kind, outputs: node.outputs)` | `node.height` |
| 419 | `nodeHeight(node.kind, outputs: node.outputs)` | `node.height` |
| 450 | `nodeHeight(node.kind, outputs: node.outputs)` | `node.height` |
| 455 | `nodeHeight(node.kind, outputs: node.outputs)` | `node.height` |
| 465 | `nodeHeight(node.kind, outputs: node.outputs)` | `node.height` |
| 470 (×2) | `nodeHeight(node.kind, outputs: node.outputs)` and `nodeWidth(node.kind)` | `node.height`, `node.width` |

**Note for line 111:** `nodeHeight(type.kind)` is called with only a kind string (no node instance). Replace with a local helper at top of `addNode`:

```dart
double heightForKind(String kind) => switch (kind) {
  'worker' => 36.0,
  'fan'    => 36.0,
  _        => 9.0 * 2 + 4 * 27.0,
};
```

Then `nodeHeight(type.kind)` → `heightForKind(type.kind)`. Or simpler: since `type.kind` is always one of these and never has outputs at creation, use `WorkflowNode(id: '', kind: type.kind, label: '').height`.

- [ ] **Step 6: Dedup `zoom_controls.dart`**

In `frontend/lib/widgets/canvas/zoom_controls.dart`, delete lines 27-39 (the two closures). Update `fitToView` (lines 51-58):

```dart
for (final node in nodes) {
  minX = minX < node.x ? minX : node.x;
  minY = minY < node.y ? minY : node.y;
  maxX = maxX > node.x + node.width ? maxX : node.x + node.width;
  maxY = maxY > node.y + node.height ? maxY : node.y + node.height;
}
```

- [ ] **Step 7: Dedup `connection_painter.dart`**

In `frontend/lib/widgets/canvas/connection_painter.dart`:

Delete lines 14-23 (the `_workerWidth`/`_workerHeight`/`_fanWidth`/`_fanHeight`/`_branchWidth`/`_branchHeight` static consts).

Replace `_branchNodeHeight` (lines 39-44) with usage of extension:

```dart
// Remove _branchNodeHeight method entirely.
```

Replace `_exitPoint` (lines 46-53):

```dart
Offset _exitPoint(WorkflowNode node, WorkflowEdge edge) {
  final pos = _nodePos(node);
  return switch (node.kind) {
    'worker' => Offset(pos.dx + node.width, pos.dy + node.height / 2),
    'fan'    => Offset(pos.dx + node.width, pos.dy + node.height / 2),
    _        => _branchExitPoint(node, pos, edge.sourcePort),
  };
}
```

Replace `_branchExitPoint` (lines 55-62):

```dart
Offset _branchExitPoint(WorkflowNode node, Offset pos, int? sourcePort) {
  if (sourcePort == null || node.outputs.isEmpty) {
    return Offset(pos.dx + node.width, pos.dy + node.height / 2);
  }
  final y = pos.dy + 9.0 + sourcePort * 27.0 + 27.0 / 2; // BranchNode.padY + port*rowHeight + rowHeight/2
  return Offset(pos.dx + node.width, y);
}
```

Replace `_entryPoint` (lines 64-71):

```dart
Offset _entryPoint(WorkflowNode node) {
  final pos = _nodePos(node);
  return switch (node.kind) {
    'worker' => Offset(pos.dx, pos.dy + node.height / 2),
    'fan'    => Offset(pos.dx, pos.dy + node.height / 2),
    _        => Offset(pos.dx, pos.dy + node.height / 2),
  };
}
```

(Simplification: entry is always vertical-center of left edge for all kinds.)

- [ ] **Step 8: Run full test suite + analyze**

Run: `~/flutter/bin/flutter test`
Run: `~/flutter/bin/flutter analyze`
Expected: All existing tests pass, no new warnings.

- [ ] **Step 9: Commit**

```bash
git add frontend/lib/models/workflow_node.dart \
        frontend/lib/widgets/canvas/graph_canvas.dart \
        frontend/lib/widgets/canvas/zoom_controls.dart \
        frontend/lib/widgets/canvas/connection_painter.dart \
        frontend/test/workflow_node_rect_test.dart
git commit -m "refactor: extract WorkflowNodeRect extension, dedup size helpers"
```

---

### Task 2: SelectionNotifier + SelectionState

**Files:**
- Create: `frontend/lib/providers/selection_notifier.dart`
- Test: `frontend/test/selection_notifier_test.dart`

- [ ] **Step 1: Write the failing test**

Create `frontend/test/selection_notifier_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/selection_notifier.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  SelectionNotifier get() => container.read(selectionProvider.notifier);
  SelectionState state() => container.read(selectionProvider);

  test('initial state is empty', () {
    expect(state().current, isEmpty);
    expect(state().active, isFalse);
  });

  test('selectOne replaces selection', () {
    get().selectOne('a');
    expect(state().current, {'a'});
    get().selectOne('b');
    expect(state().current, {'b'});
  });

  test('toggleOne adds then removes', () {
    get().toggleOne('a');
    expect(state().current, {'a'});
    get().toggleOne('a');
    expect(state().current, isEmpty);
  });

  test('toggleOne on top of existing selection adds', () {
    get().selectOne('a');
    get().toggleOne('b');
    expect(state().current, {'a', 'b'});
  });

  test('clear empties everything', () {
    get().selectOne('a');
    get().beginMarquee();
    get().updateMarqueeLive({'b', 'c'});
    get().clear();
    expect(state().current, isEmpty);
    expect(state().live, isEmpty);
    expect(state().base, isEmpty);
  });

  test('beginMarquee freezes base, clears live', () {
    get().selectOne('a');
    get().beginMarquee();
    expect(state().base, {'a'});
    expect(state().live, isEmpty);
    expect(state().active, isFalse);
  });

  test('updateMarqueeLive overwrites live only', () {
    get().selectOne('a');
    get().beginMarquee();
    get().updateMarqueeLive({'b', 'c'});
    expect(state().live, {'b', 'c'});
    expect(state().base, {'a'});
    expect(state().current, {'a', 'b', 'c'});
    expect(state().active, isTrue);
  });

  test('updateMarqueeLive shrinking removes from live', () {
    get().beginMarquee();
    get().updateMarqueeLive({'a', 'b', 'c'});
    get().updateMarqueeLive({'b'});
    expect(state().current, {'b'});
    expect(state().live, {'b'});
  });

  test('commitMarquee unions live into base and clears live', () {
    get().selectOne('a');
    get().beginMarquee();
    get().updateMarqueeLive({'b', 'c'});
    get().commitMarquee();
    expect(state().base, {'a', 'b', 'c'});
    expect(state().live, isEmpty);
    expect(state().active, isFalse);
  });

  test('cancelMarquee discards live, keeps base', () {
    get().selectOne('a');
    get().beginMarquee();
    get().updateMarqueeLive({'b'});
    get().cancelMarquee();
    expect(state().base, {'a'});
    expect(state().live, isEmpty);
    expect(state().current, {'a'});
  });

  test('multiple marquees accumulate via commit', () {
    get().beginMarquee();
    get().updateMarqueeLive({'a'});
    get().commitMarquee();
    get().beginMarquee();
    get().updateMarqueeLive({'b'});
    get().commitMarquee();
    expect(state().current, {'a', 'b'});
  });

  test('removeIds removes from base only', () {
    get().selectOne('a');
    get().beginMarquee();
    get().updateMarqueeLive({'b'});
    get().removeIds({'a'});
    expect(state().base, isEmpty);
    expect(state().live, {'b'});
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/selection_notifier_test.dart`
Expected: FAIL — `selection_provider.dart` not found / `Target of URI doesn't exist`.

- [ ] **Step 3: Create the notifier**

Create `frontend/lib/providers/selection_notifier.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectionState {
  final Set<String> base;
  final Set<String> live;

  const SelectionState({
    Set<String>? base,
    Set<String>? live,
  })  : base = base ?? const {},
        live = live ?? const {};

  Set<String> get current => base.union(live);

  bool get active => live.isNotEmpty;

  bool contains(String id) => base.contains(id) || live.contains(id);

  SelectionState copyWith({Set<String>? base, Set<String>? live}) {
    return SelectionState(
      base: base ?? this.base,
      live: live ?? this.live,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectionState &&
          setEquals(base, other.base) &&
          setEquals(live, other.live);

  @override
  int get hashCode => Object.hash(Object.hashAll(base), Object.hashAll(live));
}

bool setEquals(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(const SelectionState());

  void selectOne(String id) {
    state = SelectionState(base: {id}, live: const {});
  }

  void toggleOne(String id) {
    final next = Set<String>.from(state.base);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = SelectionState(base: next, live: const {});
  }

  void clear() {
    state = const SelectionState();
  }

  void beginMarquee() {
    state = SelectionState(base: Set<String>.from(state.current), live: const {});
  }

  void updateMarqueeLive(Set<String> hits) {
    state = state.copyWith(live: Set<String>.from(hits));
  }

  void commitMarquee() {
    state = SelectionState(base: state.current, live: const {});
  }

  void cancelMarquee() {
    state = state.copyWith(live: const {});
  }

  void removeIds(Iterable<String> ids) {
    final next = Set<String>.from(state.base)..removeAll(ids);
    state = state.copyWith(base: next);
  }
}

final selectionProvider =
    StateNotifierProvider<SelectionNotifier, SelectionState>(
  (ref) => SelectionNotifier(),
);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `~/flutter/bin/flutter test test/selection_notifier_test.dart`
Expected: PASS — 13 tests.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/providers/selection_notifier.dart \
        frontend/test/selection_notifier_test.dart
git commit -m "feat: add SelectionNotifier with base/live union model"
```

---

### Task 3: MarqueeState provider + MarqueePainter

**Files:**
- Create: `frontend/lib/providers/marquee_provider.dart`
- Create: `frontend/lib/widgets/canvas/marquee_painter.dart`
- Test: `frontend/test/marquee_painter_test.dart`

- [ ] **Step 1: Write the failing golden test**

Create `frontend/test/marquee_painter_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/canvas/marquee_painter.dart';

void main() {
  testWidgets('MarqueePainter draws a filled rect with border', (tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: CustomPaint(
          painter: MarqueePainter(const Rect.fromLTWH(10, 20, 100, 50)),
          size: const Size(200, 200),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('goldens/marquee_painter.png'),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/marquee_painter_test.dart`
Expected: FAIL — `marquee_painter.dart` doesn't exist.

- [ ] **Step 3: Create `MarqueeState` provider**

Create `frontend/lib/providers/marquee_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarqueeState {
  final Rect screenRect;
  final bool active;

  const MarqueeState({this.screenRect = Rect.zero, this.active = false});

  MarqueeState copyWith({Rect? screenRect, bool? active}) {
    return MarqueeState(
      screenRect: screenRect ?? this.screenRect,
      active: active ?? this.active,
    );
  }
}

final marqueeProvider = StateProvider<MarqueeState>(
  (ref) => const MarqueeState(),
);
```

- [ ] **Step 4: Create `MarqueePainter`**

Create `frontend/lib/widgets/canvas/marquee_painter.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class MarqueePainter extends CustomPainter {
  final Rect rect;

  const MarqueePainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = AppColors.accent.withValues(alpha: 0.12);
    final border = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, border);
  }

  @override
  bool shouldRepaint(covariant MarqueePainter old) => old.rect != rect;
}
```

- [ ] **Step 5: Generate golden**

Run: `~/flutter/bin/flutter test --update-goldens test/marquee_painter_test.dart`
Expected: PASS (golden created).

- [ ] **Step 6: Re-run golden test (no update)**

Run: `~/flutter/bin/flutter test test/marquee_painter_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/providers/marquee_provider.dart \
        frontend/lib/widgets/canvas/marquee_painter.dart \
        frontend/test/marquee_painter_test.dart \
        frontend/test/goldens/marquee_painter.png
git commit -m "feat: add marquee state provider and painter"
```

---

### Task 4: CanvasController.zoomAt (wheel zoom)

**Files:**
- Modify: `frontend/lib/providers/canvas_controller.dart` (append method after `endScale`, line 97)
- Test: `frontend/test/canvas_controller_test.dart`

- [ ] **Step 1: Write the failing test**

Create `frontend/test/canvas_controller_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/canvas_controller.dart';

void main() {
  late ProviderContainer container;
  late CanvasController controller;

  setUp(() {
    container = ProviderContainer();
    controller = container.read(canvasControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('zoomAt preserves world point under cursor (zoom in)', () {
    const cursor = Offset(100, 50);
    final worldBefore =
        (cursor - controller.state.pan) / controller.state.zoom;
    controller.zoomAt(100, cursor); // positive delta = zoom out; use negative
  });

  test('zoomAt with negative delta zooms in and keeps cursor anchored', () {
    const cursor = Offset(200, 100);
    final vp0 = controller.state;
    final worldBefore = (cursor - vp0.pan) / vp0.zoom;

    controller.zoomAt(-100, cursor);

    final vp1 = controller.state;
    expect(vp1.zoom, greaterThan(vp0.zoom));
    final worldAfter = (cursor - vp1.pan) / vp1.zoom;
    expect((worldAfter - worldBefore).distance, lessThan(1e-9));
  });

  test('zoomAt with positive delta zooms out and keeps cursor anchored', () {
    const cursor = Offset(0, 0);
    controller.setZoom(1.0);
    controller.state;
    final vp0 = controller.state;
    final worldBefore = (cursor - vp0.pan) / vp0.zoom;

    controller.zoomAt(120, cursor);

    final vp1 = controller.state;
    expect(vp1.zoom, lessThan(vp0.zoom));
    final worldAfter = (cursor - vp1.pan) / vp1.zoom;
    expect((worldAfter - worldBefore).distance, lessThan(1e-9));
  });

  test('zoomAt respects clamp at 2.0', () {
    controller.setZoom(1.95);
    controller.zoomAt(-1000, Offset.zero);
    expect(controller.state.zoom, lessThanOrEqualTo(2.0));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/canvas_controller_test.dart`
Expected: FAIL — `zoomAt` not defined.

- [ ] **Step 3: Add `zoomAt`**

In `frontend/lib/providers/canvas_controller.dart`, append after `endScale` (line 97):

```dart
  /// Zoom by a scroll-delta amount anchored to a screen cursor position.
  /// Negative delta zooms in (wheel scroll up), positive zooms out.
  void zoomAt(double scrollDelta, Offset screenCursor) {
    final factor = scrollDelta < 0 ? 1.15 : 1 / 1.15;
    final newZoom = (state.zoom * factor).clamp(0.35, 2.0);
    // Keep world point under cursor fixed:
    final worldBefore = (screenCursor - state.pan) / state.zoom;
    final newPan = screenCursor - worldBefore * newZoom;
    state = CanvasViewport(zoom: newZoom, pan: newPan);
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `~/flutter/bin/flutter test test/canvas_controller_test.dart`
Expected: PASS — 4 tests. (Delete the first incomplete test stub before running, or merge it into the third — it's just a placeholder.)

Replace the first test with this to avoid being a no-op:

```dart
  test('zoomAt is a no-op when state already at clamp and delta pushes past', () {
    controller.setZoom(2.0);
    final vp0 = controller.state;
    controller.zoomAt(-100, const Offset(0, 0));
    // already at max, factor would push past — clamp keeps it at 2.0 but pan may shift slightly
    expect(controller.state.zoom, 2.0);
  });
```

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/providers/canvas_controller.dart \
        frontend/test/canvas_controller_test.dart
git commit -m "feat: add wheel-zoom anchored to cursor in CanvasController"
```

---

### Task 5: spaceHeldProvider

**Files:**
- Modify: `frontend/lib/providers/mode_provider.dart` (append after line 30)

- [ ] **Step 1: Add provider**

Append to `frontend/lib/providers/mode_provider.dart`:

```dart
final spaceHeldProvider = StateProvider<bool>((ref) => false);
```

- [ ] **Step 2: Analyze**

Run: `~/flutter/bin/flutter analyze`
Expected: no new warnings.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/providers/mode_provider.dart
git commit -m "feat: add spaceHeldProvider for space-drag panning"
```

---

### Task 6: Migrate selectedNodeProvider → selectionProvider (behavior-preserving)

This task does NOT change behavior — single-node selection still works exactly as before. It only swaps the underlying state container. Marquee/group-drag come later.

**Files:**
- Modify: `frontend/lib/providers/mode_provider.dart:24` (remove `selectedNodeProvider`)
- Modify: `frontend/lib/widgets/canvas/graph_canvas.dart` (7 sites)
- Modify: `frontend/lib/main.dart:103`
- Modify: `frontend/test/widget_test.dart` (if it references selection — it doesn't, skip)

- [ ] **Step 1: Update `graph_canvas.dart` imports**

In `frontend/lib/widgets/canvas/graph_canvas.dart`, add at top of imports (after line 11):

```dart
import '../../providers/selection_notifier.dart';
```

- [ ] **Step 2: Update line 41 (`watch`)**

Change:
```dart
final selectedNodeId = ref.watch(selectedNodeProvider);
```
to:
```dart
final selection = ref.watch(selectionProvider);
final selectedNodeId = selection.current.length == 1 ? selection.current.first : null;
```

(Rationale: existing code at line 289 `isSelected = selectedNodeId == node.id` only handles single. Multi-node case lights up in Task 11.)

- [ ] **Step 3: Update line 134 (`addNode` sets selection)**

Change:
```dart
ref.read(selectedNodeProvider.notifier).state = id;
```
to:
```dart
ref.read(selectionProvider.notifier).selectOne(id);
```

- [ ] **Step 4: Update line 148 (`deleteNode` clears)**

Change:
```dart
ref.read(selectedNodeProvider.notifier).state = null;
```
to:
```dart
ref.read(selectionProvider.notifier).removeIds(nodeId);
```

(`removeIds` is correct even when nodeId wasn't selected — it's a no-op then. Clears just this id, not others.)

- [ ] **Step 5: Update line 171 (`duplicateNode` selects new)**

Change `ref.read(selectedNodeProvider.notifier).state = id;` →
```dart
ref.read(selectionProvider.notifier).selectOne(id);
```

- [ ] **Step 6: Update line 204-205 (`collapseNode` clears if selected)**

Replace:
```dart
if (selectedNodeId == nodeId) {
  ref.read(selectedNodeProvider.notifier).state = null;
}
```
with:
```dart
ref.read(selectionProvider.notifier).removeIds([nodeId]);
```

(The `if` check is no longer needed — `removeIds` is safe unconditionally. Keeps semantics: removes only that node's id.)

- [ ] **Step 7: Update line 238 (background tap clears)**

Change:
```dart
ref.read(selectedNodeProvider.notifier).state = null;
```
to:
```dart
ref.read(selectionProvider.notifier).clear();
```

- [ ] **Step 8: Update line 353-355 (node tap toggle)**

Current:
```dart
onTap: () {
  ref.read(selectedNodeProvider.notifier).state =
      isSelected ? null : node.id;
  if (!isSelected) {
    ref.read(operatorPickerProvider.notifier).state = null;
  }
},
```

Replace with:
```dart
onTap: () {
  ref.read(selectionProvider.notifier).toggleOne(node.id);
  if (!isSelected) {
    ref.read(operatorPickerProvider.notifier).state = null;
  }
},
```

(`toggleOne` matches old behavior exactly when selection has 0 or 1 items.)

- [ ] **Step 9: Update keyboard delete (lines 217-224)**

Current:
```dart
if (event.logicalKey == LogicalKeyboardKey.delete ||
    event.logicalKey == LogicalKeyboardKey.backspace) {
  if (selectedNodeId != null) {
    deleteNode(selectedNodeId);
    return KeyEventResult.handled;
  }
}
```

Replace with:
```dart
if (event.logicalKey == LogicalKeyboardKey.delete ||
    event.logicalKey == LogicalKeyboardKey.backspace) {
  final current = ref.read(selectionProvider).current
      .where((id) => id != 'entrypoint')
      .toList();
  if (current.isNotEmpty) {
    for (final id in current) {
      deleteNode(id);
    }
    return KeyEventResult.handled;
  }
}
```

(Delete now handles multi-selection. `deleteNode` already removes from selection via `removeIds`.)

- [ ] **Step 10: Update `main.dart:103`**

In `frontend/lib/main.dart`, replace:
```dart
ref.read(selectedNodeProvider.notifier).state = null;
```
with:
```dart
ref.read(selectionProvider.notifier).clear();
```

And add the import at top of file:
```dart
import 'providers/selection_notifier.dart';
```

- [ ] **Step 11: Remove `selectedNodeProvider`**

In `frontend/lib/providers/mode_provider.dart`, delete line 24:
```dart
final selectedNodeProvider = StateProvider<String?>((ref) => null);
```

- [ ] **Step 12: Run tests + analyze**

Run: `~/flutter/bin/flutter test`
Run: `~/flutter/bin/flutter analyze`
Expected: all pass. If `unused_import` warning for `selection_notifier.dart` in any file that doesn't use it, remove the import.

- [ ] **Step 13: Commit**

```bash
git add frontend/lib/providers/mode_provider.dart \
        frontend/lib/widgets/canvas/graph_canvas.dart \
        frontend/lib/main.dart
git commit -m "refactor: migrate selectedNodeProvider to selectionProvider"
```

---

### Task 7: Marquee overlay widget in graph_canvas

**Files:**
- Modify: `frontend/lib/widgets/canvas/graph_canvas.dart` (add overlay after line 484)

- [ ] **Step 1: Add imports**

At top of `frontend/lib/widgets/canvas/graph_canvas.dart`, add:

```dart
import '../../providers/marquee_provider.dart';
import 'marquee_painter.dart';
```

- [ ] **Step 2: Add marquee overlay widget**

After line 484 (the closing `),` of the world-transform `Transform.translate(...)`, before the screen-space picker at line 485), insert:

```dart
// Screen-space marquee overlay
Consumer(
  builder: (_, ref, __) {
    final m = ref.watch(marqueeProvider);
    if (!m.active) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: MarqueePainter(m.screenRect)),
      ),
    );
  },
),
```

`IgnorePointer` is critical — marquee overlay must not intercept the drag that's driving it.

- [ ] **Step 3: Analyze**

Run: `~/flutter/bin/flutter analyze`
Expected: no warnings.

- [ ] **Step 4: Build verify**

Run: `~/flutter/bin/flutter build web --release`
Expected: succeeds. (Marquee won't be visible yet — never set active.)

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/widgets/canvas/graph_canvas.dart
git commit -m "feat: add marquee overlay widget (render only, no trigger yet)"
```

---

### Task 8: Mouse marquee gesture + space-hold pan + wheel zoom

**Files:**
- Modify: `frontend/lib/widgets/canvas/graph_canvas.dart` (lines 213-249 — `Focus`/`Listener`/`GestureDetector` rework)

- [ ] **Step 1: Add a helper to compute marquee hits**

In `graph_canvas.dart`, inside the `build` method (near the `showPicker` helper at line 89), add:

```dart
void updateMarqueeFromScreenRect(Rect screenRect) {
  final world = Rect.fromPoints(
    (screenRect.topLeft - viewport.pan) / viewport.zoom,
    (screenRect.bottomRight - viewport.pan) / viewport.zoom,
  );
  final hits = workflow.nodes
      .where((n) => n.rect.overlaps(world))
      .map((n) => n.id)
      .toSet();
  ref.read(selectionProvider.notifier).updateMarqueeLive(hits);
  ref.read(marqueeProvider.notifier).state =
      MarqueeState(screenRect: screenRect, active: true);
}
```

- [ ] **Step 2: Add state for mouse drag origin**

Inside `build` (after the `pickerAnchor` watch at line 45), add:

```dart
final spaceHeld = ref.watch(spaceHeldProvider);
```

(We need a mouse-drag origin. Since `Listener` gives raw `PointerDownEvent`/`PointerMoveEvent`, store origin in a closure-captured variable or use a `LateInitializationError`-safe field. Simplest: a `ValueNotifier<Offset?>` field on the widget, or use a `_mouseMarqueeStart` field on a `StatefulWidget` conversion. **However** `GraphCanvas` is currently a `ConsumerWidget`. To hold mutable gesture state cleanly, we keep an instance variable inside a `ConsumerStatefulWidget`.)

**Decision:** Convert `GraphCanvas` from `ConsumerWidget` to `ConsumerStatefulWidget` so we can hold gesture state (`Offset? _marqueeStart`). This is a larger change but the right one.

Skip the conversion for now by using a top-level `StateProvider<Offset?>`:

In `frontend/lib/providers/marquee_provider.dart`, append:

```dart
final mouseMarqueeStartProvider = StateProvider<Offset?>((ref) => null);
```

Then in `build`:
```dart
final mouseMarqueeStart = ref.watch(mouseMarqueeStartProvider);
```

- [ ] **Step 3: Replace `Listener.onPointerMove` (line 229-233)**

Current:
```dart
child: Listener(
  onPointerMove: (event) {
    if (event.kind == PointerDeviceKind.mouse) {
      controller.pan(event.delta);
    }
  },
  child: GestureDetector(
```

Replace with:

```dart
child: Listener(
  onPointerDown: (event) {
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons == kPrimaryButton &&
        !spaceHeld &&
        editable) {
      ref.read(mouseMarqueeStartProvider.notifier).state = event.position;
      ref.read(selectionProvider.notifier).beginMarquee();
    }
  },
  onPointerMove: (event) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (spaceHeld) {
        controller.pan(event.delta);
        return;
      }
      final start = ref.read(mouseMarqueeStartProvider);
      if (start != null) {
        final rect = Rect.fromPoints(start, event.position);
        updateMarqueeFromScreenRect(rect);
      }
    }
  },
  onPointerUp: (event) {
    if (event.kind == PointerDeviceKind.mouse) {
      final start = ref.read(mouseMarqueeStartProvider);
      if (start != null) {
        ref.read(selectionProvider.notifier).commitMarquee();
        ref.read(mouseMarqueeStartProvider.notifier).state = null;
        ref.read(marqueeProvider.notifier).state =
            const MarqueeState();
      }
    }
  },
  onPointerCancel: (event) {
    if (event.kind == PointerDeviceKind.mouse) {
      final start = ref.read(mouseMarqueeStartProvider);
      if (start != null) {
        ref.read(selectionProvider.notifier).cancelMarquee();
        ref.read(mouseMarqueeStartProvider.notifier).state = null;
        ref.read(marqueeProvider.notifier).state =
            const MarqueeState();
      }
    }
  },
  onPointerSignal: (event) {
    if (event is PointerScrollEvent &&
        event.kind == PointerDeviceKind.mouse) {
      controller.zoomAt(event.scrollDelta.dy, event.position);
    }
  },
  child: GestureDetector(
```

Add `kPrimaryButton` import. At top of file, ensure:

```dart
import 'package:flutter/gestures.dart' show PointerScrollEvent;
```

(Already imports `dart:ui` show PointerDeviceKind and `package:flutter/services.dart`. Need to add `flutter/gestures.dart`. Check: `PointerScrollEvent` is in `package:flutter/gestures.dart`. `kPrimaryButton` is in `dart:ui` — but re-exported by material. Add `import 'package:flutter/gestures.dart';`.)

- [ ] **Step 4: Wire space-hold in the `Focus.onKeyEvent`**

Current (lines 215-227):
```dart
onKeyEvent: (node, event) {
  if (!editable) return KeyEventResult.ignored;
  if (event is KeyDownEvent) {
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      ...
    }
  }
  return KeyEventResult.ignored;
},
```

Replace with:

```dart
onKeyEvent: (node, event) {
  if (!editable) return KeyEventResult.ignored;
  if (event is KeyDownEvent) {
    if (event.logicalKey == LogicalKeyboardKey.space) {
      ref.read(spaceHeldProvider.notifier).state = true;
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      final current = ref.read(selectionProvider).current
          .where((id) => id != 'entrypoint')
          .toList();
      if (current.isNotEmpty) {
        for (final id in current) {
          deleteNode(id);
        }
        return KeyEventResult.handled;
      }
    }
  } else if (event is KeyUpEvent) {
    if (event.logicalKey == LogicalKeyboardKey.space) {
      ref.read(spaceHeldProvider.notifier).state = false;
      return KeyEventResult.handled;
    }
  }
  return KeyEventResult.ignored;
},
```

- [ ] **Step 5: Analyze**

Run: `~/flutter/bin/flutter analyze`
Expected: no warnings.

- [ ] **Step 6: Build verify**

Run: `~/flutter/bin/flutter build web --release`
Expected: succeeds.

- [ ] **Step 7: Manual test (web)**

Open dev preview at `trailhead-dev.rancidgrandmas.online`. Verify:
- Plain left-drag on empty grid → marquee box appears, follows cursor.
- Nodes under marquee highlight (selection glow).
- Release → selection stays committed.
- Drag again over more nodes → adds to existing set (union).
- Tap empty → clears.
- Hold Spacebar + drag → pans.
- Scroll wheel → zooms toward cursor.
- Tap single node → selects only that node.
- Plain-drag on a node → still drags that node.

- [ ] **Step 8: Commit**

```bash
git add frontend/lib/widgets/canvas/graph_canvas.dart \
        frontend/lib/providers/marquee_provider.dart
git commit -m "feat: mouse plain-drag marquee, space-hold pan, wheel zoom"
```

---

### Task 9: Touch long-press-drag marquee

**Files:**
- Modify: `frontend/lib/widgets/canvas/graph_canvas.dart` (background `GestureDetector`)

- [ ] **Step 1: Add touch long-press-drag handlers**

In the background `GestureDetector` (currently at lines 234-249), add `onLongPressStart/MoveUpdate/End`. The gesture arena resolves long-press over `onScaleStart` once the long-press deadline passes (~500ms by default).

Add a `touchMarqueeStartProvider` to `frontend/lib/providers/marquee_provider.dart`:

```dart
final touchMarqueeStartProvider = StateProvider<Offset?>((ref) => null);
```

In `graph_canvas.dart`, modify the `GestureDetector`:

```dart
child: GestureDetector(
  behavior: HitTestBehavior.translucent,
  onTap: () {
    ref.read(selectionProvider.notifier).clear();
    ref.read(operatorPickerProvider.notifier).state = null;
  },
  onLongPressStart: editable
      ? (details) {
          ref.read(touchMarqueeStartProvider.notifier).state =
              details.globalPosition;
          ref.read(selectionProvider.notifier).beginMarquee();
        }
      : null,
  onLongPressMoveUpdate: editable
      ? (details) {
          final start = ref.read(touchMarqueeStartProvider);
          if (start != null) {
            updateMarqueeFromScreenRect(
                Rect.fromPoints(start, details.globalPosition));
          }
        }
      : null,
  onLongPressEnd: editable
      ? (_) {
          ref.read(selectionProvider.notifier).commitMarquee();
          ref.read(touchMarqueeStartProvider.notifier).state = null;
          ref.read(marqueeProvider.notifier).state =
              const MarqueeState();
        }
      : null,
  onScaleStart: (details) {
    controller.beginScale(details.focalPoint);
  },
  onScaleUpdate: (details) {
    controller.updateScale(details.scale, details.focalPoint);
  },
  onScaleEnd: (_) {
    controller.endScale();
  },
  child: Container(
```

- [ ] **Step 2: Analyze**

Run: `~/flutter/bin/flutter analyze`
Expected: no warnings.

- [ ] **Step 3: Build verify**

Run: `~/flutter/bin/flutter build web --release`
Expected: succeeds.

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/widgets/canvas/graph_canvas.dart \
        frontend/lib/providers/marquee_provider.dart
git commit -m "feat: touch long-press-drag marquee"
```

---

### Task 10: Group drag (move entire selection set)

**Files:**
- Modify: `frontend/lib/widgets/canvas/graph_canvas.dart` (lines 288-292 for preview, 388-407 for commit)

- [ ] **Step 1: Update live preview (lines 289-292)**

Current:
```dart
final isSelected = selectedNodeId == node.id;
final isDragging = draggingNodeId == node.id;
final displayX = isDragging ? node.x + dragOffset.dx : node.x;
final displayY = isDragging ? node.y + dragOffset.dy : node.y;
```

Replace with:

```dart
final current = selection.current;
final isSelected = current.contains(node.id);
final inGroupDrag = draggingNodeId != null &&
    current.contains(draggingNodeId!) &&
    current.length > 1 &&
    current.contains(node.id);
final isDragging = inGroupDrag || (draggingNodeId == node.id);
final displayX = isDragging ? node.x + dragOffset.dx : node.x;
final displayY = isDragging ? node.y + dragOffset.dy : node.y;
```

- [ ] **Step 2: Update `onPanEnd` commit (lines 388-407)**

Current:
```dart
onPanEnd: editable
    ? (_) {
        if (draggingNodeId == node.id) {
          final offset = ref.read(dragOffsetProvider);
          final h = nodeHeight(node.kind, outputs: node.outputs);
          final snappedX = _snap(node.x + offset.dx);
          final snappedY = _snapCenter(node.y + offset.dy + h / 2) - h / 2;
          final newNodes = workflow.nodes.map((n) {
            if (n.id == node.id) {
              return n.copyWith(x: snappedX, y: snappedY);
            }
            return n;
          }).toList();
          ref.read(workflowProvider.notifier).state =
              workflow.copyWith(nodes: newNodes);
          ref.read(draggingNodeIdProvider.notifier).state = null;
          ref.read(dragOffsetProvider.notifier).state = Offset.zero;
        }
      }
    : null,
```

Replace with:

```dart
onPanEnd: editable
    ? (_) {
        if (draggingNodeId != node.id) return;
        final offset = ref.read(dragOffsetProvider);
        final cur = ref.read(selectionProvider).current;
        final isGroupDrag =
            cur.length > 1 && cur.contains(node.id);

        List<WorkflowNode> newNodes;
        if (isGroupDrag) {
          newNodes = workflow.nodes.map((n) {
            if (!cur.contains(n.id)) return n;
            final h = n.height;
            final snappedX = _snap(n.x + offset.dx);
            final snappedY =
                _snapCenter(n.y + offset.dy + h / 2) - h / 2;
            return n.copyWith(x: snappedX, y: snappedY);
          }).toList();
        } else {
          final h = node.height;
          final snappedX = _snap(node.x + offset.dx);
          final snappedY =
              _snapCenter(node.y + offset.dy + h / 2) - h / 2;
          newNodes = workflow.nodes.map((n) {
            return n.id == node.id
                ? n.copyWith(x: snappedX, y: snappedY)
                : n;
          }).toList();
        }
        ref.read(workflowProvider.notifier).state =
            workflow.copyWith(nodes: newNodes);
        ref.read(draggingNodeIdProvider.notifier).state = null;
        ref.read(dragOffsetProvider.notifier).state = Offset.zero;
      }
    : null,
```

- [ ] **Step 3: Analyze**

Run: `~/flutter/bin/flutter analyze`
Expected: no warnings.

- [ ] **Step 4: Build verify**

Run: `~/flutter/bin/flutter build web --release`
Expected: succeeds.

- [ ] **Step 5: Manual test**

In dev preview:
- Marquee-select 3 nodes.
- Plain-drag any of the 3 → all 3 move together.
- Drag a single non-selected node → only that node moves.
- Marquee-select 2 nodes, then click a 3rd (single-select replaces) → drag → only that 1 moves.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/widgets/canvas/graph_canvas.dart
git commit -m "feat: group drag for multi-selected nodes"
```

---

### Task 11: Final integration test + full build

**Files:**
- Modify: `frontend/test/widget_test.dart` (extend or new file)

- [ ] **Step 1: Add an integration test for selection union across marquees**

Create `frontend/test/marquee_integration_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/selection_notifier.dart';

void main() {
  test('marquee union across two simulated drags accumulates', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final n = container.read(selectionProvider.notifier);

    // Simulate first marquee: covers nodes A, B
    n.beginMarquee();
    n.updateMarqueeLive({'A', 'B'});
    expect(container.read(selectionProvider).current, {'A', 'B'});
    n.commitMarquee();
    expect(container.read(selectionProvider).current, {'A', 'B'});

    // Second marquee covers C only (A, B no longer in rect)
    n.beginMarquee();
    n.updateMarqueeLive({'C'});
    expect(container.read(selectionProvider).current, {'A', 'B', 'C'});
    n.commitMarquee();
    expect(container.read(selectionProvider).current, {'A', 'B', 'C'});
  });

  test('marquee shrink within single drag removes from live', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final n = container.read(selectionProvider.notifier);

    n.beginMarquee();
    n.updateMarqueeLive({'A', 'B', 'C'});
    n.updateMarqueeLive({'A', 'B'});
    n.updateMarqueeLive({'A'});
    expect(container.read(selectionProvider).current, {'A'});
    n.commitMarquee();
    expect(container.read(selectionProvider).current, {'A'});
  });
}
```

- [ ] **Step 2: Run full test suite**

Run: `~/flutter/bin/flutter test`
Expected: all pass.

- [ ] **Step 3: Run analyzer**

Run: `~/flutter/bin/flutter analyze`
Expected: no issues.

- [ ] **Step 4: Build web release**

Run: `~/flutter/bin/flutter build web --release`
Expected: succeeds.

- [ ] **Step 5: Final manual smoke test**

In dev preview, verify all behaviors from spec §1:
- Mouse: plain-drag marquee, space-hold pan, wheel zoom, plain-drag on selected = group drag, plain-drag on unselected = single drag, tap empty = clear, tap node = select single, Delete key removes all selected.
- Touch: 1-finger pan, 2-finger pinch zoom, long-press-drag marquee, tap empty clear.

- [ ] **Step 6: Commit**

```bash
git add frontend/test/marquee_integration_test.dart
git commit -m "test: marquee union + shrink integration tests"
```

---

## Self-Review Notes

**Spec coverage:**
- §1 Gesture model: Tasks 5 (space), 8 (mouse marquee/pan/wheel), 9 (touch marquee), 4 (wheel zoom).
- §2 Selection state: Task 2.
- §3 Marquee render + hit-test: Task 3 (painter), Task 7 (overlay), Task 8 (hit-test helper).
- §4 Node rect helper dedup: Task 1.
- §5 Group drag: Task 10.
- §6 Canvas controller `zoomAt`: Task 4.
- Migration of `selectedNodeProvider`: Task 6.
- Testing: per-task + Task 11 integration.

**Placeholder scan:** none.

**Type consistency:** `SelectionNotifier.selectOne/toggleOne/beginMarquee/updateMarqueeLive/commitMarquee/cancelMarquee/removeIds/clear` — used identically across Tasks 2, 6, 8, 9. `node.width`/`node.height`/`node.rect` — used in Tasks 1, 8, 10. `zoomAt(delta, cursor)` — defined Task 4, used Task 8. `MarqueeState(screenRect, active)` — defined Task 3, used Tasks 7-9.
