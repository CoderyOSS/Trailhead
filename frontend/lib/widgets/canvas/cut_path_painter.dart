import 'package:flutter/material.dart';
import '../../theme/theme_controller.dart';
import '../../theme/tokens.dart';

class CutPathPainter extends CustomPainter {
  final List<Offset> points;

  CutPathPainter({required this.points}) : super(repaint: ThemeController());

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = AppColors.danger
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CutPathPainter old) {
    return old.points != points;
  }
}
