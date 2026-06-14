import 'dart:math' show Random;
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
import 'connection_painter.dart';
import 'dot_grid_painter.dart';
import 'operator_picker.dart';
import 'fan_node.dart';
import 'routing_node.dart';
import 'worker_node.dart';

class GraphCanvas extends ConsumerWidget {
  const GraphCanvas({super.key});

  static const double _snapGrid = 32.0;
  static const Duration _snapDuration = Duration(milliseconds: 200);

  double _snap(double value) => (value / _snapGrid).round() * _snapGrid;
  double _snapCenter(double center) => (center / _snapGrid).round() * _snapGrid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewport = ref.watch(canvasControllerProvider);
    final controller = ref.read(canvasControllerProvider.notifier);
    final workflow = ref.watch(workflowProvider);
    final selectedNodeId = ref.watch(selectedNodeProvider);
    final hoveredNodeId = ref.watch(hoveredNodeProvider);
    final draggingNodeId = ref.watch(draggingNodeIdProvider);
    final dragOffset = ref.watch(dragOffsetProvider);
    final pickerAnchor = ref.watch(operatorPickerProvider);
    final mode = ref.watch(modeProvider);
    final editable = mode == AppMode.build;

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

    void showPicker(Offset worldPos, String sourceId) {
      if (!editable) return;
      final screenX = worldPos.dx * viewport.zoom + viewport.pan.dx;
      final screenY = worldPos.dy * viewport.zoom + viewport.pan.dy;
      ref.read(operatorPickerProvider.notifier).state = PickerAnchor(
        screenPos: Offset(screenX, screenY),
        sourceNodeId: sourceId,
      );
    }

    void addNode(OperatorType type) {
      final sourceId = pickerAnchor?.sourceNodeId;
      if (sourceId == null) return;

      final source = workflow.nodes.firstWhere(
        (n) => n.id == sourceId,
        orElse: () => workflow.nodes.first,
      );

      final id = 'node_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final sourceHeight = source.kind == 'worker' ? 32.0 : 64.0;
      final newNodeHeight = type.kind == 'worker' ? 32.0 : 64.0;
      final snappedX = _snap(source.x + 220);
      final snappedY = _snapCenter(source.y + sourceHeight / 2) - newNodeHeight / 2;
      final newNode = WorkflowNode(
        id: id,
        kind: type.kind,
        label: type.label,
        x: snappedX,
        y: snappedY,
      );

      final edge = WorkflowEdge(
        id: 'edge_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
        sourceId: sourceId,
        targetId: id,
      );

      ref.read(workflowProvider.notifier).state = workflow.copyWith(
        nodes: [...workflow.nodes, newNode],
        edges: [...workflow.edges, edge],
      );
      ref.read(selectedNodeProvider.notifier).state = id;
      ref.read(operatorPickerProvider.notifier).state = null;
    }

