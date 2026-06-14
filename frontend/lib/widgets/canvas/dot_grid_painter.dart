import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class DotGridPainter extends CustomPainter {
  final double zoom;
  final Offset pan;

  DotGridPainter({required this.zoom, required this.pan});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final spacing = 32.0 * zoom;
    final originX = pan.dx;
    final originY = pan.dy;

    // Axes — always draw
    final xAxisPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 1.5;
    final yAxisPaint = Paint()
      ..color = AppColors.trail
      ..strokeWidth = 1.5;

    if (originY >= 0 && originY <= size.height) {
      canvas.drawLine(
        Offset(0, originY),
        Offset(size.width, originY),
        xAxisPaint,
      );
    }
    if (originX >= 0 && originX <= size.width) {
      canvas.drawLine(
        Offset(originX, 0),
        Offset(originX, size.height),
        yAxisPaint,
      );
    }

    // Dot grid — hide when zoomed too far out
    if (spacing < 2) return;

    final paint = Paint()
      ..color = AppColors.fg4.withAlpha(77)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final startX = pan.dx % spacing;
    final startY = pan.dy % spacing;

    final dots = <Offset>[];
    for (double x = startX; x < size.width; x += spacing) {
      for (double y = startY; y < size.height; y += spacing) {
        dots.add(Offset(x, y));
      }
    }
    canvas.drawPoints(PointMode.points, dots, paint);
  }

  @override
  bool shouldRepaint(covariant DotGridPainter old) {
    return old.zoom != zoom || old.pan != pan;
  }
}
