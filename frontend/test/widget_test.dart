import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('gradient page renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const TrailheadApp());
    expect(find.byType(DecoratedBox), findsOneWidget);
  });
}
