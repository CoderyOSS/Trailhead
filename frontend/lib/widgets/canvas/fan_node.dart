import 'package:flutter/material.dart';
import '../../models/workflow_node.dart';
import '../../providers/mock_data.dart';
import '../../theme/tokens.dart';
import '../icons.dart';

class MapNode extends StatelessWidget {
  final WorkflowNode node;
  final JobState? status;
  final bool selected;
  final VoidCallback? onEnter;
  final VoidCallback? onExit;
  const MapNode({
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

    final bgGradient = running
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.accent.withValues(alpha: 0.12),
              AppColors.bg2,
            ],
            stops: const [0.0, 0.7],
          )
        : AppColors.loafGradient;
    final borderColor = selected
        ? AppColors.accent
        : running
            ? AppColors.accent
            : AppColors.border2;

    return MouseRegion(
      onEnter: (_) => onEnter?.call(),
      onExit: (_) => onExit?.call(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Layer 1: shadow + clipped content
          Container(
            width: 168,
            height: 36,
            decoration: BoxDecoration(boxShadow: outlineShadows),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                decoration: BoxDecoration(gradient: bgGradient),
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
                          icon: TrailheadIconData.forEach,
                          size: 14,
                          color: AppColors.accentInk,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          node.label,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fg0,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Layer 2: border overlay
          Container(
            width: 168,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          _ConnectorDot(left: true),
          _ConnectorDot(left: false),
          if (status != null && !running && status != JobState.queued)
            Positioned(
              top: -8,
              right: 8,
              child: _StatusBadge(status: status!),
            ),
        ],
      ),
    );
  }
}

class _ConnectorDot extends StatelessWidget {
  final bool left;
  const _ConnectorDot({required this.left});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left ? -4 : null,
      right: left ? null : -4,
      top: 14,
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
