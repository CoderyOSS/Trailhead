import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../providers/scissors_provider.dart';
import '../../theme/tokens.dart';
import '../icons.dart';

class ModeFlashOverlay extends StatefulWidget {
  final FlashMode mode;
  final VoidCallback onDismiss;

  ModeFlashOverlay({
    super.key,
    required this.mode,
    required this.onDismiss,
  });

  @override
  State<ModeFlashOverlay> createState() => _ModeFlashOverlayState();
}

class _ModeFlashOverlayState extends State<ModeFlashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.97)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 38,
      ),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 38,
      ),
    ]).animate(_controller);

    _controller.forward();

    _dismissTimer = Timer(const Duration(milliseconds: 820), () {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isScissors = widget.mode == FlashMode.scissors;

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: AppColors.bg1.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: isScissors ? AppColors.accent : AppColors.border2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: CartaIcon(
                          icon: isScissors
                              ? CartaIconData.scissors
                              : CartaIconData.mousePointer,
                          size: 62,
                          color: isScissors ? AppColors.accent : AppColors.fg0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isScissors ? 'scissors' : 'select mode',
                  style: TextStyle(
                    fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.52,
                    color: isScissors ? AppColors.accent : AppColors.fg2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
