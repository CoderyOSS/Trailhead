import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/widgets/mode_rail.dart';
import 'package:frontend/widgets/top_bar.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(child: TrailheadApp()));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  testWidgets('app renders mode rail, top bar, and shell', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.byType(ModeRail), findsOneWidget);
    expect(find.byType(TopBar), findsOneWidget);
    expect(find.byType(TrailheadShell), findsOneWidget);
  });

  testWidgets('top bar shows active mode content by default', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('ACTIVE'), findsOneWidget);
  });

  testWidgets('mode rail switches mode via provider', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('ACTIVE'), findsOneWidget);

    await tester.tap(find.byType(ModeRail));
    await tester.pumpAndSettle();
  });
}
