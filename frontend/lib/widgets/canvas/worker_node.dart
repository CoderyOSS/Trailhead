import 'package:flutter/material.dart';
import '../../models/workflow_node.dart';
import '../../models/job_state.dart';
import '../../theme/tokens.dart';
import '../icons.dart';
import '../status_tag.dart';

class WorkerNode extends StatelessWidget {
  final WorkflowNode node;
  final JobState? status;
  final bool selected;
  final CartaIconData icon;
  final VoidCallback? onEnter;
  final VoidCallback? onExit;

  /// Active-mode trigger affordance on the left cap (source.inject nodes on
  /// a deployed flow): pulsing glow + click cursor. The actual tap routing
  /// lives in the canvas's node GestureDetector (nested detectors lose the
  /// gesture arena to the parent node detector). When false the cap stays
  /// purely decorative.
  final bool triggerable;

  /// An inject is in flight — cap shows a spinner.
  final bool triggering;

  WorkerNode({
    super.key,
    required this.node,
    this.status,
    this.selected = false,
    this.icon = CartaIconData.bot,
    this.onEnter,
    this.onExit,
    this.triggerable = false,
    this.triggering = false,
  });

  @override
  Widget build(BuildContext context) {
    final running = status == JobState.running;

    List<BoxShadow> outlineShadows;
    if (selected) {
      outlineShadows = [
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              boxShadow: outlineShadows,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                decoration: BoxDecoration(gradient: bgGradient),
                child: Row(
                  children: [
                    MouseRegion(
                      cursor: triggerable && !triggering
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: Container(
                        width: 30,
                        decoration: BoxDecoration(
                          gradient: AppColors.crustGradient,
                          border: Border(
                            right: BorderSide(color: AppColors.border2),
                          ),
                        ),
                        child: Center(
                          child: triggering
                              ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accentInk,
                                  ),
                                )
                              : CartaIcon(
                                  icon: icon,
                                  size: 14,
                                  color: AppColors.accentInk,
                                ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (running)
                              Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: StatusDot(
                                  status: JobState.running,
                                  pulse: true,
                                  size: 5,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                node.label,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.fg0,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Layer 2: pulsing trigger glow (outside ClipRRect so it spills)
          if (triggerable)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 30,
              child: IgnorePointer(child: _TriggerCapGlow()),
            ),
          // Layer 3: border overlay
          Container(
            width: 168,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          if (node.hasInput) _ConnectorDot(left: true),
          if (node.hasOutput) _ConnectorDot(left: false),
          if (running)
            Positioned(
              left: 36,
              right: 10,
              bottom: 3,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.bg4,
                  borderRadius: BorderRadius.circular(1),
                ),
                child: FractionallySizedBox(
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
          if (status != null && !running)
            Positioned(
              top: -8,
              right: 8,
              child: _StatusBadge(status: status!),
            ),
          // Display-only channel chip on port nodes (peer counts and
          // cross-tab edge visualization are deferred by design).
          if (node.kind == 'port.in' || node.kind == 'port.out')
            Positioned(
              bottom: -8,
              right: 8,
              child: _ChannelChip(channel: node.channel),
            ),
        ],
      ),
    );
  }
}

/// Pulsing accent glow behind the trigger cap. Same timing/intensity as the
/// pulsing status dot on the active chip (`status_tag.dart`).
class _TriggerCapGlow extends StatefulWidget {
  @override
  State<_TriggerCapGlow> createState() => _TriggerCapGlowState();
}

class _TriggerCapGlowState extends State<_TriggerCapGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final blur = 2.0 + 7.0 * t;
        final spread = 0.0 + 2.0 * t;
        final alpha = (0.14 * 255 + 0.54 * 255 * t).round();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(AppRadius.md),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withAlpha(alpha),
                blurRadius: blur,
                spreadRadius: spread,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConnectorDot extends StatelessWidget {
  final bool left;
  _ConnectorDot({required this.left});

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
  _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.bg4,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.fg2,
        ),
      ),
    );
  }
}

/// Small pill under a port node showing its channel name. Display-only —
/// editing happens in the node drawer's channel field.
class _ChannelChip extends StatelessWidget {
  final String? channel;
  const _ChannelChip({required this.channel});

  @override
  Widget build(BuildContext context) {
    final unset = channel == null || channel!.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.bg4,
        border: Border.all(
          color: unset ? AppColors.warning : AppColors.border2,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        unset ? 'no channel' : channel!,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: unset ? AppColors.warning : AppColors.accent,
        ),
      ),
    );
  }
}
