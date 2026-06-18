import 'package:flutter/material.dart';
import '../../models/workflow_node.dart';
import '../../providers/mock_data.dart';
import '../../theme/tokens.dart';
import '../icons.dart';

class BranchNode extends StatelessWidget {
  final WorkflowNode node;
  final JobState? status;
  final bool selected;
  final VoidCallback? onEnter;
  final VoidCallback? onExit;
  const BranchNode({
    super.key,
    required this.node,
    this.status,
    this.selected = false,
    this.onEnter,
    this.onExit,
  });

  static const double width = 130;
  static const double rowHeight = 27;
  static const double padY = 9;

  double get height => padY * 2 + _outputs.length * rowHeight;

  List<BranchOutput> get _outputs =>
      node.outputs.isNotEmpty ? node.outputs : WorkflowNode.defaultBranchOutputs;

  @override
  Widget build(BuildContext context) {
    final running = status == JobState.running;
    final outputs = _outputs;
    final h = height;

    List<BoxShadow> outlineShadows;
    if (selected) {
      outlineShadows = [
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
      outlineShadows = [
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
        width: width,
        height: h,
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
            SizedBox.expand(
              child: Row(
                children: [
                  Container(
                    width: 30,
                    decoration: const BoxDecoration(
                      gradient: AppColors.crustGradient,
                      border: Border(
                        right: BorderSide(color: AppColors.border2),
                      ),
                    ),
                    child: const Center(
                      child: TrailheadIcon(
                        icon: TrailheadIconData.gitBranch,
                        size: 14,
                        color: AppColors.accentInk,
                      ),
                    ),
                  ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: padY),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: outputs.map((c) {
                            return SizedBox(
                              height: rowHeight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12, left: 11),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    c.label,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: c.id == '3' ? FontWeight.w500 : FontWeight.w600,
                                      color: c.id == '3' ? AppColors.fg3 : AppColors.fg0,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Input dot
            Positioned(
              left: -4,
              top: h / 2 - 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border3, width: 1.5),
                ),
              ),
            ),
            // Output dots
            ...outputs.asMap().entries.map((e) {
              final i = e.key;
              final top = padY + i * rowHeight + rowHeight / 2 - 4;
              return Positioned(
                right: -4,
                top: top,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.bg3,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border3, width: 1.5),
                  ),
                ),
              );
            }),
            if (status != null && !running && status != JobState.queued)
              Positioned(
                top: -8,
                right: 8,
                child: _StatusBadge(status: status!),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final JobState status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        status == JobState.cancelled ? 'cancelled' : status.name,
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
    );
  }
}
