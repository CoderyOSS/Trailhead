import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow_node.dart';
import '../../providers/canvas_controller.dart';
import '../../providers/mode_provider.dart';
import '../../theme/tokens.dart';
import 'fan_node.dart';
import 'routing_node.dart';
import 'worker_node.dart';

class ZoomControls extends ConsumerWidget {
  final Size canvasSize;
  const ZoomControls({super.key, required this.canvasSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewport = ref.watch(canvasControllerProvider);
    final controller = ref.read(canvasControllerProvider.notifier);
    final workflow = ref.watch(workflowProvider);

    const mono = TextStyle(
      fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace',
      fontSize: 11,
      height: 1.0,
    );

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

    void fitToView() {
      final nodes = workflow.nodes;
      if (nodes.isEmpty) {
        controller.reset();
        return;
      }
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;
      for (final node in nodes) {
        final w = nodeWidth(node.kind);
        final h = nodeHeight(node.kind, outputs: node.outputs);
        minX = minX < node.x ? minX : node.x;
        minY = minY < node.y ? minY : node.y;
        maxX = maxX > node.x + w ? maxX : node.x + w;
        maxY = maxY > node.y + h ? maxY : node.y + h;
      }
      final bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
      controller.fitToBounds(bounds, canvasSize, margin: AppSpacing.s8 * 2);
    }

    Widget btn({
      required VoidCallback onTap,
      required Widget child,
      double? width,
      String? tooltip,
    }) {
      return Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            hoverColor: AppColors.bg3,
            splashColor: AppColors.bg3.withValues(alpha: 0.5),
            child: Container(
              width: width ?? 22,
              height: 22,
              alignment: Alignment.center,
              child: DefaultTextStyle(
                style: mono.copyWith(
                  color: AppColors.fg0,
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          border: Border.all(color: AppColors.border1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minus
            btn(
              onTap: () => controller.zoomBy(0.9),
              tooltip: 'Zoom out',
              child: const Text('−'),
            ),
            // Percentage — tap to reset
            btn(
              onTap: () => controller.setZoom(1.0),
              width: 38,
              tooltip: 'Reset to 100%',
              child: Text(
                '${(viewport.zoom * 100).round()}%',
                style: mono.copyWith(
                  color: AppColors.fg3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Plus
            btn(
              onTap: () => controller.zoomBy(1.1),
              tooltip: 'Zoom in',
              child: const Text('+'),
            ),
            // Divider
            Container(
              width: 1,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: AppColors.border1,
            ),
            // Fit
            btn(
              onTap: fitToView,
              width: null,
              tooltip: 'Fit to view',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'fit',
                  style: mono.copyWith(
                    color: AppColors.fg0,
                    fontWeight: FontWeight.w500,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
