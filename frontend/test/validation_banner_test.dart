import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/thrt_provider.dart';
import 'package:frontend/widgets/validation_banner.dart';

void main() {
  testWidgets('hidden when there are no validation errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          validationErrorsProvider
              .overrideWith((ref) => const <String>[]),
        ],
        child: const MaterialApp(home: Scaffold(body: ValidationBanner())),
      ),
    );

    expect(find.byType(Container), findsNothing);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets('renders each validation error verbatim', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          validationErrorsProvider.overrideWith((ref) => const [
                'node a: {:unknown_module_type, "mod.ghost.pkg"}',
                'path name: "missing"',
              ]),
        ],
        child: const MaterialApp(home: Scaffold(body: ValidationBanner())),
      ),
    );

    expect(
      find.text('node a: {:unknown_module_type, "mod.ghost.pkg"}'),
      findsOneWidget,
    );
    expect(find.text('path name: "missing"'), findsOneWidget);
  });
}
