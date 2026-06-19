import 'dart:math' show Random;
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/gestures.dart' show PointerScrollEvent, kPrimaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow_document.dart';
import '../../models/workflow_edge.dart';
import '../../models/workflow_node.dart';
import '../../providers/canvas_controller.dart';
import '../../providers/mode_provider.dart';
import '../../providers/mock_data.dart';
import '../../providers/operator_picker_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/mode_rail.dart';
import '../../providers/connection_drag_provider.dart';
import '../../providers/scissors_provider.dart';
import 'connection_painter.dart';
import 'cut_path_painter.dart';
import 'dot_grid_painter.dart';
import 'marquee_painter.dart';
import 'operator_picker.dart';
import '../../providers/marquee_provider.dart';
import '../../providers/node_menu_provider.dart';
import '../../providers/selection_notifier.dart';
import 'node_context_menu.dart';
import 'entrypoint_node.dart';
import 'fan_node.dart';
import 'routing_node.dart';
import 'worker_node.dart';
import 'canvas_toolbar.dart';

class GraphCanvas extends ConsumerWidget {
  const GraphCanvas({super.key});

  static const double _snapGrid = 32.0;
  static const Duration _snapDuration = Duration(milliseconds: 200);

  double _snap(double value) => (value / _snapGrid).round() * _snapGrid;
  double _snapCenter(double center) => (center / _snapGrid).round() * _snapGrid;

