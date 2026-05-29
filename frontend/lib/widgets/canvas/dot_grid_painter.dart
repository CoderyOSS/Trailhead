import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/theme/tokens.dart';

class DotGridPainter extends CustomPainter {
  final double zoom;
  final Offset pan;

  DotGridPainter({required this.zoom, required this.pan});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final spacing = 24.0 * zoom;
    if (spacing < 2) return;

    final paint = Paint()
      ..color = AppColors.border2.withAlpha(89)
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
