import 'package:flutter/material.dart';
import '../../models/workflow_node.dart';
import '../../providers/mock_data.dart';
import '../../theme/tokens.dart';
import '../icons.dart';
import '../status_tag.dart';

class WorkerNode extends StatelessWidget {
  final WorkflowNode node;
  final JobState? status;
  final bool selected;
  final VoidCallback? onEnter;
  final VoidCallback? onExit;
  const WorkerNode({
    super.key,
    required this.node,
    this.status,
    this.selected = false,
    this.onEnter,
    this.onExit,
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

    return MouseRegion(
      onEnter: (_) => onEnter?.call(),
      onExit: (_) => onExit?.call(),
      child: Container(
        width: 160,
        height: 32,
        decoration: BoxDecoration(
          gradient: running
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.12),
                    AppColors.bg2,
                  ],
                  stops: const [0.0, 0.7],
                )
              : AppColors.loafGradient,
          border: Border.all(
            color: selected
                ? AppColors.accent
                : running
                    ? AppColors.accent
                    : AppColors.border2,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: outlineShadows,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
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
                    // Content — centered label only
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
                        child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (running)
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: StatusDot(
                                status: JobState.running,
                                pulse: true,
                                size: 5,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              node.label,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.fg0,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                    // Progress bar
                    if (running)
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 3,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.bg4,
                            borderRadius: BorderRadius.circular(1),
                          ),
                          child: const FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.55,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppColors.crustGradient,
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(1),
                                ),
                              ),
                            ),
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