  static double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLen2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLen2 == 0) return (p - a).distance;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / abLen2).clamp(0.0, 1.0);
    final closest = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    return (p - closest).distance;
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewport = ref.watch(canvasControllerProvider);
    final controller = ref.read(canvasControllerProvider.notifier);
    final workflow = ref.watch(workflowProvider);
    final selection = ref.watch(selectionProvider);
    final hoveredNodeId = ref.watch(hoveredNodeProvider);
    final draggingNodeId = ref.watch(draggingNodeIdProvider);
    final dragOffset = ref.watch(dragOffsetProvider);
    final pickerAnchor = ref.watch(operatorPickerProvider);
    final mode = ref.watch(modeProvider);
    final editable = mode == AppMode.build;
    final menuAnchor = ref.watch(nodeMenuProvider);
    final connectionDrag = ref.watch(connectionDragProvider);
    final scissors = ref.watch(scissorsModeProvider);
    final cutPath = ref.watch(cutPathProvider);
    final spaceHeld = ref.watch(spaceHeldProvider);

    // Sync in-place workflow edits to the document model and workflow list.
    ref.listen<WorkflowSummary>(workflowProvider, (prev, next) {
      if (prev != null && prev.id == next.id) {
        final vp = ref.read(canvasControllerProvider);
        ref.read(documentsProvider.notifier).update((docs) {
          final m = Map<String, WorkflowDocument>.from(docs);
          m[next.id] = WorkflowDocument(workflow: next, viewport: vp);
          return m;
        });
        ref.read(workflowsProvider.notifier).update((list) {
          return list.map((w) => w.id == next.id ? next : w).toList();
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

    // ── Connection drag helpers ───────────────────────────────────────────

    Offset _branchOutputWorldPos(WorkflowNode node, int? port) {
      if (port == null || node.outputs.isEmpty) {
        return Offset(node.x + node.width, node.y + node.height / 2);
      }
      final y = node.y +
          WorkflowNode.branchPadY +
          port * WorkflowNode.branchRowHeight +
          WorkflowNode.branchRowHeight / 2;
      return Offset(node.x + node.width, y);
    }

    Offset _handleWorldPos(WorkflowNode node, bool isOutput, int? port) {
      if (isOutput) {
        return switch (node.kind) {
          'worker' => Offset(node.x + node.width, node.y + node.height / 2),
          'fan'    => Offset(node.x + node.width, node.y + node.height / 2),
          _        => _branchOutputWorldPos(node, port),
        };
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
      ({String nodeId, bool isOutput, int? port})? best;
      double bestDist = worldThreshold;

      for (final node in workflow.nodes) {
        if (node.id == sourceNodeId) continue;

        if (seekingInput) {
          final pos = _handleWorldPos(node, false, null);
          final dist = (pos - worldPos).distance;
          if (dist < bestDist) {
            bestDist = dist;
            best = (nodeId: node.id, isOutput: false, port: null);
          }
        } else {
          // Seeking output — branch ports only, worker/fan have single output
          if (node.kind == 'branch' && node.outputs.isNotEmpty) {
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

    void _startConnectionDrag(String sourceNodeId, bool sourceIsOutput, Offset worldPos, int? sourcePort) {
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
        final current = ref.read(workflowProvider);
        final alreadyExists = current.edges.any((e) =>
            e.sourceId == sourceNodeId &&
            e.targetId == drag.targetNodeId &&
            e.sourcePort == drag.sourcePort);

        if (!alreadyExists) {
          final newEdge = WorkflowEdge(
            id: 'edge_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
            sourceId: sourceNodeId,
            targetId: drag.targetNodeId!,
            sourcePort: drag.sourcePort,
          );
          ref.read(workflowProvider.notifier).state = current.copyWith(
            edges: [...current.edges, newEdge],
          );
        }
      }

      ref.read(connectionDragProvider.notifier).state = null;
    }

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

    void addNode(OperatorType type) {
      final sourceId = pickerAnchor?.sourceNodeId;
      if (sourceId == null) return;

      final source = workflow.nodes.firstWhere(
        (n) => n.id == sourceId,
        orElse: () => workflow.nodes.first,
      );

      final id = 'node_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final sourceHeight = source.height;
      final newNodeHeight = WorkflowNode(id: '', kind: type.kind, label: '', x: 0, y: 0).height;
      final snappedX = _snap(source.x + 220);
      final snappedY = _snapCenter(source.y + sourceHeight / 2) - newNodeHeight / 2;
      final newNode = WorkflowNode(
        id: id,
        kind: type.kind,
        label: type.label,
        x: snappedX,
        y: snappedY,
        outputs: type.kind == 'branch' ? WorkflowNode.defaultBranchOutputs : const [],
      );

      final edge = WorkflowEdge(
        id: 'edge_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
        sourceId: sourceId,
        targetId: id,
        sourcePort: pickerAnchor?.sourcePort,
      );

      ref.read(workflowProvider.notifier).state = workflow.copyWith(
        nodes: [...workflow.nodes, newNode],
        edges: [...workflow.edges, edge],
      );
      ref.read(selectionProvider.notifier).selectOne(id);
      ref.read(operatorPickerProvider.notifier).state = null;
    }

    void deleteNode(String nodeId) {
      final currentWorkflow = ref.read(workflowProvider);
      final newNodes = currentWorkflow.nodes.where((n) => n.id != nodeId).toList();
      final newEdges = currentWorkflow.edges
          .where((e) => e.sourceId != nodeId && e.targetId != nodeId)
          .toList();
      ref.read(workflowProvider.notifier).state = currentWorkflow.copyWith(
        nodes: newNodes,
        edges: newEdges,
      );
      ref.read(selectionProvider.notifier).removeIds([nodeId]);
      if (hoveredNodeId == nodeId) {
        ref.read(hoveredNodeProvider.notifier).state = null;
      }
      ref.read(nodeMenuProvider.notifier).state = null;
    }

    void duplicateNode(String nodeId) {
      if (nodeId == 'entrypoint') return;
      final node = workflow.nodes.firstWhere((n) => n.id == nodeId);
      final id = 'node_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final newNode = WorkflowNode(
        id: id,
        kind: node.kind,
        label: node.label,
        x: _snap(node.x + 220),
        y: _snap(node.y + 32),
        outputs: node.outputs,
      );
      ref.read(workflowProvider.notifier).state = workflow.copyWith(
        nodes: [...workflow.nodes, newNode],
      );
      ref.read(selectionProvider.notifier).selectOne(id);
      ref.read(nodeMenuProvider.notifier).state = null;
    }

    void collapseNode(String nodeId) {
      final parentEdge = workflow.edges.cast<WorkflowEdge?>().firstWhere(
        (e) => e?.targetId == nodeId,
        orElse: () => null,
      );
      final childEdges = workflow.edges.where((e) => e.sourceId == nodeId).toList();

      final newEdges = workflow.edges
          .where((e) => e.targetId != nodeId && e.sourceId != nodeId)
          .toList();

      if (parentEdge != null) {
        for (final child in childEdges) {
          newEdges.add(WorkflowEdge(
            id: 'edge_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
            sourceId: parentEdge.sourceId,
            targetId: child.targetId,
            sourcePort: parentEdge.sourcePort,
          ));
        }
      }

      final newNodes = workflow.nodes.where((n) => n.id != nodeId).toList();

      ref.read(workflowProvider.notifier).state = workflow.copyWith(
        nodes: newNodes,
        edges: newEdges,
      );

      ref.read(selectionProvider.notifier).removeIds([nodeId]);
      ref.read(nodeMenuProvider.notifier).state = null;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = constraints.biggest;
        return Focus(
          autofocus: true,
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
          child: Listener(
              onPointerDown: (event) {
              if (event.kind != PointerDeviceKind.mouse) return;
              if (event.buttons != kPrimaryButton) return;
              if (!editable || spaceHeld) return;
              // Don't start marquee if pointer is over a node — node's own
              // gesture detector handles drag.
              final worldPos = (event.localPosition - viewport.pan) / viewport.zoom;
              final overNode = workflow.nodes.any((n) => n.rect.contains(worldPos));
              if (overNode) return;
              ref.read(mouseMarqueeStartProvider.notifier).state = event.localPosition;
              ref.read(selectionProvider.notifier).beginMarquee();
            },
            onPointerMove: (event) {
              if (event.kind != PointerDeviceKind.mouse) return;
              if (spaceHeld) {
                controller.pan(event.delta);
                return;
              }
              final start = ref.read(mouseMarqueeStartProvider);
              if (start != null) {
                updateMarqueeFromScreenRect(
                  Rect.fromPoints(start, event.localPosition),
                );
              }
            },
            onPointerUp: (event) {
              if (event.kind != PointerDeviceKind.mouse) return;
              final start = ref.read(mouseMarqueeStartProvider);
              if (start != null) {
                ref.read(selectionProvider.notifier).commitMarquee();
                ref.read(mouseMarqueeStartProvider.notifier).state = null;
                ref.read(marqueeProvider.notifier).state =
                    const MarqueeState();
              }
            },
            onPointerCancel: (event) {
              if (event.kind != PointerDeviceKind.mouse) return;
              final start = ref.read(mouseMarqueeStartProvider);
              if (start != null) {
                ref.read(selectionProvider.notifier).cancelMarquee();
                ref.read(mouseMarqueeStartProvider.notifier).state = null;
                ref.read(marqueeProvider.notifier).state =
                    const MarqueeState();
              }
            },
            onPointerSignal: (event) {
              if (event is PointerScrollEvent &&
                  event.kind == PointerDeviceKind.mouse) {
                controller.zoomAt(event.scrollDelta.dy, event.localPosition);
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                // Deselect when tapping empty canvas
                ref.read(selectionProvider.notifier).clear();
                ref.read(operatorPickerProvider.notifier).state = null;
              },
              onDoubleTap: editable
                  ? () {
                      final next = !scissors;
                      ref.read(scissorsModeProvider.notifier).state = next;
                      if (next) {
                        ref.read(selectionProvider.notifier).clear();
                      }
                    }
                  : null,
              onLongPressStart: editable
                  ? (details) {
                      ref.read(touchMarqueeStartProvider.notifier).state =
                          details.localPosition;
                      ref.read(selectionProvider.notifier).beginMarquee();
                    }
                  : null,
              onLongPressMoveUpdate: editable
                  ? (details) {
                      final start = ref.read(touchMarqueeStartProvider);
                      if (start != null) {
                        updateMarqueeFromScreenRect(
                          Rect.fromPoints(start, details.localPosition),
                        );
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
              onScaleStart: scissors && editable
                  ? null
                  : (details) {
                      if (ref.read(mouseMarqueeStartProvider) != null) return;
                      if (ref.read(touchMarqueeStartProvider) != null) return;
                      controller.beginScale(details.localFocalPoint);
                    },
              onScaleUpdate: scissors && editable
                  ? null
                  : (details) {
                      if (ref.read(mouseMarqueeStartProvider) != null) return;
                      if (ref.read(touchMarqueeStartProvider) != null) return;
                      controller.updateScale(details.scale, details.localFocalPoint);
                    },
              onScaleEnd: scissors && editable
                  ? null
                  : (_) {
                      if (ref.read(mouseMarqueeStartProvider) != null) return;
                      if (ref.read(touchMarqueeStartProvider) != null) return;
                      controller.endScale();
                    },
              onPanStart: scissors && editable
                  ? (details) {
                      final worldPos = Offset(
                        (details.localPosition.dx - viewport.pan.dx) / viewport.zoom,
                        (details.localPosition.dy - viewport.pan.dy) / viewport.zoom,
                      );
                      ref.read(cutPathProvider.notifier).state = [worldPos];
                    }
                  : null,
              onPanUpdate: scissors && editable
                  ? (details) {
                      final worldPos = Offset(
                        (details.localPosition.dx - viewport.pan.dx) / viewport.zoom,
                        (details.localPosition.dy - viewport.pan.dy) / viewport.zoom,
                      );
                      ref.read(cutPathProvider.notifier).state = [
                        ...ref.read(cutPathProvider),
                        worldPos,
                      ];
                    }
                  : null,
              onPanEnd: scissors && editable
                  ? (_) {
                      final path = ref.read(cutPathProvider);
                      if (path.length >= 2) {
                        final threshold = 6.0 / viewport.zoom;
                        final toDelete = <String>{};

                        for (final edge in workflow.edges) {
                          final source = workflow.nodes.firstWhere((n) => n.id == edge.sourceId);
                          final target = workflow.nodes.firstWhere((n) => n.id == edge.targetId);

                          Offset exitPoint(WorkflowNode node) {
                            final pos = Offset(node.x, node.y);
                            return switch (node.kind) {
                              'worker' => Offset(pos.dx + node.width, pos.dy + node.height / 2),
                              'fan'    => Offset(pos.dx + node.width, pos.dy + node.height / 2),
                              _        => Offset(pos.dx + node.width, pos.dy + node.height / 2),
                            };
                          }

                          Offset entryPoint(WorkflowNode node) {
                            final pos = Offset(node.x, node.y);
                            return Offset(pos.dx, pos.dy + node.height / 2);
                          }

                          final p0 = exitPoint(source);
                          final p3 = entryPoint(target);
                          final dx = (p3.dx - p0.dx).abs();
                          final controlLen = dx.clamp(40.0, 150.0);
                          final p1 = Offset(p0.dx + controlLen, p0.dy);
                          final p2 = Offset(p3.dx - controlLen, p3.dy);

                          for (var i = 0; i <= 20; i++) {
                            final t = i / 20.0;
                            final u = 1.0 - t;
                            final tt = t * t;
                            final uu = u * u;
                            final uuu = uu * u;
                            final ttt = tt * t;
                            final bx = uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
                            final by = uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;

                            var hit = false;
                            for (var j = 0; j < path.length - 1; j++) {
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
                              toDelete.add('${edge.sourceId}→${edge.targetId}');
                              break;
                            }
                          }
                        }

                        if (toDelete.isNotEmpty) {
                          final current = ref.read(workflowProvider);
                          ref.read(workflowProvider.notifier).state = current.copyWith(
                            edges: current.edges.where((e) => !toDelete.contains('${e.sourceId}→${e.targetId}')).toList(),
                          );
                        }
                      }
                      ref.read(cutPathProvider.notifier).state = const [];
                    }
                  : null,
              child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.hearthGradient,
          ),
          child: ClipRect(
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
                // World transform
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
                            onTapDown: scissors && editable
                                ? (details) {
                                    final tapWorld = details.localPosition;
                                    const threshold = 18.0;
                                    String? nearestEdgeKey;
                                    double nearestDist = threshold;

                                    for (final edge in workflow.edges) {
                                      final source = workflow.nodes.firstWhere((n) => n.id == edge.sourceId);
                                      final target = workflow.nodes.firstWhere((n) => n.id == edge.targetId);

                                      // Compute dragged positions (same as painter)
                                      Offset nodePos(WorkflowNode node) {
                                        final inGroupDrag = draggingNodeId != null &&
                                            selection.current.length > 1 &&
                                            selection.current.contains(draggingNodeId) &&
                                            selection.current.contains(node.id);
                                        if (draggingNodeId == node.id || inGroupDrag) {
                                          return Offset(node.x + dragOffset.dx, node.y + dragOffset.dy);
                                        }
                                        return Offset(node.x, node.y);
                                      }

                                      Offset exitPoint(WorkflowNode node) {
                                        final pos = nodePos(node);
                                        return switch (node.kind) {
                                          'worker' => Offset(pos.dx + node.width, pos.dy + node.height / 2),
                                          'fan'    => Offset(pos.dx + node.width, pos.dy + node.height / 2),
                                          _        => Offset(pos.dx + node.width, pos.dy + node.height / 2),
                                        };
                                      }

                                      Offset entryPoint(WorkflowNode node) {
                                        final pos = nodePos(node);
                                        return Offset(pos.dx, pos.dy + node.height / 2);
                                      }

                                      final p0 = exitPoint(source);
                                      final p3 = entryPoint(target);
                                      final dx = (p3.dx - p0.dx).abs();
                                      final controlLen = dx.clamp(40.0, 150.0);
                                      final p1 = Offset(p0.dx + controlLen, p0.dy);
                                      final p2 = Offset(p3.dx - controlLen, p3.dy);

                                      // Sample bezier curve
                                      for (var i = 0; i <= 20; i++) {
                                        final t = i / 20.0;
                                        final u = 1.0 - t;
                                        final tt = t * t;
                                        final uu = u * u;
                                        final uuu = uu * u;
                                        final ttt = tt * t;
                                        final bx = uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
                                        final by = uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;
                                        final dist = (tapWorld.dx - bx).abs() + (tapWorld.dy - by).abs();
                                        if (dist < nearestDist) {
                                          nearestDist = dist;
                                          nearestEdgeKey = '${edge.sourceId}→${edge.targetId}';
                                        }
                                      }
                                    }

                                    if (nearestEdgeKey != null) {
                                      final current = ref.read(workflowProvider);
                                      ref.read(workflowProvider.notifier).state = current.copyWith(
                                        edges: current.edges.where((e) => '${e.sourceId}→${e.targetId}' != nearestEdgeKey).toList(),
                                      );
                                    }
                                  }
                                : null,
                            child: CustomPaint(
                              painter: ConnectionPainter(
                                nodes: workflow.nodes,
                                edges: workflow.edges,
                                draggingNodeId: draggingNodeId,
                                dragOffset: dragOffset,
                                selectedIds: selection.current,
                                connectionDrag: connectionDrag,
                              ),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                        // Nodes
                        ...workflow.nodes.map((node) {
                          final current = selection.current;
                          final isSelected = current.contains(node.id);
                          // Group drag: if the dragged node is part of a multi-selection, every selected
                          // node moves together. Single-node drag (length 1 or unselected) moves only it.
                          final inGroupDrag = draggingNodeId != null &&
                              current.contains(draggingNodeId) &&
                              current.length > 1 &&
                              current.contains(node.id);
                          final isDragging = inGroupDrag || (draggingNodeId == node.id);
                          final displayX = isDragging ? node.x + dragOffset.dx : node.x;
                          final displayY = isDragging ? node.y + dragOffset.dy : node.y;

                          final nodeWidget = node.id == 'entrypoint'
                              ? EntrypointNode(
                                  node: node,
                                  selected: isSelected,
                                  onEnter: () {
                                    ref.read(hoveredNodeProvider.notifier).state = node.id;
                                  },
                                  onExit: () {
                                    ref.read(hoveredNodeProvider.notifier).state =
                                        (hoveredNodeId == node.id) ? null : hoveredNodeId;
                                  },
                                )
                              : node.kind == 'worker'
                                  ? WorkerNode(
                                      node: node,
                                      selected: isSelected,
                                      onEnter: () {
                                        ref.read(hoveredNodeProvider.notifier).state = node.id;
                                      },
                                      onExit: () {
                                        ref.read(hoveredNodeProvider.notifier).state =
                                            (hoveredNodeId == node.id) ? null : hoveredNodeId;
                                      },
                                    )
                                  : node.kind == 'fan'
                                      ? MapNode(
                                          node: node,
                                          selected: isSelected,
                                          onEnter: () {
                                            ref.read(hoveredNodeProvider.notifier).state = node.id;
                                          },
                                          onExit: () {
                                            ref.read(hoveredNodeProvider.notifier).state =
                                                (hoveredNodeId == node.id) ? null : hoveredNodeId;
                                          },
                                        )
                                      : BranchNode(
                                          node: node,
                                          selected: isSelected,
                                          onEnter: () {
                                            ref.read(hoveredNodeProvider.notifier).state = node.id;
                                          },
                                          onExit: () {
                                            ref.read(hoveredNodeProvider.notifier).state =
                                                (hoveredNodeId == node.id) ? null : hoveredNodeId;
                                          },
                                        );

                          return AnimatedPositioned(
                            key: ValueKey('${workflow.id}_${node.id}'),
                            left: displayX,
                            top: displayY,
                            duration: isDragging ? Duration.zero : _snapDuration,
                            curve: Curves.easeOutCubic,
                            child: MultiHitStack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    if (scissors && editable) {
                                      deleteNode(node.id);
                                      return;
                                    }
                                    ref.read(selectionProvider.notifier).toggleOne(node.id);
                                    // close picker when selecting another node
                                    if (!isSelected) {
                                      ref.read(operatorPickerProvider.notifier).state = null;
                                    }
                                  },
                                  onLongPressStart: isSelected && editable && node.id != 'entrypoint'
                                      ? (details) {
                                          ref.read(nodeMenuProvider.notifier).state = NodeMenuAnchor(
                                            nodeId: node.id,
                                          );
                                        }
                                      : null,
                                  onSecondaryTapDown: isSelected && editable && node.id != 'entrypoint'
                                      ? (details) {
                                          ref.read(nodeMenuProvider.notifier).state = NodeMenuAnchor(
                                            nodeId: node.id,
                                          );
                                        }
                                      : null,
                                  onPanStart: editable && !scissors
                                      ? (_) {
                                          ref.read(draggingNodeIdProvider.notifier).state = node.id;
                                          ref.read(dragOffsetProvider.notifier).state = Offset.zero;
                                        }
                                      : null,
                                  onPanUpdate: editable && !scissors
                                      ? (details) {
                                          if (draggingNodeId == node.id) {
                                            ref.read(dragOffsetProvider.notifier).state += details.delta;
                                          }
                                        }
                                      : null,
                                  onPanEnd: editable && !scissors
                                      ? (_) {
                                          if (draggingNodeId != node.id) return;
                                          final offset = ref.read(dragOffsetProvider);
                                          final cur = ref.read(selectionProvider).current;
                                          final currentWorkflow = ref.read(workflowProvider);
                                          final isGroupDrag = cur.length > 1 && cur.contains(node.id);

                                          final newNodes = currentWorkflow.nodes.map((n) {
                                            final shouldMove = isGroupDrag
                                                ? cur.contains(n.id)
                                                : (n.id == node.id);
                                            if (!shouldMove) return n;
                                            final h = n.height;
                                            final snappedX = _snap(n.x + offset.dx);
                                            final snappedY = _snapCenter(n.y + offset.dy + h / 2) - h / 2;
                                            return n.copyWith(x: snappedX, y: snappedY);
                                          }).toList();

                                          ref.read(workflowProvider.notifier).state =
                                              currentWorkflow.copyWith(nodes: newNodes);
                                          ref.read(draggingNodeIdProvider.notifier).state = null;
                                          ref.read(dragOffsetProvider.notifier).state = Offset.zero;
                                        }
                                      : null,
                                  onPanCancel: editable && !scissors
                                      ? () {
                                          ref.read(draggingNodeIdProvider.notifier).state = null;
                                          ref.read(dragOffsetProvider.notifier).state = Offset.zero;
                                        }
                                      : null,
                                  child: nodeWidget,
                                ),
                                if (isSelected && editable && node.id != 'entrypoint')
                                  Positioned(
                                    left: -44.0,
                                    top: node.height / 2 - 44.0,
                                    child: _InputHandle(
                                      onTap: () {},
                                      onPanStart: editable
                                          ? (_) {
                                              final worldPos = _handleWorldPos(node, false, null);
                                              _startConnectionDrag(node.id, false, worldPos, null);
                                            }
                                          : null,
                                      onPanUpdate: editable
                                          ? (details) {
                                              final drag = ref.read(connectionDragProvider);
                                              if (drag != null) {
                                                _updateConnectionDrag(
                                                  drag.currentWorldPos + details.delta,
                                                  node.id,
                                                );
                                              }
                                            }
                                          : null,
                                      onPanEnd: editable
                                          ? (_) => _endConnectionDrag(node.id)
                                          : null,
                                      onPanCancel: editable
                                          ? () => ref.read(connectionDragProvider.notifier).state = null
                                          : null,
                                    ),
                                  ),
                                  if (isSelected && editable && node.kind == 'branch')
                                  ...node.outputs.isNotEmpty
                                      ? node.outputs.asMap().entries.map((e) {
                                          final port = e.key;
                                          final top = BranchNode.padY + port * BranchNode.rowHeight;
                                          return Positioned(
                                            left: BranchNode.width - 22.0,
                                            top: top,
                                            child: _OutputHandle(
                                              targetWidth: 44.0,
                                              targetHeight: BranchNode.rowHeight,
                                              onTap: () => showPicker(
                                                Offset(
                                                  displayX + BranchNode.width,
                                                  displayY + BranchNode.padY + port * BranchNode.rowHeight + BranchNode.rowHeight / 2,
                                                ),
                                                node.id,
                                                sourcePort: port,
                                              ),
                                              onPanStart: editable
                                                  ? (_) {
                                                      final worldPos = _handleWorldPos(node, true, port);
                                                      _startConnectionDrag(node.id, true, worldPos, port);
                                                    }
                                                  : null,
                                              onPanUpdate: editable
                                                  ? (details) {
                                                      final drag = ref.read(connectionDragProvider);
                                                      if (drag != null) {
                                                        _updateConnectionDrag(
                                                          drag.currentWorldPos + details.delta,
                                                          node.id,
                                                        );
                                                      }
                                                    }
                                                  : null,
                                              onPanEnd: editable
                                                  ? (_) => _endConnectionDrag(node.id)
                                                  : null,
                                              onPanCancel: editable
                                                  ? () => ref.read(connectionDragProvider.notifier).state = null
                                                  : null,
                                            ),
                                          );
                                        })
                                      : [
                                          // Fallback for branch nodes with no outputs defined
                                          Positioned(
                                            left: BranchNode.width - 44.0,
                                            top: node.height / 2 - 44.0,
                                            child: _OutputHandle(
                                              onTap: () => showPicker(
                                                Offset(
                                                  displayX + BranchNode.width,
                                                  displayY + node.height / 2,
                                                ),
                                                node.id,
                                              ),
                                              onPanStart: editable
                                                  ? (_) {
                                                      final worldPos = _handleWorldPos(node, true, null);
                                                      _startConnectionDrag(node.id, true, worldPos, null);
                                                    }
                                                  : null,
                                              onPanUpdate: editable
                                                  ? (details) {
                                                      final drag = ref.read(connectionDragProvider);
                                                      if (drag != null) {
                                                        _updateConnectionDrag(
                                                          drag.currentWorldPos + details.delta,
                                                          node.id,
                                                        );
                                                      }
                                                    }
                                                  : null,
                                              onPanEnd: editable
                                                  ? (_) => _endConnectionDrag(node.id)
                                                  : null,
                                              onPanCancel: editable
                                                  ? () => ref.read(connectionDragProvider.notifier).state = null
                                                  : null,
                                            ),
                                          ),
                                        ],
                                if (isSelected && editable && node.kind != 'branch')
                                  Positioned(
                                    left: node.width - 44.0,
                                    top: node.height / 2 - 44.0,
                                    child: _OutputHandle(
                                      onTap: () => showPicker(
                                        Offset(
                                          displayX + node.width,
                                          displayY + node.height / 2,
                                        ),
                                        node.id,
                                      ),
                                      onPanStart: editable
                                          ? (_) {
                                              final worldPos = _handleWorldPos(node, true, null);
                                              _startConnectionDrag(node.id, true, worldPos, null);
                                            }
                                          : null,
                                      onPanUpdate: editable
                                          ? (details) {
                                              final drag = ref.read(connectionDragProvider);
                                              if (drag != null) {
                                                _updateConnectionDrag(
                                                  drag.currentWorldPos + details.delta,
                                                  node.id,
                                                );
                                              }
                                            }
                                          : null,
                                      onPanEnd: editable
                                          ? (_) => _endConnectionDrag(node.id)
                                          : null,
                                      onPanCancel: editable
                                          ? () => ref.read(connectionDragProvider.notifier).state = null
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),

                        // Cut path overlay (scissors mode drag line)
                        if (cutPath.isNotEmpty)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CutPathPainter(points: cutPath),
                              size: Size.infinite,
                            ),
                          ),

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
                        child: CustomPaint(painter: MarqueePainter(m.screenRect)),
                      ),
                    );
                  },
                ),
                // Screen-space operator picker
                if (pickerAnchor != null)
                  OperatorPicker(
                    anchor: pickerAnchor.screenPos,
                    onSelect: addNode,
                    onClose: () {
                      ref.read(operatorPickerProvider.notifier).state = null;
                    },
                  ),
                if (menuAnchor != null)
                  Builder(
                    builder: (context) {
                      final menuNode = workflow.nodes.cast<WorkflowNode?>().firstWhere(
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
                      final menuDx = isMenuNodeDragging ? menuNode.x + dragOffset.dx : menuNode.x;
                      final menuDy = isMenuNodeDragging ? menuNode.y + dragOffset.dy : menuNode.y;
                      final screenPos = Offset(
                        menuDx * viewport.zoom + viewport.pan.dx,
                        menuDy * viewport.zoom + viewport.pan.dy,
                      );
                      return NodeContextMenu(
                        anchor: screenPos,
                        canDuplicate: menuNode.id != 'entrypoint',
                        onDuplicate: () => duplicateNode(menuAnchor.nodeId),
                        onCollapse: () => collapseNode(menuAnchor.nodeId),
                        onDelete: () => deleteNode(menuAnchor.nodeId),
                        onClose: () {
                          ref.read(nodeMenuProvider.notifier).state = null;
                        },
                      );
                    },
                  ),
                CanvasToolbar(canvasSize: canvasSize),
                // Mode indicator badge
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              ],
            ),
          ),
        ),
      ),
    ),
  );
  },
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

  const _OutputHandle({
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
  final VoidCallback onTap;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;

  const _InputHandle({
    required this.onTap,
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
  const UnboundedHitStack({
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
  const MultiHitStack({
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
      final StackParentData childParentData = child.parentData! as StackParentData;
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
