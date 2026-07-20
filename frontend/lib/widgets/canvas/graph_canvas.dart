import 'dart:async' show Timer;
import 'dart:math' show Random;
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/gestures.dart' show PointerScrollEvent, kPrimaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/node_catalog.dart';
import '../../models/workflow_document.dart';
import '../../models/workflow_edge.dart';
import '../../models/workflow_node.dart';
import '../../providers/canvas_controller.dart';
import '../../providers/mode_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/mock_data.dart';
import '../../providers/operator_picker_provider.dart';
import '../../providers/thrt_provider.dart';
import '../../services/thrt_api.dart' show FlowStatus, InstalledNode;
import '../../theme/tokens.dart';
import '../../widgets/mode_rail.dart';
import '../../providers/connection_drag_provider.dart';
import '../../providers/scissors_provider.dart';
import '../../providers/invalid_drop_flash_provider.dart';
import '../../utils/connection_validator.dart';
import 'connection_painter.dart';
import 'cut_path_painter.dart';
import 'dot_grid_painter.dart';
import 'marquee_painter.dart';
import 'mode_flash_overlay.dart';
import 'operator_picker.dart';
import '../../providers/marquee_provider.dart';
import '../../providers/node_menu_provider.dart';
import '../../providers/selection_notifier.dart';
import 'node_context_menu.dart';
import '../icons.dart';
import 'routing_node.dart';
import 'worker_node.dart';
import 'canvas_toolbar.dart';

final _idRng = Random();

/// Short base36 id (`n_x4k9q2` / `e_8z1m0p`), collision-checked against
/// [existing]. Replaces the long `node_${millis}_${rand4}` form.
String _shortId(String prefix, Set<String> existing) {
  const chars = '0123456789abcdefghijklmnopqrstuvwxyz';
  for (var attempt = 0; attempt < 100; attempt++) {
    final id =
        '$prefix${List.generate(6, (_) => chars[_idRng.nextInt(36)]).join()}';
    if (!existing.contains(id)) return id;
  }
  // Pathological collision streak — timestamp fallback stays unique.
  return '$prefix${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
}

class GraphCanvas extends ConsumerStatefulWidget {
  GraphCanvas({super.key});