    void deleteNode(String nodeId) {
      final newNodes = workflow.nodes.where((n) => n.id != nodeId).toList();
      final newEdges = workflow.edges
          .where((e) => e.sourceId != nodeId && e.targetId != nodeId)
          .toList();
      ref.read(workflowProvider.notifier).state = workflow.copyWith(
        nodes: newNodes,
        edges: newEdges,
      );
      if (selectedNodeId == nodeId) {
        ref.read(selectedNodeProvider.notifier).state = null;
      }
      if (hoveredNodeId == nodeId) {
        ref.read(hoveredNodeProvider.notifier).state = null;
      }
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (!editable) return KeyEventResult.ignored;
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (selectedNodeId != null) {
              deleteNode(selectedNodeId);
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
          // Deselect when tapping empty canvas
          ref.read(selectedNodeProvider.notifier).state = null;
          ref.read(operatorPickerProvider.notifier).state = null;
        },
        onPanUpdate: (details) {
          controller.pan(details.delta);
        },
        child: Container(
          decoration: const BoxDecoration(
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
                          child: CustomPaint(
                            painter: ConnectionPainter(
                              nodes: workflow.nodes,
                              edges: workflow.edges,
                              draggingNodeId: draggingNodeId,
                              dragOffset: dragOffset,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                        // Nodes
                        ...workflow.nodes.map((node) {
                          final isSelected = selectedNodeId == node.id;
                          final isDragging = draggingNodeId == node.id;
                          final displayX = isDragging ? node.x + dragOffset.dx : node.x;
                          final displayY = isDragging ? node.y + dragOffset.dy : node.y;

                          final nodeWidget = node.kind == 'worker'
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
                                  onDelete: (editable && node.id != 'entrypoint') ? () => deleteNode(node.id) : null,
                                )
                              : node.kind == 'fan'
                                  ? FanNode(
                                      node: node,
                                      selected: isSelected,
                                      onEnter: () {
                                        ref.read(hoveredNodeProvider.notifier).state = node.id;
                                      },
                                      onExit: () {
                                        ref.read(hoveredNodeProvider.notifier).state =
                                            (hoveredNodeId == node.id) ? null : hoveredNodeId;
                                      },
                                      onDelete: (editable && node.id != 'entrypoint') ? () => deleteNode(node.id) : null,
                                    )
                                   : RoutingNode(
                                      node: node,
                                      selected: isSelected,
                                      onEnter: () {
                                        ref.read(hoveredNodeProvider.notifier).state = node.id;
                                      },
                                      onExit: () {
                                        ref.read(hoveredNodeProvider.notifier).state =
                                            (hoveredNodeId == node.id) ? null : hoveredNodeId;
                                      },
                                      onDelete: (editable && node.id != 'entrypoint') ? () => deleteNode(node.id) : null,
                                    );

                          return AnimatedPositioned(
                            key: ValueKey('${workflow.id}_${node.id}'),
                            left: displayX,
                            top: displayY,
                            duration: isDragging ? Duration.zero : _snapDuration,
                            curve: Curves.easeOutCubic,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    ref.read(selectedNodeProvider.notifier).state =
                                        isSelected ? null : node.id;
                                    // close picker when selecting another node
                                    if (!isSelected) {
                                      ref.read(operatorPickerProvider.notifier).state = null;
                                    }
                                  },
                                  onPanStart: editable
                                      ? (_) {
                                          ref.read(draggingNodeIdProvider.notifier).state = node.id;
                                          ref.read(dragOffsetProvider.notifier).state = Offset.zero;
                                        }
                                      : null,
                                  onPanUpdate: editable
                                      ? (details) {
                                          if (draggingNodeId == node.id) {
                                            final worldDelta = Offset(
                                              details.delta.dx / viewport.zoom,
                                              details.delta.dy / viewport.zoom,
                                            );
                                            ref.read(dragOffsetProvider.notifier).state += worldDelta;
                                          }
                                        }
                                      : null,
                                  onPanEnd: editable
                                      ? (_) {
                                          if (draggingNodeId == node.id) {
                                            final offset = ref.read(dragOffsetProvider);
                                            final nodeHeight = node.kind == 'worker' ? 32.0 : 64.0;
                                            final snappedX = _snap(node.x + offset.dx);
                                            final snappedY = _snapCenter(node.y + offset.dy + nodeHeight / 2) - nodeHeight / 2;
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
                                  onPanCancel: editable
                                      ? () {
                                          ref.read(draggingNodeIdProvider.notifier).state = null;
                                          ref.read(dragOffsetProvider.notifier).state = Offset.zero;
                                        }
                                      : null,
                                  child: nodeWidget,
                                ),
                                if (isSelected && editable)
                                  Positioned(
                                    left: (node.kind == 'worker'
                                            ? 160.0
                                            : node.kind == 'fan'
                                                ? 160.0
                                                : RoutingNode.pillRight) -
                                        88.0 / viewport.zoom,
                                    top: (node.kind == 'worker'
                                            ? 16.0
                                            : node.kind == 'fan'
                                                ? 32.0
                                                : RoutingNode.pillVCenter) -
                                        88.0 / viewport.zoom,
                                    child: _OutputHandle(
                                      inverseZoom: 1.0 / viewport.zoom,
                                      onTap: () => showPicker(
                                        Offset(
                                          displayX +
                                              (node.kind == 'worker'
                                                  ? 160.0
                                                  : node.kind == 'fan'
                                                      ? 160.0
                                                      : RoutingNode.pillRight),
                                          displayY +
                                              (node.kind == 'worker'
                                                  ? 16.0
                                                  : node.kind == 'fan'
                                                      ? 32.0
                                                      : RoutingNode.pillVCenter),
                                        ),
                                        node.id,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),

                        ],
                      ),
                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutputHandle extends StatelessWidget {
  final double inverseZoom;
  final VoidCallback onTap;

  const _OutputHandle({
    required this.inverseZoom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Direct world-space sizing so hit area exactly matches visual area.
    // 44 screen-px hit area = 44 * inverseZoom world units.
    final size = 176.0 * inverseZoom;
    final dotSize = 12.0 * inverseZoom;
    final borderWidth = 2.0 * inverseZoom;
    final ringSpread = 1.0 * inverseZoom;
    final glowBlur = 8.0 * inverseZoom;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
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
