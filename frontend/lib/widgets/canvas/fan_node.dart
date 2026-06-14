import 'package:flutter/material.dart';
import '../../models/workflow_node.dart';
import '../../providers/mock_data.dart';
import '../../theme/tokens.dart';
import '../icons.dart';

class FanNode extends StatelessWidget {
  final WorkflowNode node;
  final JobState? status;
  final bool selected;
  final VoidCallback? onEnter;
  final VoidCallback? onExit;
  final VoidCallback? onDelete;

  const FanNode({
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
    final statusColor = _statusColor(status);

    List<BoxShadow> outlineShadows;
    if (selected) {
      outlineShadows = [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.22),
          blurRadius: 4,
          spreadRadius: 4,
        ),
        const BoxShadow(
          color: Color(0x66000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];
    } else if (running) {
      outlineShadows = [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.30),
          blurRadius: 18,
        ),
        const BoxShadow(
          color: Color(0x66000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];
    } else {
      outlineShadows = [
        const BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];
    }

    // Static mock data
    const over = 'ingest.files';
    const count = 7;
    const bodyLabel = 'comment-file';

    return MouseRegion(
      onEnter: (_) => onEnter?.call(),
      onExit: (_) => onExit?.call(),
      child: Container(
        width: 160,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.bg2,
          border: Border.all(
            color: selected || running
                ? AppColors.accent
                : AppColors.border2,
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: outlineShadows,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    // Status rail
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: statusColor, width: 3),
                          ),
                        ),
                      ),
                    ),
                    // Header
                    Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: BoxDecoration(
                        gradient: selected || running
                            ? AppColors.crustGradient
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0x52e8923a),
                                  Color(0x2ee8923a),
                                ],
                              ),
                      ),
                      child: Row(
                        children: [
                          TrailheadIcon(
                            icon: TrailheadIconData.forEach,
                            size: 13,
                            color: selected || running
                                ? AppColors.accentInk
                                : AppColors.accent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'map',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: selected || running
                                  ? AppColors.accentInk
                                  : AppColors.accent,
                              letterSpacing: 0.02 * 10.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: selected || running
                                  ? const Color(0x2D000000)
                                  : const Color(0x38000000),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (running)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: selected || running
                                          ? AppColors.accentInk
                                          : AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  '×$count',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: selected || running
                                        ? AppColors.accentInk
                                        : AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Body
                    Positioned(
                      top: 26,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              bodyLabel,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.fg0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'over $over',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.5,
                                color: AppColors.fg3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Status badge
            if (status != null && !running && status != JobState.queued)
              Positioned(
                top: -8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: status == JobState.passed
                        ? AppColors.success
                        : status == JobState.failed
                            ? AppColors.danger
                            : AppColors.bg4,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status == JobState.cancelled ? 'cancelled' : status!.name,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: status == JobState.passed
                          ? const Color(0xFF1a3d1c)
                          : status == JobState.failed
                              ? const Color(0xFF3d1a1a)
                              : AppColors.fg2,
                    ),
                  ),
                ),
              ),
            // Delete button
            if (selected && onDelete != null)
              Positioned(
                top: -8,
                left: -8,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: TrailheadIcon(
                        icon: TrailheadIconData.x,
                        size: 9,
                        color: AppColors.fg2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(JobState? s) {
    if (s == null) return AppColors.border2;
    if (s == JobState.queued) return AppColors.border2.withValues(alpha: 0.4);
    return switch (s) {
      JobState.passed => AppColors.success,
      JobState.failed => AppColors.danger,
      JobState.running => AppColors.accent,
      JobState.retrying => AppColors.warning,
      _ => AppColors.border2,
    };
  }
}
