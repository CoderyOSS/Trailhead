import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/canvas/marquee_painter.dart';

void main() {
  testWidgets('MarqueePainter draws a filled rect with border', (tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: CustomPaint(
          painter: MarqueePainter(const Rect.fromLTWH(10, 20, 100, 50)),
          size: const Size(200, 200),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('goldens/marquee_painter.png'),
    );
  });
}
