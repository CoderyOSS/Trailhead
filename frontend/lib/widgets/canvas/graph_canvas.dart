import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_controller.dart';
import '../../providers/mode_provider.dart';
import '../../theme/tokens.dart';
import 'dot_grid_painter.dart';
import 'worker_node.dart';

class GraphCanvas extends ConsumerWidget {
  const GraphCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewport = ref.watch(canvasControllerProvider);
    final controller = ref.read(canvasControllerProvider.notifier);
    final workflow = ref.watch(workflowProvider);
    final selectedNodeId = ref.watch(selectedNodeProvider);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
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
              Positioned.fill(
                child: CustomPaint(
                  painter: DotGridPainter(
                    zoom: viewport.zoom,
                    pan: viewport.pan,
                  ),
                ),
              ),
              Transform.translate(
                offset: viewport.pan,
                child: Transform.scale(
                  scale: viewport.zoom,
                  alignment: Alignment.topLeft,
                  child: Stack(
                    children: workflow.nodes.map((node) {
                      return Positioned(
                        left: node.x,
                        top: node.y,
                        child: WorkerNode(
                          node: node,
                          selected: selectedNodeId == node.id,
                          onTap: () {
                            ref.read(selectedNodeProvider.notifier).state =
                                selectedNodeId == node.id ? null : node.id;
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
