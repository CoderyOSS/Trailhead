import 'package:flutter/material.dart';
import '../../models/workflow_node.dart';
import '../../theme/tokens.dart';
import '../icons.dart';

class TransformNode extends StatelessWidget {
  final WorkflowNode node;
  final bool selected;
  final VoidCallback? onEnter;
  final VoidCallback? onExit;

  const TransformNode({
    super.key,
    required this.node,
    this.selected = false,
    this.onEnter,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.accent : AppColors.border2;

    final shadow = selected
        ? [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.22),
              blurRadius: 4,
              spreadRadius: 3,
            ),
            const BoxShadow(
              color: Color(0x66000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ]
        : [
            const BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ];

    return MouseRegion(
      onEnter: (_) => onEnter?.call(),
      onExit: (_) => onExit?.call(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 168,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              boxShadow: shadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                decoration: BoxDecoration(gradient: AppColors.loafGradient),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      decoration: BoxDecoration(
                        color: AppColors.fg3.withValues(alpha: 0.08),
                        border: Border(
                          right: BorderSide(color: AppColors.border2),
                        ),
                      ),
                      child: Center(
                        child: TrailheadIcon(
                          icon: TrailheadIconData.terminal,
                          size: 14,
                          color: AppColors.fg0,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          node.label,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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
