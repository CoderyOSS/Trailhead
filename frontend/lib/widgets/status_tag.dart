import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../models/job_state.dart';

class StatusDot extends StatelessWidget {
  final JobState status;
  final bool pulse;
  final double size;

  StatusDot({
    super.key,
    required this.status,
    this.pulse = false,
    this.size = 6,
  });

  Color get _color {
    switch (status) {
      case JobState.running:
        return AppColors.accent;
      case JobState.cancelled:
        return AppColors.fg3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return pulse
        ? _PulsingDot(color: _color, size: size)
        : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  _PulsingDot({required this.color, required this.size});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
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
        final opacity = 0.74 + 0.26 * t;
        final blur = 2.0 + 7.0 * t;
        final spread = 0.0 + 2.0 * t;
        final alpha = (0.14 * 255 + 0.54 * 255 * t).round();

        return Opacity(
          opacity: opacity,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withAlpha(alpha),
                  blurRadius: blur,
                  spreadRadius: spread,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StatusTag extends StatelessWidget {
  final JobState status;

  StatusTag({super.key, required this.status});

  Color get _color {
    switch (status) {
      case JobState.running:
        return AppColors.accent;
      case JobState.cancelled:
        return AppColors.fg3;
    }
  }

  Color get _softBg {
    switch (status) {
      case JobState.running:
        return AppColors.accent.withValues(alpha: 0.15);
      case JobState.cancelled:
        return AppColors.bg3;
    }
  }

  String get _label {
    switch (status) {
      case JobState.running:
        return 'running';
      case JobState.cancelled:
        return 'cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _softBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusDot(
            status: status,
            pulse: status == JobState.running,
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
