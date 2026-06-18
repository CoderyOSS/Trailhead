import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class MarqueePainter extends CustomPainter {
  final Rect rect;

  const MarqueePainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = AppColors.accent.withValues(alpha: 0.12);
    final border = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, border);
  }

  @override
  bool shouldRepaint(covariant MarqueePainter old) => old.rect != rect;
}
