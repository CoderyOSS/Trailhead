import 'dart:math' show Random;
import 'dart:ui' show PointerDeviceKind;
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
import '../../providers/node_menu_provider.dart';
import 'node_context_menu.dart';
import 'entrypoint_node.dart';
import 'fan_node.dart';
import 'routing_node.dart';
import 'worker_node.dart';
import 'zoom_controls.dart';

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
    final menuAnchor = ref.watch(nodeMenuProvider);

    double nodeWidth(String kind) => switch (kind) {
      'worker' => 168.0,
      'fan'    => 168.0,
      _        => BranchNode.width,
    };

    double nodeHeight(String kind, {List<BranchOutput> outputs = const []}) => switch (kind) {
      'worker' => 36.0,
      'fan'    => 36.0,
      _        => outputs.isNotEmpty
          ? BranchNode.padY * 2 + outputs.length * BranchNode.rowHeight
          : BranchNode.padY * 2 + 4 * BranchNode.rowHeight,
    };

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

    void addNode(OperatorType type) {
      final sourceId = pickerAnchor?.sourceNodeId;
      if (sourceId == null) return;

      final source = workflow.nodes.firstWhere(
        (n) => n.id == sourceId,
        orElse: () => workflow.nodes.first,
      );

      final id = 'node_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final sourceHeight = nodeHeight(source.kind, outputs: source.outputs);
      final newNodeHeight = nodeHeight(type.kind);
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
      ref.read(selectedNodeProvider.notifier).state = id;
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

      if (selectedNodeId == nodeId) {
        ref.read(selectedNodeProvider.notifier).state = null;
      }
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
          child: Listener(
                                    onPointerMove: (event) {
          if (event.kind == PointerDeviceKind.mouse) {
            controller.pan(event.delta);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // Deselect when tapping empty canvas
            ref.read(selectedNodeProvider.notifier).state = null;
            ref.read(operatorPickerProvider.notifier).state = null;
          },
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
                                    ref.read(selectedNodeProvider.notifier).state =
                                        isSelected ? null : node.id;
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
                                  onPanStart: editable
                                      ? (_) {
                                          ref.read(draggingNodeIdProvider.notifier).state = node.id;
                                          ref.read(dragOffsetProvider.notifier).state = Offset.zero;
                                        }
                                      : null,
                                  onPanUpdate: editable
                                      ? (details) {
                                          if (draggingNodeId == node.id) {
                                            ref.read(dragOffsetProvider.notifier).state += details.delta;
                                          }
                                        }
                                      : null,
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
                                  onPanCancel: editable
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
                                    top: nodeHeight(node.kind, outputs: node.outputs) / 2 - 44.0,
                                    child: _InputHandle(
                                      onTap: () {},
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
                                            ),
                                          );
                                        })
                                      : [
                                          // Fallback for branch nodes with no outputs defined
                                          Positioned(
                                            left: BranchNode.width - 44.0,
                                            top: nodeHeight(node.kind, outputs: node.outputs) / 2 - 44.0,
                                            child: _OutputHandle(
                                              onTap: () => showPicker(
                                                Offset(
                                                  displayX + BranchNode.width,
                                                  displayY + nodeHeight(node.kind, outputs: node.outputs) / 2,
                                                ),
                                                node.id,
                                              ),
                                            ),
                                          ),
                                        ],
                                if (isSelected && editable && node.kind != 'branch')
                                  Positioned(
                                    left: nodeWidth(node.kind) - 44.0,
                                    top: nodeHeight(node.kind, outputs: node.outputs) / 2 - 44.0,
                                    child: _OutputHandle(
                                      onTap: () => showPicker(
                                        Offset(
                                          displayX + nodeWidth(node.kind),
                                          displayY + nodeHeight(node.kind, outputs: node.outputs) / 2,
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
                ZoomControls(canvasSize: canvasSize),
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
  final double targetWidth;
  final double targetHeight;

  const _OutputHandle({
    required this.onTap,
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

  const _InputHandle({
    required this.onTap,
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
