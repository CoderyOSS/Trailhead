import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/canvas_controller.dart';
import 'package:frontend/theme/tokens.dart';
import 'dot_grid_painter.dart';

class GraphCanvas extends ConsumerWidget {
  const GraphCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewport = ref.watch(canvasControllerProvider);
    final controller = ref.read(canvasControllerProvider.notifier);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (details) {
        controller.pan(details.delta);
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.hearthGradient,
        ),
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
          ],
        ),
      ),
    );
  }
}