  @override
  ConsumerState<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends ConsumerState<GraphCanvas>
    with SingleTickerProviderStateMixin {
  static const double _snapGrid = 32.0;
  static const Duration _snapDuration = Duration(milliseconds: 200);
  static const double _doubleTapMaxDist = 20.0;
  static const int _doubleTapMaxMs = 300;
  static const double _dragThreshold = 5.0;

  DateTime? _firstTapDownTime;
  Offset? _firstTapDownPos;
  Timer? _tapTimer;
  Timer? _statusTimer;
  bool _doubleClickDragActive = false;
  Offset? _doubleClickStartPos;

  /// Single source of truth for *rendered* node positions. Nodes and the
  /// connection painter both read this map, so arrows stay glued to nodes
  /// throughout the post-drag snap glide. Logical positions live on
  /// `workflow.nodes`; this map eases toward them via [_snapController].
  final Map<String, Offset> _renderedPos = {};
  Map<String, Offset> _snapFrom = {};
  Map<String, Offset> _snapTo = {};
  Object? _posWorkflowKey;
  late final AnimationController _snapController = AnimationController(
    vsync: this,
    duration: _snapDuration,
  )..addListener(_onSnapTick);

  void _onSnapTick() {
    final t = Curves.easeOutCubic.transform(_snapController.value);
    setState(() {
      _snapTo.forEach((id, to) {
        final from = _snapFrom[id] ?? to;
        _renderedPos[id] = Offset.lerp(from, to, t)!;
      });
    });
  }

  static bool _offsetMapEquals(Map<String, Offset> a, Map<String, Offset> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  /// Reconciles [_renderedPos] with logical node positions. Call every build.
  ///
  /// - New nodes seed instantly (no fly-in from 0,0).
  /// - Dragged nodes track logical+dragOffset directly (no animation).
  /// - Any other rendered≠logical gap starts (or retargets) one shared
  ///   snap-glide animation, so nodes and arrows move in lockstep.
  void _syncRenderedPositions(
    WorkflowSummary workflow,
    String? draggingNodeId,
    Offset dragOffset,
    Set<String> selectedIds,
  ) {
    if (_posWorkflowKey != workflow.id) {
      _posWorkflowKey = workflow.id;
      _renderedPos.clear();
      _snapFrom = {};
      _snapTo = {};
      _snapController.stop();
    }

    final draggedIds = <String>{};
    if (draggingNodeId != null) {
      if (selectedIds.contains(draggingNodeId) && selectedIds.length > 1) {
        draggedIds.addAll(selectedIds);
      } else {
        draggedIds.add(draggingNodeId);
      }
    }

    final ids = workflow.nodes.map((n) => n.id).toSet();
    _renderedPos.removeWhere((id, _) => !ids.contains(id));

    final newFrom = <String, Offset>{};
    final newTo = <String, Offset>{};
    for (final n in workflow.nodes) {
      final logical = Offset(n.x, n.y);
      if (draggedIds.contains(n.id)) {
        _renderedPos[n.id] = logical + dragOffset;
        continue;
      }
      final rendered = _renderedPos.putIfAbsent(n.id, () => logical);
      final target = _snapTo[n.id];
      if (target != null && target == logical && rendered != logical) {
        // Already gliding toward this logical position.
        newFrom[n.id] = _snapFrom[n.id] ?? rendered;
        newTo[n.id] = logical;
        continue;
      }
      if (rendered != logical) {
        newFrom[n.id] = rendered;
        newTo[n.id] = logical;
      }
    }

    if (newTo.isEmpty) {
      if (_snapTo.isNotEmpty) {
        _snapFrom = {};
        _snapTo = {};
        _snapController.stop();
      }
    } else if (!_offsetMapEquals(newTo, _snapTo) ||
        !_snapController.isAnimating) {
      _snapFrom = newFrom;
      _snapTo = newTo;
      _snapController.forward(from: 0.0);
    }
  }

  /// Node ids with an inject currently in flight (cap spinner state).
  final Set<String> _injecting = {};

  /// 1s poll of the current workflow's runtime status while in Active mode.
  /// The jobs-based poll above only fires for running jobs; this one keeps
  /// `flowStatusProvider` fresh for the visible flow regardless.
  Timer? _activeStatusTimer;

  double _snap(double value) => (value / _snapGrid).round() * _snapGrid;
  double _snapCenter(double center) => (center / _snapGrid).round() * _snapGrid;

  /// Actor kinds reported by the runtime feed edge classification.
  static void _syncInstalledActorKinds(List<InstalledNode> nodes) {
    WorkflowNodeKind.installedActorKinds = {
      for (final n in nodes)
        if (n.actor) n.type,
    };
  }

  @override
  void initState() {
    super.initState();
    // Seed classification with whatever the provider already has (the
    // ref.listen in build only fires on subsequent changes).
    ref.read(installedNodesProvider).whenData(_syncInstalledActorKinds);
    _syncActiveStatusTimer(ref.read(modeProvider));
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _statusTimer?.cancel();
    _activeStatusTimer?.cancel();
    _snapController.dispose();
    super.dispose();
  }

  static double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLen2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLen2 == 0) return (p - a).distance;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / abLen2).clamp(0.0, 1.0);
    final closest = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    return (p - closest).distance;
  }

  void _cancelTapTimer() {
    _tapTimer?.cancel();
    _tapTimer = null;
  }

  void _resetDoubleClick() {
    _cancelTapTimer();
    _firstTapDownTime = null;
    _firstTapDownPos = null;
    _doubleClickDragActive = false;
    _doubleClickStartPos = null;
  }

  void _beginMarquee(Offset startPos) {
    ref.read(selectionProvider.notifier).beginMarquee();
    ref.read(marqueeProvider.notifier).state = MarqueeState(
      screenRect: Rect.fromPoints(startPos, startPos),
      active: true,
    );
  }

  void _updateMarquee(Offset startPos, Offset currentPos) {
    final viewport = ref.read(canvasControllerProvider);
    final workflow = ref.read(canvasWorkflowProvider);
    final screenRect = Rect.fromPoints(startPos, currentPos);
    final world = Rect.fromPoints(
      (screenRect.topLeft - viewport.pan) / viewport.zoom,
      (screenRect.bottomRight - viewport.pan) / viewport.zoom,
    );
    final hits =
        workflow.nodes
            .where((n) => n.rect.overlaps(world))
            .map((n) => n.id)
            .toSet();
    ref.read(selectionProvider.notifier).updateMarqueeLive(hits);
    ref.read(marqueeProvider.notifier).state = MarqueeState(
      screenRect: screenRect,
      active: true,
    );
  }

  void _commitMarquee() {
    ref.read(selectionProvider.notifier).commitMarquee();
    ref.read(marqueeProvider.notifier).state = MarqueeState();
  }

  void _cancelMarquee() {
    ref.read(selectionProvider.notifier).cancelMarquee();
    ref.read(marqueeProvider.notifier).state = MarqueeState();
  }

  void _openNodeDrawer(String nodeId) {
    ref.read(selectedNodeIdProvider.notifier).state = nodeId;
    ref.read(nodeDrawerOpenProvider.notifier).state = true;
  }

  Future<void> _pollStatus() async {
    final jobs = ref.read(jobsProvider).valueOrNull ?? [];
    final runningFlows =
        jobs.where((j) => j.status == 'running').map((j) => j.flowName).toSet();
    if (runningFlows.isEmpty) return;
    try {
      final api = ref.read(thrtApiProvider);
      final updates = <String, FlowStatus>{};
      for (final name in runningFlows) {
        updates[name] = await api.status(name);
      }
      final current = ref.read(flowStatusProvider);
      final cleaned = Map<String, FlowStatus>.from(current)
        ..removeWhere((k, _) => !runningFlows.contains(k));
      cleaned.addAll(updates);
      ref.read(flowStatusProvider.notifier).state = cleaned;
    } catch (e) {
      debugPrint('status poll failed: $e');
    }
  }

  /// Poll runtime status of the currently selected workflow and merge it
  /// into `flowStatusProvider` (drives badges, drawer trigger, cap button).
  Future<void> _pollActiveFlow() async {
    final wf = ref.read(canvasWorkflowProvider);
    if (wf.name.isEmpty) return;
    try {
      final status = await ref.read(thrtApiProvider).status(wf.name);
      ref.read(flowStatusProvider.notifier).state =
          Map<String, FlowStatus>.from(ref.read(flowStatusProvider))
            ..[wf.name] = status;
    } catch (e) {
      debugPrint('active flow status poll failed: $e');
    }
  }

  void _syncActiveStatusTimer(AppMode mode) {
    _activeStatusTimer?.cancel();
    _activeStatusTimer = null;
    if (mode == AppMode.active) {
      _pollActiveFlow();
      _activeStatusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _pollActiveFlow();
      });
    }
  }

  /// Trigger button on a `source.inject` node cap (active mode, deployed
  /// flow). Uses the shared inject buffer so drawer edits apply.
  Future<void> _triggerNodeInject(WorkflowNode node) async {
    if (_injecting.contains(node.id)) return;
    final wf = ref.read(canvasWorkflowProvider);
    final code =
        ref.read(injectBufferProvider)[injectBufferKey(ref, node.id)] ??
        node.payloadCode ??
        '';
    setState(() => _injecting.add(node.id));
    try {
      await triggerNodeInject(ref, wf.name, node.id, code,
          isExpr: node.payloadIsExpr);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('inject failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _injecting.remove(node.id));
    }
  }

  void _toggleScissors() {
    final current = ref.read(scissorsModeProvider);
    final next = !current;
    ref.read(scissorsModeProvider.notifier).state = next;
    if (next) {
      ref.read(selectionProvider.notifier).clear();
    }
    final currentFlash = ref.read(flashOverlayProvider);
    ref.read(flashOverlayProvider.notifier).state = (
      mode: next ? FlashMode.scissors : FlashMode.cursor,
      id: (currentFlash?.id ?? 0) + 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep actor classification in sync with runtime-installed modules so
    // edges into harness/tool/etc. get message semantics.
    ref.listen(installedNodesProvider, (_, next) {
      next.whenData(_syncInstalledActorKinds);
    });
    final viewport = ref.watch(canvasControllerProvider);
    final controller = ref.read(canvasControllerProvider.notifier);
    // Render the selected job's snapshot in Active mode, the live workflow
    // otherwise. Mutations route through updateCanvasWorkflow.
    final workflow = ref.watch(canvasWorkflowProvider);
    final selection = ref.watch(selectionProvider);
    final hoveredNodeId = ref.watch(hoveredNodeProvider);
    final draggingNodeId = ref.watch(draggingNodeIdProvider);
    final dragOffset = ref.watch(dragOffsetProvider);
    final pickerAnchor = ref.watch(operatorPickerProvider);
    final mode = ref.watch(modeProvider);
    final editable = mode == AppMode.build;
    // Active mode allows repositioning nodes on the job snapshot (never
    // persisted to the workflow). Requires a job document to exist.
    final selectedJob = ref.watch(selectedJobProvider);
    final hasJobDoc = selectedJob != null &&
        ref.watch(jobDocumentsProvider).containsKey(selectedJob.id);
    final repositionable =
        editable || (mode == AppMode.active && hasJobDoc);
    final menuAnchor = ref.watch(nodeMenuProvider);
    final connectionDrag = ref.watch(connectionDragProvider);
    final scissors = ref.watch(scissorsModeProvider);
    final cutPath = ref.watch(cutPathProvider);
    final flash = ref.watch(flashOverlayProvider);
    final spaceHeld = ref.watch(spaceHeldProvider);

    // Reconcile rendered node positions with logical ones; starts the shared
    // snap-glide animation when nodes were just repositioned. Nodes and
    // arrows both read _renderedPos, so they move in lockstep.
    _syncRenderedPositions(
      workflow,
      draggingNodeId,
      dragOffset,
      selection.current,
    );

    // Sync in-place workflow edits to the document model (canvas viewport cache).
    // Backend persistence is handled by the autosave listener in main.dart.
    ref.listen<WorkflowSummary>(workflowProvider, (prev, next) {
      if (prev != null && prev.id == next.id) {
        final vp = ref.read(canvasControllerProvider);
        ref.read(documentsProvider.notifier).update((docs) {
          final m = Map<String, WorkflowDocument>.from(docs);
          m[next.id] = WorkflowDocument(workflow: next, viewport: vp);
          return m;
        });
      }
    });

    // Sync viewport movements to the active document.
    ref.listen<CanvasViewport>(canvasControllerProvider, (prev, next) {
      final wf = ref.read(workflowProvider);
      ref.read(documentsProvider.notifier).update((docs) {
        final m = Map<String, WorkflowDocument>.from(docs);
        m[wf.id] = WorkflowDocument(workflow: wf, viewport: next);
        return m;
      });
    });

    ref.listen(jobsProvider, (prev, next) {
      _statusTimer?.cancel();
      final jobs = next.valueOrNull ?? [];
      if (jobs.any((j) => j.status == 'running')) {
        _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _pollStatus();
        });
      }
    });

    ref.listen(modeProvider, (_, next) => _syncActiveStatusTimer(next));

    final flowStatuses = ref.watch(flowStatusProvider);

    void showPicker(Offset worldPos, String sourceId, {int? sourcePort}) {
      if (!editable) return;
      final screenX = worldPos.dx * viewport.zoom + viewport.pan.dx;
      final screenY = worldPos.dy * viewport.zoom + viewport.pan.dy;
      ref.read(operatorPickerProvider.notifier).state = PickerAnchor(
        screenPos: Offset(screenX, screenY),
        sourceNodeId: sourceId,
        sourcePort: sourcePort,
      );
    }

    void showPickerStandalone() {
      if (!editable) return;
      final size = MediaQuery.of(context).size;
      const widgetWidth = 240.0;
      final screenX = size.width / 2 - widgetWidth / 2;
      final screenY = size.height / 2 - 80;
      ref.read(operatorPickerProvider.notifier).state = PickerAnchor(
        screenPos: Offset(screenX, screenY),
      );
    }

    // ── Connection drag helpers ───────────────────────────────────────────

    Offset _branchOutputWorldPos(WorkflowNode node, int? port) {
      if (port == null || node.outputs.isEmpty) {
        return Offset(node.x + node.width, node.y + node.height / 2);
      }
      final y =
          node.y +
          WorkflowNode.branchPadY +
          port * WorkflowNode.branchRowHeight +
          WorkflowNode.branchRowHeight / 2;
      return Offset(node.x + node.width, y);
    }

    Offset _handleWorldPos(WorkflowNode node, bool isOutput, int? port) {
      if (isOutput) {
        if (node.kind == 'function' &&
            node.expr == null &&
            node.outputs.isNotEmpty) {
          return _branchOutputWorldPos(node, port);
        }
        return Offset(node.x + node.width, node.y + node.height / 2);
      }
      return Offset(node.x, node.y + node.height / 2);
    }

    ({String nodeId, bool isOutput, int? port})? _findNearestHandle(
      Offset worldPos,
      bool seekingInput,
      String sourceNodeId,
    ) {
      const screenThreshold = 24.0;
      final worldThreshold = screenThreshold / viewport.zoom;
      // Whole node body counts as a hit target (touch: finger covers the
      // small connector). Slightly inflated so grazing the edge still snaps.
      final bodyInflate = 8.0 / viewport.zoom;
      ({String nodeId, bool isOutput, int? port})? best;
      double bestDist = worldThreshold;

      for (final node in workflow.nodes) {
        if (node.id == sourceNodeId) continue;

        if (seekingInput) {
          if (!node.hasInput) continue;
          if (node.rect.inflate(bodyInflate).contains(worldPos)) {
            return (nodeId: node.id, isOutput: false, port: null);
          }
          final pos = _handleWorldPos(node, false, null);
          final dist = (pos - worldPos).distance;
          if (dist < bestDist) {
            bestDist = dist;
            best = (nodeId: node.id, isOutput: false, port: null);
          }
        } else {
          // Seeking output — function ports only
          if (!node.hasOutput) continue;
          final isBranch =
              node.kind == 'function' &&
              node.expr == null &&
              node.outputs.isNotEmpty;
          if (node.rect.inflate(bodyInflate).contains(worldPos)) {
            if (isBranch) {
              final row =
                  ((worldPos.dy -
                              node.y -
                              WorkflowNode.branchPadY) /
                          WorkflowNode.branchRowHeight)
                      .floor()
                      .clamp(0, node.outputs.length - 1);
              return (nodeId: node.id, isOutput: true, port: row);
            }
            return (nodeId: node.id, isOutput: true, port: null);
          }
          if (isBranch) {
            for (var p = 0; p < node.outputs.length; p++) {
              final pos = _handleWorldPos(node, true, p);
              final dist = (pos - worldPos).distance;
              if (dist < bestDist) {
                bestDist = dist;
                best = (nodeId: node.id, isOutput: true, port: p);
              }
            }
          } else {
            final pos = _handleWorldPos(node, true, null);
            final dist = (pos - worldPos).distance;
            if (dist < bestDist) {
              bestDist = dist;
              best = (nodeId: node.id, isOutput: true, port: null);
            }
          }
        }
      }
      return best;
    }

    void _startConnectionDrag(
      String sourceNodeId,
      bool sourceIsOutput,
      Offset worldPos,
      int? sourcePort,
    ) {
      ref.read(connectionDragProvider.notifier).state = ConnectionDragState(
        sourceNodeId: sourceNodeId,
        sourcePort: sourcePort,
        sourceIsOutput: sourceIsOutput,
        currentWorldPos: worldPos,
      );
    }

    void _updateConnectionDrag(Offset worldPos, String sourceNodeId) {
      final drag = ref.read(connectionDragProvider);
      if (drag == null) return;
      final seekingInput = drag.sourceIsOutput;
      final snap = _findNearestHandle(worldPos, seekingInput, sourceNodeId);
      ref.read(connectionDragProvider.notifier).state = ConnectionDragState(
        sourceNodeId: drag.sourceNodeId,
        sourcePort: drag.sourcePort,
        sourceIsOutput: drag.sourceIsOutput,
        currentWorldPos: worldPos,
        targetNodeId: snap?.nodeId,
        targetIsOutput: snap?.isOutput,
        targetPort: snap?.port,
      );
    }

    void _endConnectionDrag(String sourceNodeId) {
      final drag = ref.read(connectionDragProvider);
      if (drag == null) return;

      if (drag.targetNodeId != null) {
        final current = ref.read(canvasWorkflowProvider);
        final nodeMap = {for (final n in current.nodes) n.id: n};
        final alreadyExists = current.connections.any(
          (e) =>
              e.from == sourceNodeId &&
              e.to == drag.targetNodeId &&
              e.sourcePort == drag.sourcePort,
        );

        if (!alreadyExists) {
          final newEdge = WorkflowConnection(
            id: _shortId(
              'e_',
              current.connections.map((e) => e.id).toSet(),
            ),
            from: sourceNodeId,
            to: drag.targetNodeId!,
            sourcePort: drag.sourcePort,
          );

          if (ConnectionValidator.wouldBeValid(
            newEdge,
            current.connections,
            nodeMap,
          )) {
            updateCanvasWorkflow(
              ref,
              (w) => w.copyWith(connections: [...w.connections, newEdge]),
            );
          } else {
            final dropPos = drag.currentWorldPos;
            ref
                .read(invalidDropFlashProvider.notifier)
                .state = InvalidDropFlash(
              worldPos: dropPos,
              id: DateTime.now().millisecondsSinceEpoch,
            );
            Timer(invalidDropFlashDuration, () {
              ref.read(invalidDropFlashProvider.notifier).state = null;
            });
          }
        }
      }

      ref.read(connectionDragProvider.notifier).state = null;
    }

    void updateMarqueeFromScreenRect(Rect screenRect) {
      final world = Rect.fromPoints(
        (screenRect.topLeft - viewport.pan) / viewport.zoom,
        (screenRect.bottomRight - viewport.pan) / viewport.zoom,
      );
      final hits =
          workflow.nodes
              .where((n) => n.rect.overlaps(world))
              .map((n) => n.id)
              .toSet();
      ref.read(selectionProvider.notifier).updateMarqueeLive(hits);
      ref.read(marqueeProvider.notifier).state = MarqueeState(
        screenRect: screenRect,
        active: true,
      );
    }

    void addNode(NodeEntry entry) {
      final sourceId = pickerAnchor?.sourceNodeId;
      final id = _shortId('n_', workflow.nodes.map((n) => n.id).toSet());

      if (sourceId == null) {
        final vp = ref.read(canvasControllerProvider);
        final screenSize = MediaQuery.of(context).size;
        final centerX = (-vp.pan.dx + screenSize.width / 2) / vp.zoom;
        final centerY = (-vp.pan.dy + screenSize.height / 2) / vp.zoom;
        final newNode = WorkflowNode(
          id: id,
          kind: entry.kind,
          label: entry.label,
          x: _snap(centerX - 100),
          y: _snap(centerY - 18),
          outputs:
              entry.kind == 'function' && !entry.isTransform
                  ? WorkflowNode.defaultBranchOutputs
                  : const [],
          expr: entry.isTransform ? entry.templateExpr : null,
        );
        updateCanvasWorkflow(
          ref,
          (w) => w.copyWith(nodes: [...w.nodes, newNode]),
        );
        ref.read(selectionProvider.notifier).selectOne(id);
        ref.read(operatorPickerProvider.notifier).state = null;
        return;
      }

      final source = workflow.nodes.firstWhere(
        (n) => n.id == sourceId,
        orElse: () => workflow.nodes.first,
      );

      final sourceHeight = source.height;
      final newNodeHeight =
          WorkflowNode(id: '', kind: entry.kind, label: '', x: 0, y: 0).height;
      final snappedX = _snap(source.x + 220);
      final snappedY =
          _snapCenter(source.y + sourceHeight / 2) - newNodeHeight / 2;
      final newNode = WorkflowNode(
        id: id,
        kind: entry.kind,
        label: entry.label,
        x: snappedX,
        y: snappedY,
        outputs:
            entry.kind == 'function' && !entry.isTransform
                ? WorkflowNode.defaultBranchOutputs
                : const [],
        expr: entry.isTransform ? entry.templateExpr : null,
      );

      final edge = WorkflowConnection(
        id: _shortId('e_', workflow.connections.map((e) => e.id).toSet()),
        from: sourceId,
        to: id,
        sourcePort: pickerAnchor?.sourcePort,
      );

      updateCanvasWorkflow(
        ref,
        (w) => w.copyWith(
          nodes: [...w.nodes, newNode],
          connections: [...w.connections, edge],
        ),
      );
      ref.read(selectionProvider.notifier).selectOne(id);
      ref.read(operatorPickerProvider.notifier).state = null;
    }

    void deleteNode(String nodeId) {
      final currentWorkflow = ref.read(canvasWorkflowProvider);
      final newNodes =
          currentWorkflow.nodes.where((n) => n.id != nodeId).toList();
      final newEdges =
          currentWorkflow.connections
              .where((e) => e.from != nodeId && e.to != nodeId)
              .toList();
      updateCanvasWorkflow(
        ref,
        (w) => w.copyWith(nodes: newNodes, connections: newEdges),
      );
      ref.read(selectionProvider.notifier).removeIds([nodeId]);
      if (hoveredNodeId == nodeId) {
        ref.read(hoveredNodeProvider.notifier).state = null;
      }
      ref.read(nodeMenuProvider.notifier).state = null;
    }

    void duplicateNode(String nodeId) {
      final node = workflow.nodes.firstWhere((n) => n.id == nodeId);
      final id = _shortId('n_', workflow.nodes.map((n) => n.id).toSet());
      final newNode = WorkflowNode(
        id: id,
        kind: node.kind,
        label: node.label,
        x: _snap(node.x + 220),
        y: _snap(node.y + 32),
        outputs: node.outputs,
      );
      updateCanvasWorkflow(
        ref,
        (w) => w.copyWith(nodes: [...w.nodes, newNode]),
      );
      ref.read(selectionProvider.notifier).selectOne(id);
      ref.read(nodeMenuProvider.notifier).state = null;
    }

    void collapseNode(String nodeId) {
      final parentEdge = workflow.connections
          .cast<WorkflowConnection?>()
          .firstWhere((e) => e?.to == nodeId, orElse: () => null);
      final childEdges =
          workflow.connections.where((e) => e.from == nodeId).toList();

      final newEdges =
          workflow.connections
              .where((e) => e.to != nodeId && e.from != nodeId)
              .toList();

      if (parentEdge != null) {
        final taken = workflow.connections.map((e) => e.id).toSet();
        for (final child in childEdges) {
          final id = _shortId('e_', taken);
          taken.add(id);
          newEdges.add(
            WorkflowConnection(
              id: id,
              from: parentEdge.from,
              to: child.to,
              sourcePort: parentEdge.sourcePort,
            ),
          );
        }
      }

      final newNodes = workflow.nodes.where((n) => n.id != nodeId).toList();

      updateCanvasWorkflow(
        ref,
        (w) => w.copyWith(nodes: newNodes, connections: newEdges),
      );

      ref.read(selectionProvider.notifier).removeIds([nodeId]);
      ref.read(nodeMenuProvider.notifier).state = null;
    }

    ref.watch(settingsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = constraints.biggest;
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (!editable) return KeyEventResult.ignored;
            // Never handle canvas shortcuts while a text field owns primary
            // focus (on web, key events still bubble to ancestor Focus nodes;
            // EditableText deletes characters via the text-input channel, not
            // the raw key path — so without this guard backspace in any field
            // deletes the selected nodes).
            final pfCtx = FocusManager.instance.primaryFocus?.context;
            if (pfCtx != null &&
                (pfCtx.widget is EditableText ||
                    pfCtx.findAncestorWidgetOfExactType<EditableText>() !=
                        null)) {
              return KeyEventResult.ignored;
            }
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.space) {
                ref.read(spaceHeldProvider.notifier).state = true;
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.delete ||
                  event.logicalKey == LogicalKeyboardKey.backspace) {
                // Node deletion is build-mode only.
                if (!editable) return KeyEventResult.ignored;
                final current =
                    ref
                        .read(selectionProvider)
                        .current
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
          child: ClipRect(
            child: Stack(
              children: [
                // Background layer: grid + edges + empty space with Listener
                Positioned.fill(
                  child: Listener(
                    onPointerDown: (event) {
                      if (event.buttons != kPrimaryButton) return;
                      if (spaceHeld) return;
                      if (!editable) {
                        // Active/history: tap on empty space clears the
                        // single-selection (hides the node details column).
                        final worldPos =
                            (event.localPosition - viewport.pan) /
                            viewport.zoom;
                        final overNode = workflow.nodes.any(
                          (n) => n.rect.contains(worldPos),
                        );
                        if (overNode) return;
                        ref.read(selectionProvider.notifier).clear();
                        ref.read(selectedNodeIdProvider.notifier).state = null;
                        ref.read(operatorPickerProvider.notifier).state = null;
                        return;
                      }
                      final worldPos =
                          (event.localPosition - viewport.pan) / viewport.zoom;
                      final overNode = workflow.nodes.any(
                        (n) => n.rect.contains(worldPos),
                      );
                      if (overNode) {
                        _resetDoubleClick();
                        return;
                      }

                      final now = DateTime.now();
                      if (_firstTapDownTime != null &&
                          _firstTapDownPos != null &&
                          now.difference(_firstTapDownTime!).inMilliseconds <=
                              _doubleTapMaxMs &&
                          (event.localPosition - _firstTapDownPos!).distance <=
                              _doubleTapMaxDist) {
                        _cancelTapTimer();
                        _doubleClickStartPos = event.localPosition;
                        _firstTapDownTime = null;
                        _firstTapDownPos = null;
                        return;
                      }

                      _firstTapDownTime = now;
                      _firstTapDownPos = event.localPosition;
                      _cancelTapTimer();
                      _tapTimer = Timer(
                        const Duration(milliseconds: _doubleTapMaxMs),
                        () {
                          if (mounted) {
                            ref.read(selectionProvider.notifier).clear();
                            ref.read(operatorPickerProvider.notifier).state =
                                null;
                          }
                          _resetDoubleClick();
                        },
                      );
                    },
                    onPointerMove: (event) {
                      if (event.buttons != kPrimaryButton) return;
                      if (spaceHeld) {
                        controller.pan(event.delta);
                        return;
                      }

                      if (_firstTapDownPos != null &&
                          !_doubleClickDragActive &&
                          _doubleClickStartPos == null &&
                          (event.localPosition - _firstTapDownPos!).distance >
                              _dragThreshold) {
                        _resetDoubleClick();
                        return;
                      }

                      if (_doubleClickStartPos != null &&
                          !_doubleClickDragActive) {
                        if ((event.localPosition - _doubleClickStartPos!)
                                .distance >
                            _dragThreshold) {
                          _doubleClickDragActive = true;
                          _beginMarquee(_doubleClickStartPos!);
                        }
                      }

                      if (_doubleClickDragActive &&
                          _doubleClickStartPos != null) {
                        _updateMarquee(
                          _doubleClickStartPos!,
                          event.localPosition,
                        );
                      }
                    },
                    onPointerUp: (event) {
                      if (_doubleClickDragActive) {
                        _commitMarquee();
                        _resetDoubleClick();
                        return;
                      }

                      if (_doubleClickStartPos != null) {
                        if (editable) _toggleScissors();
                        _resetDoubleClick();
                        return;
                      }
                    },
                    onPointerCancel: (_) {
                      if (_doubleClickDragActive) {
                        _cancelMarquee();
                      }
                      _resetDoubleClick();
                    },
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent &&
                          (event.kind == PointerDeviceKind.mouse ||
                              event.kind == PointerDeviceKind.trackpad)) {
                        controller.zoomAt(
                          event.scrollDelta.dy,
                          event.localPosition,
                        );
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onScaleStart:
                          scissors && editable
                              ? null
                              : (details) {
                                if (_doubleClickDragActive) return;
                                controller.beginScale(details.localFocalPoint);
                              },
                      onScaleUpdate:
                          scissors && editable
                              ? null
                              : (details) {
                                if (_doubleClickDragActive) return;
                                controller.updateScale(
                                  details.scale,
                                  details.localFocalPoint,
                                );
                              },
                      onScaleEnd:
                          scissors && editable
                              ? null
                              : (_) {
                                if (_doubleClickDragActive) return;
                                controller.endScale();
                              },
                      onPanStart:
                          scissors && editable
                              ? (details) {
                                final worldPos = Offset(
                                  (details.localPosition.dx - viewport.pan.dx) /
                                      viewport.zoom,
                                  (details.localPosition.dy - viewport.pan.dy) /
                                      viewport.zoom,
                                );
                                ref.read(cutPathProvider.notifier).state = [
                                  worldPos,
                                ];
                              }
                              : null,
                      onPanUpdate:
                          scissors && editable
                              ? (details) {
                                final worldPos = Offset(
                                  (details.localPosition.dx - viewport.pan.dx) /
                                      viewport.zoom,
                                  (details.localPosition.dy - viewport.pan.dy) /
                                      viewport.zoom,
                                );
                                ref.read(cutPathProvider.notifier).state = [
                                  ...ref.read(cutPathProvider),
                                  worldPos,
                                ];
                              }
                              : null,
                      onPanEnd:
                          scissors && editable
                              ? (_) {
                                final path = ref.read(cutPathProvider);
                                if (path.length >= 2) {
                                  final threshold = 6.0 / viewport.zoom;
                                  final toDelete = <String>{};

                                  for (final edge in workflow.connections) {
                                    final source = workflow.nodes.firstWhere(
                                      (n) => n.id == edge.from,
                                    );
                                    final target = workflow.nodes.firstWhere(
                                      (n) => n.id == edge.to,
                                    );

                                    Offset exitPoint(WorkflowNode node) {
                                      final pos = Offset(node.x, node.y);
                                      return switch (node.kind) {
                                        'worker' => Offset(
                                          pos.dx + node.width,
                                          pos.dy + node.height / 2,
                                        ),
                                        'fan' => Offset(
                                          pos.dx + node.width,
                                          pos.dy + node.height / 2,
                                        ),
                                        _ => Offset(
                                          pos.dx + node.width,
                                          pos.dy + node.height / 2,
                                        ),
                                      };
                                    }

                                    Offset entryPoint(WorkflowNode node) {
                                      final pos = Offset(node.x, node.y);
                                      return Offset(
                                        pos.dx,
                                        pos.dy + node.height / 2,
                                      );
                                    }

                                    final p0 = exitPoint(source);
                                    final p3 = entryPoint(target);
                                    final dx = (p3.dx - p0.dx).abs();
                                    final controlLen = dx.clamp(40.0, 150.0);
                                    final p1 = Offset(
                                      p0.dx + controlLen,
                                      p0.dy,
                                    );
                                    final p2 = Offset(
                                      p3.dx - controlLen,
                                      p3.dy,
                                    );

                                    for (var i = 0; i <= 20; i++) {
                                      final t = i / 20.0;
                                      final u = 1.0 - t;
                                      final tt = t * t;
                                      final uu = u * u;
                                      final uuu = uu * u;
                                      final ttt = tt * t;
                                      final bx =
                                          uuu * p0.dx +
                                          3 * uu * t * p1.dx +
                                          3 * u * tt * p2.dx +
                                          ttt * p3.dx;
                                      final by =
                                          uuu * p0.dy +
                                          3 * uu * t * p1.dy +
                                          3 * u * tt * p2.dy +
                                          ttt * p3.dy;

                                      var hit = false;
                                      for (
                                        var j = 0;
                                        j < path.length - 1;
                                        j++
                                      ) {
                                        final dist = _pointToSegmentDistance(
                                          Offset(bx, by),
                                          path[j],
                                          path[j + 1],
                                        );
                                        if (dist < threshold) {
                                          hit = true;
                                          break;
                                        }
                                      }
                                      if (hit) {
                                        toDelete.add(
                                          '${edge.from}\u2192${edge.to}',
                                        );
                                        break;
                                      }
                                    }
                                  }

                                  if (toDelete.isNotEmpty) {
                                    updateCanvasWorkflow(
                                      ref,
                                      (w) => w.copyWith(
                                        connections:
                                            w.connections
                                                .where(
                                                  (e) =>
                                                      !toDelete.contains(
                                                        '${e.from}\u2192${e.to}',
                                                      ),
                                                )
                                                .toList(),
                                      ),
                                    );
                                  }
                                }
                                ref.read(cutPathProvider.notifier).state =
                                    const [];
                              }
                              : null,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.hearthGradient,
                        ),
                        child: Stack(
                          children: [
                            // Dot grid
                            Positioned.fill(
                              child: CustomPaint(
                                painter: DotGridPainter(
                                  zoom: viewport.zoom,
                                  pan: viewport.pan,
                                ),
                              ),
                            ),
                            // World transform for edges
                            Transform.translate(
                              offset: viewport.pan,
                              child: Transform.scale(
                                scale: viewport.zoom,
                                alignment: Alignment.topLeft,
                                child: UnboundedHitStack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Connection edges (behind nodes)
                                    Positioned.fill(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTapDown:
                                            scissors && editable
                                                ? (details) {
                                                  final tapWorld =
                                                      details.localPosition;
                                                  const threshold = 18.0;
                                                  String? nearestEdgeKey;
                                                  double nearestDist =
                                                      threshold;

                                                  for (final edge
                                                      in workflow.connections) {
                                                    final source = workflow
                                                        .nodes
                                                        .firstWhere(
                                                          (n) =>
                                                              n.id == edge.from,
                                                        );
                                                    final target = workflow
                                                        .nodes
                                                        .firstWhere(
                                                          (n) =>
                                                              n.id == edge.to,
                                                        );

                                                    // Rendered positions (same as painter)
                                                    Offset nodePos(
                                                      WorkflowNode node,
                                                    ) {
                                                      return _renderedPos[node
                                                              .id] ??
                                                          Offset(
                                                            node.x,
                                                            node.y,
                                                          );
                                                    }

                                                    Offset exitPoint(
                                                      WorkflowNode node,
                                                    ) {
                                                      final pos = nodePos(node);
                                                      return switch (node
                                                          .kind) {
                                                        'worker' => Offset(
                                                          pos.dx + node.width,
                                                          pos.dy +
                                                              node.height / 2,
                                                        ),
                                                        'fan' => Offset(
                                                          pos.dx + node.width,
                                                          pos.dy +
                                                              node.height / 2,
                                                        ),
                                                        _ => Offset(
                                                          pos.dx + node.width,
                                                          pos.dy +
                                                              node.height / 2,
                                                        ),
                                                      };
                                                    }

                                                    Offset entryPoint(
                                                      WorkflowNode node,
                                                    ) {
                                                      final pos = nodePos(node);
                                                      return Offset(
                                                        pos.dx,
                                                        pos.dy +
                                                            node.height / 2,
                                                      );
                                                    }

                                                    final p0 = exitPoint(
                                                      source,
                                                    );
                                                    final p3 = entryPoint(
                                                      target,
                                                    );
                                                    final dx =
                                                        (p3.dx - p0.dx).abs();
                                                    final controlLen = dx.clamp(
                                                      40.0,
                                                      150.0,
                                                    );
                                                    final p1 = Offset(
                                                      p0.dx + controlLen,
                                                      p0.dy,
                                                    );
                                                    final p2 = Offset(
                                                      p3.dx - controlLen,
                                                      p3.dy,
                                                    );

                                                    // Sample bezier curve
                                                    for (
                                                      var i = 0;
                                                      i <= 20;
                                                      i++
                                                    ) {
                                                      final t = i / 20.0;
                                                      final u = 1.0 - t;
                                                      final tt = t * t;
                                                      final uu = u * u;
                                                      final uuu = uu * u;
                                                      final ttt = tt * t;
                                                      final bx =
                                                          uuu * p0.dx +
                                                          3 * uu * t * p1.dx +
                                                          3 * u * tt * p2.dx +
                                                          ttt * p3.dx;
                                                      final by =
                                                          uuu * p0.dy +
                                                          3 * uu * t * p1.dy +
                                                          3 * u * tt * p2.dy +
                                                          ttt * p3.dy;
                                                      final dist =
                                                          (tapWorld.dx - bx)
                                                              .abs() +
                                                          (tapWorld.dy - by)
                                                              .abs();
                                                      if (dist < nearestDist) {
                                                        nearestDist = dist;
                                                        nearestEdgeKey =
                                                            '${edge.from}\u2192${edge.to}';
                                                      }
                                                    }
                                                  }

                                                  if (nearestEdgeKey != null) {
                                                    updateCanvasWorkflow(
                                                      ref,
                                                      (w) => w.copyWith(
                                                        connections:
                                                            w.connections
                                                                .where(
                                                                  (e) =>
                                                                      '${e.from}\u2192${e.to}' !=
                                                                      nearestEdgeKey,
                                                                )
                                                                .toList(),
                                                      ),
                                                    );
                                                  }
                                                }
                                                : null,
                                         child: CustomPaint(
                                           painter: ConnectionPainter(
                                             nodes: workflow.nodes,
                                             connections: workflow.connections,
                                             renderedPositions: Map.of(
                                               _renderedPos,
                                             ),
                                             connectionDrag: connectionDrag,
                                            invalidDropPos:
                                                ref
                                                    .watch(
                                                      invalidDropFlashProvider,
                                                    )
                                                    ?.worldPos,
                                          ),
                                          size: Size.infinite,
                                        ),
                                      ),
                                    ),
                                    // Cut path overlay (scissors mode drag line)
                                    if (cutPath.isNotEmpty)
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: CutPathPainter(
                                            points: cutPath,
                                          ),
                                          size: Size.infinite,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Nodes layer: same world transform, NOT under Listener
                Transform.translate(
                  offset: viewport.pan,
                  child: Transform.scale(
                    scale: viewport.zoom,
                    alignment: Alignment.topLeft,
                    child: UnboundedHitStack(
                      clipBehavior: Clip.none,
                      children: [
                         ...workflow.nodes.map((node) {
                           final current = selection.current;
                           final isSelected = current.contains(node.id);
                           final rendered =
                               _renderedPos[node.id] ??
                               Offset(node.x, node.y);
                           final displayX = rendered.dx;
                           final displayY = rendered.dy;

                          final nodeWidget =
                              node.kind == 'function' && node.expr == null
                                  ? BranchNode(
                                    node: node,
                                    selected: isSelected,
                                    onEnter: () {
                                      ref
                                          .read(hoveredNodeProvider.notifier)
                                          .state = node.id;
                                    },
                                    onExit: () {
                                      ref
                                          .read(hoveredNodeProvider.notifier)
                                          .state = (hoveredNodeId == node.id)
                                              ? null
                                              : hoveredNodeId;
                                    },
                                  )
                                  : WorkerNode(
                                    node: node,
                                    selected: isSelected,
                                    icon:
                                        node.kind == 'source.inject'
                                            ? TrailheadIconData.play
                                            : node.kind == 'delay'
                                                ? TrailheadIconData.stopwatch
                                                : node.expr != null
                                                    ? TrailheadIconData.terminal
                                                    : TrailheadIconData.bot,
                                    triggerable:
                                        node.kind == 'source.inject' &&
                                            !editable &&
                                            (flowStatuses[workflow.name]
                                                    ?.deployed ??
                                                false),
                                    triggering:
                                        _injecting.contains(node.id),
                                    onEnter: () {
                                      ref
                                          .read(hoveredNodeProvider.notifier)
                                          .state = node.id;
                                    },
                                    onExit: () {
                                      ref
                                          .read(hoveredNodeProvider.notifier)
                                          .state = (hoveredNodeId == node.id)
                                              ? null
                                              : hoveredNodeId;
                                    },
                                  );

                           return Positioned(
                             key: ValueKey('${workflow.id}_${node.id}'),
                             left: displayX,
                             top: displayY,
                             child: MultiHitStack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: (details) {
                                    if (scissors && editable) {
                                      deleteNode(node.id);
                                      return;
                                    }
                                    // Trigger cap: left 30px of an inject
                                    // node on a deployed flow (active mode).
                                    // Routed here because a nested detector
                                    // on the cap loses the gesture arena to
                                    // this parent node detector.
                                    if (node.kind == 'source.inject' &&
                                        !editable &&
                                        (flowStatuses[workflow.name]
                                                ?.deployed ??
                                            false) &&
                                        details.localPosition.dx <= 30) {
                                      _triggerNodeInject(node);
                                      return;
                                    }
                                    if (!editable) {
                                      // Active/history: single-select drives
                                      // the node drawer. Multi-select is a
                                      // build-mode-only feature.
                                      ref
                                          .read(selectionProvider.notifier)
                                          .selectOne(node.id);
                                      ref
                                          .read(
                                            selectedNodeIdProvider.notifier,
                                          )
                                          .state = node.id;
                                      return;
                                    }
                                    ref
                                        .read(selectionProvider.notifier)
                                        .toggleOne(node.id);
                                    if (!isSelected) {
                                      ref
                                          .read(operatorPickerProvider.notifier)
                                          .state = null;
                                    }
                                  },
                                  onDoubleTap: () => _openNodeDrawer(node.id),
                                  onLongPressStart:
                                      isSelected && editable
                                          ? (details) {
                                            ref
                                                .read(nodeMenuProvider.notifier)
                                                .state = NodeMenuAnchor(
                                              nodeId: node.id,
                                            );
                                          }
                                          : null,
                                  onSecondaryTapDown:
                                      isSelected && editable
                                          ? (details) {
                                            ref
                                                .read(nodeMenuProvider.notifier)
                                                .state = NodeMenuAnchor(
                                              nodeId: node.id,
                                            );
                                          }
                                          : null,
                                  onPanStart:
                                      repositionable && !scissors
                                          ? (_) {
                                            ref
                                                .read(
                                                  draggingNodeIdProvider
                                                      .notifier,
                                                )
                                                .state = node.id;
                                            ref
                                                .read(
                                                  dragOffsetProvider.notifier,
                                                )
                                                .state = Offset.zero;
                                          }
                                          : null,
                                  onPanUpdate:
                                      repositionable && !scissors
                                          ? (details) {
                                            if (draggingNodeId == node.id) {
                                              ref
                                                  .read(
                                                    dragOffsetProvider.notifier,
                                                  )
                                                  .state += details.delta;
                                            }
                                          }
                                          : null,
                                  onPanEnd:
                                      repositionable && !scissors
                                          ? (_) {
                                            if (draggingNodeId != node.id)
                                              return;
                                            final offset = ref.read(
                                              dragOffsetProvider,
                                            );
                                            final cur =
                                                ref
                                                    .read(selectionProvider)
                                                    .current;
                                            final currentWorkflow = ref.read(
                                              canvasWorkflowProvider,
                                            );
                                            final isGroupDrag =
                                                cur.length > 1 &&
                                                cur.contains(node.id);

                                            final newNodes =
                                                currentWorkflow.nodes.map((n) {
                                                  final shouldMove =
                                                      isGroupDrag
                                                          ? cur.contains(n.id)
                                                          : (n.id == node.id);
                                                  if (!shouldMove) return n;
                                                  final h = n.height;
                                                  final snappedX = _snap(
                                                    n.x + offset.dx,
                                                  );
                                                  final snappedY =
                                                      _snapCenter(
                                                        n.y + offset.dy + h / 2,
                                                      ) -
                                                      h / 2;
                                                  return n.copyWith(
                                                    x: snappedX,
                                                    y: snappedY,
                                                  );
                                                }).toList();

                                            updateCanvasWorkflow(
                                              ref,
                                              (w) =>
                                                  w.copyWith(nodes: newNodes),
                                            );
                                            ref
                                                .read(
                                                  draggingNodeIdProvider
                                                      .notifier,
                                                )
                                                .state = null;
                                            ref
                                                .read(
                                                  dragOffsetProvider.notifier,
                                                )
                                                .state = Offset.zero;
                                          }
                                          : null,
                                  onPanCancel:
                                      repositionable && !scissors
                                          ? () {
                                            ref
                                                .read(
                                                  draggingNodeIdProvider
                                                      .notifier,
                                                )
                                                .state = null;
                                            ref
                                                .read(
                                                  dragOffsetProvider.notifier,
                                                )
                                                .state = Offset.zero;
                                          }
                                          : null,
                                  child: nodeWidget,
                                ),
                                if (isSelected && editable && node.hasInput)
                                  Positioned(
                                    left: -44.0,
                                    top: node.height / 2 - 44.0,
                                    child: _InputHandle(
                                      onPanStart:
                                          editable
                                              ? (_) {
                                                final worldPos =
                                                    _handleWorldPos(
                                                      node,
                                                      false,
                                                      null,
                                                    );
                                                _startConnectionDrag(
                                                  node.id,
                                                  false,
                                                  worldPos,
                                                  null,
                                                );
                                              }
                                              : null,
                                      onPanUpdate:
                                          editable
                                              ? (details) {
                                                final drag = ref.read(
                                                  connectionDragProvider,
                                                );
                                                if (drag != null) {
                                                  _updateConnectionDrag(
                                                    drag.currentWorldPos +
                                                        details.delta,
                                                    node.id,
                                                  );
                                                }
                                              }
                                              : null,
                                      onPanEnd:
                                          editable
                                              ? (_) =>
                                                  _endConnectionDrag(node.id)
                                              : null,
                                      onPanCancel:
                                          editable
                                              ? () =>
                                                  ref
                                                      .read(
                                                        connectionDragProvider
                                                            .notifier,
                                                      )
                                                      .state = null
                                              : null,
                                    ),
                                  ),
                                if (isSelected &&
                                    editable &&
                                    node.kind == 'function' &&
                                    node.expr == null)
                                  ...node.outputs.isNotEmpty
                                      ? node.outputs.asMap().entries.map((e) {
                                        final port = e.key;
                                        final top =
                                            BranchNode.padY +
                                            port * BranchNode.rowHeight;
                                        return Positioned(
                                          left: BranchNode.width - 22.0,
                                          top: top,
                                          child: _OutputHandle(
                                            targetWidth: 44.0,
                                            targetHeight: BranchNode.rowHeight,
                                            onTap:
                                                () => showPicker(
                                                  Offset(
                                                    displayX + BranchNode.width,
                                                    displayY +
                                                        BranchNode.padY +
                                                        port *
                                                            BranchNode
                                                                .rowHeight +
                                                        BranchNode.rowHeight /
                                                            2,
                                                  ),
                                                  node.id,
                                                  sourcePort: port,
                                                ),
                                            onPanStart:
                                                editable
                                                    ? (_) {
                                                      final worldPos =
                                                          _handleWorldPos(
                                                            node,
                                                            true,
                                                            port,
                                                          );
                                                      _startConnectionDrag(
                                                        node.id,
                                                        true,
                                                        worldPos,
                                                        port,
                                                      );
                                                    }
                                                    : null,
                                            onPanUpdate:
                                                editable
                                                    ? (details) {
                                                      final drag = ref.read(
                                                        connectionDragProvider,
                                                      );
                                                      if (drag != null) {
                                                        _updateConnectionDrag(
                                                          drag.currentWorldPos +
                                                              details.delta,
                                                          node.id,
                                                        );
                                                      }
                                                    }
                                                    : null,
                                            onPanEnd:
                                                editable
                                                    ? (_) => _endConnectionDrag(
                                                      node.id,
                                                    )
                                                    : null,
                                            onPanCancel:
                                                editable
                                                    ? () =>
                                                        ref
                                                            .read(
                                                              connectionDragProvider
                                                                  .notifier,
                                                            )
                                                            .state = null
                                                    : null,
                                          ),
                                        );
                                      })
                                      : [
                                        Positioned(
                                          left: BranchNode.width - 44.0,
                                          top: node.height / 2 - 44.0,
                                          child: _OutputHandle(
                                            onTap:
                                                () => showPicker(
                                                  Offset(
                                                    displayX + BranchNode.width,
                                                    displayY + node.height / 2,
                                                  ),
                                                  node.id,
                                                ),
                                            onPanStart:
                                                editable
                                                    ? (_) {
                                                      final worldPos =
                                                          _handleWorldPos(
                                                            node,
                                                            true,
                                                            null,
                                                          );
                                                      _startConnectionDrag(
                                                        node.id,
                                                        true,
                                                        worldPos,
                                                        null,
                                                      );
                                                    }
                                                    : null,
                                            onPanUpdate:
                                                editable
                                                    ? (details) {
                                                      final drag = ref.read(
                                                        connectionDragProvider,
                                                      );
                                                      if (drag != null) {
                                                        _updateConnectionDrag(
                                                          drag.currentWorldPos +
                                                              details.delta,
                                                          node.id,
                                                        );
                                                      }
                                                    }
                                                    : null,
                                            onPanEnd:
                                                editable
                                                    ? (_) => _endConnectionDrag(
                                                      node.id,
                                                    )
                                                    : null,
                                            onPanCancel:
                                                editable
                                                    ? () =>
                                                        ref
                                                            .read(
                                                              connectionDragProvider
                                                                  .notifier,
                                                            )
                                                            .state = null
                                                    : null,
                                          ),
                                        ),
                                      ],
                                if (isSelected &&
                                    editable &&
                                    !(node.kind == 'function' &&
                                        node.expr == null) &&
                                    node.hasOutput)
                                  Positioned(
                                    left: node.width - 44.0,
                                    top: node.height / 2 - 44.0,
                                    child: _OutputHandle(
                                      onTap:
                                          () => showPicker(
                                            Offset(
                                              displayX + node.width,
                                              displayY + node.height / 2,
                                            ),
                                            node.id,
                                          ),
                                      onPanStart:
                                          editable
                                              ? (_) {
                                                final worldPos =
                                                    _handleWorldPos(
                                                      node,
                                                      true,
                                                      null,
                                                    );
                                                _startConnectionDrag(
                                                  node.id,
                                                  true,
                                                  worldPos,
                                                  null,
                                                );
                                              }
                                              : null,
                                      onPanUpdate:
                                          editable
                                              ? (details) {
                                                final drag = ref.read(
                                                  connectionDragProvider,
                                                );
                                                if (drag != null) {
                                                  _updateConnectionDrag(
                                                    drag.currentWorldPos +
                                                        details.delta,
                                                    node.id,
                                                  );
                                                }
                                              }
                                              : null,
                                      onPanEnd:
                                          editable
                                              ? (_) =>
                                                  _endConnectionDrag(node.id)
                                              : null,
                                      onPanCancel:
                                          editable
                                              ? () =>
                                                  ref
                                                      .read(
                                                        connectionDragProvider
                                                            .notifier,
                                                      )
                                                      .state = null
                                              : null,
                                    ),
                                  ),
                                if (flowStatuses.containsKey(workflow.name))
                                  Builder(
                                    builder: (context) {
                                      final status =
                                          flowStatuses[workflow.name]!;
                                      final nodeStats = status.nodes[node.id];
                                      if (nodeStats == null)
                                        return const SizedBox.shrink();
                                      return Positioned(
                                        top: -12,
                                        right: -6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.bg2,
                                            border: Border.all(
                                              color: AppColors.border1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x40000000),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            'in:${nodeStats.msgsIn} out:${nodeStats.msgsOut}',
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 9,
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                // Screen-space marquee overlay
                Consumer(
                  builder: (_, ref, __) {
                    final m = ref.watch(marqueeProvider);
                    if (!m.active) return const SizedBox.shrink();
                    return Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: MarqueePainter(m.screenRect),
                        ),
                      ),
                    );
                  },
                ),
                CanvasToolbar(canvasSize: canvasSize),
                // Operator picker — rendered via root Overlay (outside the
                // canvas ClipRect) so it is never clipped by the graph region
                // and paints above sibling panels (e.g. the portrait drawer).
                if (pickerAnchor != null)
                  _PickerOverlayHost(
                    onSelect: addNode,
                    onClose: () {
                      ref.read(operatorPickerProvider.notifier).state = null;
                    },
                  ),
                if (menuAnchor != null)
                  Builder(
                    builder: (context) {
                      final menuNode = workflow.nodes
                          .cast<WorkflowNode?>()
                          .firstWhere(
                            (n) => n!.id == menuAnchor.nodeId,
                            orElse: () => null,
                          );
                      if (menuNode == null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(nodeMenuProvider.notifier).state = null;
                        });
                        return const SizedBox.shrink();
                      }
                      final isMenuNodeDragging = draggingNodeId == menuNode.id;
                      final menuDx =
                          isMenuNodeDragging
                              ? menuNode.x + dragOffset.dx
                              : menuNode.x;
                      final menuDy =
                          isMenuNodeDragging
                              ? menuNode.y + dragOffset.dy
                              : menuNode.y;
                      final screenPos = Offset(
                        menuDx * viewport.zoom + viewport.pan.dx,
                        menuDy * viewport.zoom + viewport.pan.dy,
                      );
                      return NodeContextMenu(
                        anchor: screenPos,
                        canDuplicate: true,
                        onDuplicate: () => duplicateNode(menuAnchor.nodeId),
                        onCollapse: () => collapseNode(menuAnchor.nodeId),
                        onDelete: () {
                          final selected =
                              ref.read(selectionProvider).current.toList();
                          if (selected.isNotEmpty) {
                            for (final id in selected) {
                              deleteNode(id);
                            }
                          }
                        },
                        onInspect: () {
                          _openNodeDrawer(menuAnchor.nodeId);
                          ref.read(nodeMenuProvider.notifier).state = null;
                        },
                        onClose: () {
                          ref.read(nodeMenuProvider.notifier).state = null;
                        },
                      );
                    },
                  ),
                // Mode indicator badge
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      border: Border.all(color: AppColors.border1),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      scissors ? 'tool \u00b7 scissors' : 'layout \u00b7 graph',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppColors.fg2,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                // Mode-change flash overlay
                if (flash != null)
                  ModeFlashOverlay(
                    key: ValueKey(flash.id),
                    mode: flash.mode,
                    onDismiss: () {
                      ref.read(flashOverlayProvider.notifier).state = null;
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Hosts the [OperatorPicker] in the root [Overlay] instead of the canvas
/// stack. The canvas is wrapped in a [ClipRect], so an in-stack picker is
/// clipped to the graph region and painted over by sibling panels (portrait
/// drawer). A root overlay entry escapes both: the picker is never clipped
/// and sits above drawers — including when the iOS keyboard pushes the
/// drawer up into the canvas area.
///
/// The host itself is a zero-hit [Positioned.fill] inside the canvas stack;
/// its render box spans the canvas region, giving the overlay entry the
/// canvas's global origin for anchor placement.
class _PickerOverlayHost extends StatefulWidget {
  final void Function(NodeEntry entry) onSelect;
  final VoidCallback onClose;

  const _PickerOverlayHost({required this.onSelect, required this.onClose});

  @override
  State<_PickerOverlayHost> createState() => _PickerOverlayHostState();
}

class _PickerOverlayHostState extends State<_PickerOverlayHost> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertEntry());
  }

  void _insertEntry() {
    if (!mounted || _entry != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final hostContext = context;
    _entry = OverlayEntry(
      builder: (_) {
        // Recomputed on every entry build (host rebuilds mark it dirty), so
        // the anchor tracks the canvas origin across resizes.
        final box = hostContext.findRenderObject() as RenderBox?;
        final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
        return Material(
          type: MaterialType.transparency,
          child: OperatorPicker(
            anchor: origin + const Offset(16, 16),
            onSelect: widget.onSelect,
            onClose: widget.onClose,
          ),
        );
      },
    );
    overlay.insert(_entry!);
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _entry?.markNeedsBuild();
    return const Positioned.fill(
      child: IgnorePointer(child: SizedBox.shrink()),
    );
  }
}

class _OutputHandle extends StatelessWidget {
  final VoidCallback onTap;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;
  final double targetWidth;
  final double targetHeight;

  _OutputHandle({
    required this.onTap,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.targetWidth = 88.0,
    this.targetHeight = 88.0,
  });

  @override
  Widget build(BuildContext context) {
    // Direct world-space sizing so hit area exactly matches visual area.
    final width = targetWidth;
    final height = targetHeight;
    const dotSize = 12.0;
    const borderWidth = 2.0;
    const ringSpread = 1.0;
    const glowBlur = 8.0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      child: Container(
        width: width,
        height: height,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.bg1, width: borderWidth),
            boxShadow: [
              // crisp accent ring
              BoxShadow(
                color: AppColors.accent,
                blurRadius: 0,
                spreadRadius: ringSpread,
              ),
              // soft glow
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.5),
                blurRadius: glowBlur,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputHandle extends StatelessWidget {
  final VoidCallback? onTap;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;

  _InputHandle({
    this.onTap,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
  });

  @override
  Widget build(BuildContext context) {
    const size = 88.0;
    const dotSize = 12.0;
    const borderWidth = 2.0;
    const ringSpread = 1.0;
    const glowBlur = 8.0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      child: Container(
        width: size,
        height: size,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.bg1, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent,
                blurRadius: 0,
                spreadRadius: ringSpread,
              ),
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.5),
                blurRadius: glowBlur,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A [Stack] whose hit-test is not bounded by its own size.
///
/// Flutter's default [RenderStack.hitTest] rejects pointers that fall
/// outside the Stack's layout bounds. That breaks nodes positioned at
/// negative world coordinates (left of the Y axis or above the X axis),
/// because the transformed pointer lands outside the Stack's local bounds.
///
/// This widget overrides [hitTest] to test children regardless of the
/// Stack's own size, while keeping normal layout and paint clipping
/// (the outer [ClipRect] still clips painting to the viewport).
class UnboundedHitStack extends Stack {
  UnboundedHitStack({
    super.key,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
    super.children,
  });

  @override
  RenderStack createRenderObject(BuildContext context) {
    return _RenderUnboundedHitStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderStack renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }
}

class _RenderUnboundedHitStack extends RenderStack {
  _RenderUnboundedHitStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// A [Stack] that tests **all** children for hit-test, not just the first one.
///
/// Flutter's default [RenderStack.hitTestChildren] walks children in reverse
/// paint order and returns `true` on the first hit. That blocks overlapping
/// siblings (e.g. a large invisible touch-target on top of a smaller body)
/// from ever receiving pointer events.
///
/// This widget tests every child and returns `true` if *any* child was hit,
/// letting all overlapping recognizers enter the gesture arena.
class MultiHitStack extends Stack {
  MultiHitStack({
    super.key,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
    super.children,
  });

  @override
  RenderStack createRenderObject(BuildContext context) {
    return _RenderMultiHitStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderStack renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }
}

class _RenderMultiHitStack extends RenderStack {
  _RenderMultiHitStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    bool anyHit = false;
    RenderBox? child = lastChild;
    while (child != null) {
      final StackParentData childParentData =
          child.parentData! as StackParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: Offset(childParentData.left ?? 0.0, childParentData.top ?? 0.0),
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) anyHit = true;
      child = childParentData.previousSibling as RenderBox?;
    }
    return anyHit;
  }
}
