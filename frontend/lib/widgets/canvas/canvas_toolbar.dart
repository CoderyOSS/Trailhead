import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow_node.dart';
import '../../providers/canvas_controller.dart';
import '../../providers/mode_provider.dart';
import '../../providers/scissors_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/mode_rail.dart';
import '../icons.dart';

class CanvasToolbar extends ConsumerWidget {
  final Size canvasSize;
  const CanvasToolbar({super.key, required this.canvasSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(canvasControllerProvider.notifier);
    final workflow = ref.watch(workflowProvider);
    final mode = ref.watch(modeProvider);
    final editable = mode == AppMode.build;
    final scissors = ref.watch(scissorsModeProvider);

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
        minX = minX < node.x ? minX : node.x;
        minY = minY < node.y ? minY : node.y;
        maxX = maxX > node.x + node.width ? maxX : node.x + node.width;
        maxY = maxY > node.y + node.height ? maxY : node.y + node.height;
      }
      final bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
      controller.fitToBounds(bounds, canvasSize, margin: AppSpacing.s8 * 2);
    }

    Widget toolBtn({
      required VoidCallback onTap,
      required TrailheadIconData icon,
      required bool active,
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
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: TrailheadIcon(
                icon: icon,
                size: 14,
                color: active ? AppColors.accentInk : AppColors.fg0,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (editable) ...[
              toolBtn(
                onTap: () {
                  ref.read(scissorsModeProvider.notifier).state = false;
                  final currentFlash = ref.read(flashOverlayProvider);
                  ref.read(flashOverlayProvider.notifier).state = (
                    mode: FlashMode.cursor,
                    id: (currentFlash?.id ?? 0) + 1,
                  );
                },
                icon: TrailheadIconData.mousePointer,
                active: !scissors,
                tooltip: 'Select — move and select nodes',
              ),
              const SizedBox(height: 2),
              toolBtn(
                onTap: () {
                  ref.read(scissorsModeProvider.notifier).state = true;
                  final currentFlash = ref.read(flashOverlayProvider);
                  ref.read(flashOverlayProvider.notifier).state = (
                    mode: FlashMode.scissors,
                    id: (currentFlash?.id ?? 0) + 1,
                  );
                },
                icon: TrailheadIconData.scissors,
                active: scissors,
                tooltip: 'Scissors — cut connections',
              ),
              Container(
                width: 18,
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: AppColors.border1,
              ),
            ],
            toolBtn(
              onTap: fitToView,
              icon: TrailheadIconData.maximize,
              active: false,
              tooltip: 'Fit to view',
            ),
          ],
        ),
      ),
    );
  }
}
