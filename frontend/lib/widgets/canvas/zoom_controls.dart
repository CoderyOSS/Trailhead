import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_controller.dart';
import '../../theme/tokens.dart';

class ZoomControls extends ConsumerWidget {
  const ZoomControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewport = ref.watch(canvasControllerProvider);
    final controller = ref.read(canvasControllerProvider.notifier);

    const mono = TextStyle(
      fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace',
      fontSize: 11,
      height: 1.0,
    );

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
              onTap: () => controller.reset(),
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
