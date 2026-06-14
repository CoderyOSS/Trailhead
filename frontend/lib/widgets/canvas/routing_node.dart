import 'package:flutter/material.dart';
import '../../models/workflow_node.dart';
import '../../providers/mock_data.dart';
import '../../theme/tokens.dart';
import '../icons.dart';
import '../delete_button.dart';

class RoutingNode extends StatelessWidget {
  /// Full footprint matching the WorkerNode and the canvas grid.
  static const double width = 192;
  static const double height = 64;

  /// Pill bounds inside the 192×64 footprint.
  static const double pillLeft = 34;
  static const double pillRight = 158;  // 34 + 124
  static const double pillVCenter = 32; // centered in 64

  final WorkflowNode node;
  final JobState? status;
  final bool selected;
  final VoidCallback? onEnter;
  final VoidCallback? onExit;
  final VoidCallback? onDelete;

  const RoutingNode({
    super.key,
    required this.node,
    this.status,
    this.selected = false,
    this.onEnter,
    this.onExit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final running = status == JobState.running;
    final meta = _routingMeta[node.kind] ?? _routingMeta['branch']!;

    List<BoxShadow> shadows;
    if (selected) {
      shadows = [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.22),
          blurRadius: 0,
          spreadRadius: 3,
        ),
        const BoxShadow(
          color: Color(0x66000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ];
    } else if (running) {
      shadows = [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.30),
          blurRadius: 14,
        ),
        const BoxShadow(
          color: Color(0x66000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];
    } else {
      shadows = [
        const BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];
    }

    return SizedBox(
      width: width,
      height: height,
      child: MouseRegion(
        onEnter: (_) => onEnter?.call(),
        onExit: (_) => onExit?.call(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 34,
              top: 7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 124,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: running
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.accent.withValues(alpha: 0.14),
                                AppColors.bg3,
                              ],
                            )
                          : null,
                      color: running ? null : AppColors.bg3,
                      border: Border.all(
                        color: selected || running
                            ? AppColors.accent
                            : AppColors.border3,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: shadows,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TrailheadIcon(
                            icon: meta.icon,
                            size: 12,
                            color: running ? AppColors.accent : AppColors.fg0,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            meta.label,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: running ? AppColors.accent : AppColors.fg0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),
            // Delete button
            if (selected && onDelete != null)
              Positioned(
                top: -17,
                left: 15,
                child: GestureDetector(
                  onTap: onDelete,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: DeleteButton(),
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

final _routingMeta = <String, _RoutingMeta>{
  'branch': _RoutingMeta(label: 'branch', icon: TrailheadIconData.gitBranch),
};

class _RoutingMeta {
  final String label;
  final TrailheadIconData icon;
  const _RoutingMeta({required this.label, required this.icon});
}
