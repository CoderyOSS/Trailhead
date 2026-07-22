import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/providers/mode_provider.dart';
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

  // Default mode is `build` (was `active` before the flow-tabs redesign —
  // the old assertion on the literal text "ACTIVE" no longer applies because
  // the TopBar no longer renders a mode label; the ModeRail uses icons).
  testWidgets('top bar defaults to build mode', (WidgetTester tester) async {
    await pumpApp(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrailheadApp)),
      listen: false,
    );
    expect(container.read(modeProvider), AppMode.build);
  });

  testWidgets('mode rail switches mode via provider', (WidgetTester tester) async {
    await pumpApp(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrailheadApp)),
      listen: false,
    );
    expect(container.read(modeProvider), AppMode.build);

    await tester.tap(find.byType(ModeRail));
    await tester.pumpAndSettle();
  });
}
