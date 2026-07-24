import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/theme_controller.dart';
import '../../theme/tokens.dart';

class DotGridPainter extends CustomPainter {
  final double zoom;
  final Offset pan;

  DotGridPainter({required this.zoom, required this.pan})
      : super(repaint: ThemeController());

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final spacing = 32.0 * zoom;
    final originX = pan.dx;
    final originY = pan.dy;

    // Axes + major grid lines — subtle theme-aware gray.
    // Origin axes always drawn; repeating lines every 10 grid units (= 320 world-px).
    final axisPaint = Paint()
      ..color = AppColors.chartGrid
      ..strokeWidth = 1.5;

    if (originY >= 0 && originY <= size.height) {
      canvas.drawLine(Offset(0, originY), Offset(size.width, originY), axisPaint);
    }
    if (originX >= 0 && originX <= size.width) {
      canvas.drawLine(Offset(originX, 0), Offset(originX, size.height), axisPaint);
    }

    const majorEvery = 10;
    final majorSpacing = spacing * majorEvery;
    if (majorSpacing >= 2) {
      final firstV = (-originX / majorSpacing).ceil();
      final lastV = ((size.width - originX) / majorSpacing).floor();
      for (var k = firstV; k <= lastV; k++) {
        if (k == 0) continue;
        final x = originX + k * majorSpacing;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), axisPaint);
      }
      final firstH = (-originY / majorSpacing).ceil();
      final lastH = ((size.height - originY) / majorSpacing).floor();
      for (var k = firstH; k <= lastH; k++) {
        if (k == 0) continue;
        final y = originY + k * majorSpacing;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
      }
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
