import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/providers/drawer_provider.dart';
import 'package:frontend/widgets/drawer_panel.dart';
import 'package:frontend/widgets/icons.dart';
import 'package:frontend/widgets/node_drawer/node_drawer.dart';

Finder _panelIcon(CartaIconData icon) => find.byWidgetPredicate(
      (w) => w is CartaIcon && w.icon == icon,
    );

Widget _host({NodeDrawerView view = NodeDrawerView.builder}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1000,
          height: 600,
          child: UnifiedDrawer(
            node: null,
            view: view,
            nodeKey: const GlobalObjectKey('test_none_builder'),
            onClose: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders header with 3-state switch; empty state with no node',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('logs'), findsOneWidget);
    // 'settings' appears in the segmented control AND the empty-state
    // header title.
    expect(find.text('settings'), findsNWidgets(2));
    expect(find.text('both'), findsOneWidget);
    // Default view mode is both: settings pane shows the no-selection
    // empty state alongside the logs pane.
    expect(find.text('select a node on the canvas'), findsOneWidget);
    // Split-direction toggle only visible in both mode. Default layout is
    // verticalSplit (side-by-side columns); the icon shows the action
    // (switch to horizontalSplit / stacked rows), not the current state.
    expect(_panelIcon(CartaIconData.panelBottom), findsOneWidget);
  });

  testWidgets('switching to logs-only hides the settings pane',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('logs'));
    await tester.pumpAndSettle();
    // Flush the debounced prefs-save timer (300ms).
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('select a node on the canvas'), findsNothing);
    // Layout toggle hidden when not in both mode.
    expect(_panelIcon(CartaIconData.panelRight), findsNothing);
    expect(_panelIcon(CartaIconData.panelBottom), findsNothing);
  });

  testWidgets('layout toggle flips split direction', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(_panelIcon(CartaIconData.panelBottom));
    await tester.pumpAndSettle();
    expect(_panelIcon(CartaIconData.panelRight), findsOneWidget);
    expect(_panelIcon(CartaIconData.panelBottom), findsNothing);
    // Flush the debounced prefs-save timer (300ms).
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('close button shown in build mode, hidden when forced open',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: UnifiedDrawer(
                node: null,
                view: NodeDrawerView.job,
                nodeKey: const GlobalObjectKey('test_none_job'),
                onClose: () {},
                forcedOpen: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsNothing);
  });
}
