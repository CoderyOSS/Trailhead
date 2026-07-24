import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/carta_provider.dart';
import 'package:frontend/providers/configs_provider.dart';
import 'package:frontend/services/carta_api.dart';
import 'package:frontend/services/configs_api.dart';
import 'package:frontend/widgets/settings/configs_section.dart';

class _FakeConfigsApi extends ConfigsApi {
  _FakeConfigsApi() : super('/api/v1');
  @override
  Future<List<ConfigDto>> list() async => const [
        ConfigDto(key: 'db', source: '%{host: "h"}', updatedAt: '2026-07-23T00:00:00Z'),
        ConfigDto(key: 'cache', source: '%{ttl: 60}', updatedAt: null),
      ];
}

/// Stub CartaApi — only validateElixirTerm is reached by ConfigsSection.
/// Returns `ok: true` for everything so the PayloadEditor pip is happy and
/// the card's `_isValid` flag stays true (otherwise `_save` short-circuits).
class _StubCartaApi extends CartaApi {
  _StubCartaApi() : super('/api/v1');
  @override
  Future<TermValidationResult> validateElixirTerm(String code,
      {bool isExpr = false}) async {
    return TermValidationResult.good();
  }
}

/// Recording fake — tracks replace() calls and can be programmed to fail.
class _RecordingApi extends ConfigsApi {
  _RecordingApi.fromSource(String source, {this.failReplace = false})
      : _initial = ConfigDto(key: 'k', source: source, updatedAt: null),
        super('/api/v1');

  final ConfigDto _initial;
  final List<String> replaces = [];
  int listCalls = 0;
  // When true, replace() throws ConfigsApiException(400, 'bad').
  bool failReplace;

  @override
  Future<List<ConfigDto>> list() async {
    listCalls++;
    return [_initial];
  }

  @override
  Future<void> replace(String key, String source) async {
    replaces.add(source);
    if (failReplace) {
      throw ConfigsApiException(400, 'invalid literal');
    }
  }
}

void main() {
  testWidgets('renders config keys from the provider', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [configsApiProvider.overrideWithValue(_FakeConfigsApi())],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ConfigsSection()),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('db'), findsOneWidget);
    expect(find.text('cache'), findsOneWidget);
    expect(find.textContaining('CONFIGS (2)'), findsOneWidget);
  });

  testWidgets('shows empty-state copy when there are no configs', (tester) async {
    final fake = _FakeEmptyApi();
    await tester.pumpWidget(ProviderScope(
      overrides: [configsApiProvider.overrideWithValue(fake)],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ConfigsSection()),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('No configuration objects yet'), findsOneWidget);
  });

  testWidgets('debounce collapses rapid edits into a single PUT',
      (tester) async {
    final fake = _RecordingApi.fromSource('%{}');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        configsApiProvider.overrideWithValue(fake),
        cartaApiProvider.overrideWithValue(_StubCartaApi()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ConfigsSection()),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Expand the card to mount the editor.
    await tester.tap(find.text('k'));
    await tester.pumpAndSettle();

    // Type three keystrokes back-to-back. The save timer resets each time.
    await tester.enterText(find.byType(TextField).last, '%{a: 1}');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField).last, '%{a: 2}');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField).last, '%{a: 3}');
    await tester.pump(const Duration(milliseconds: 500));

    // Still before the 1.5s debounce elapses — no PUT should have fired.
    expect(fake.replaces, isEmpty);

    // Wait out the debounce. Exactly one PUT with the latest value.
    await tester.pump(const Duration(milliseconds: 1600));
    expect(fake.replaces, ['%{a: 3}']);
  });

  testWidgets('a failed PUT shows an inline error and clears on next edit',
      (tester) async {
    final fake = _RecordingApi.fromSource('%{}', failReplace: true);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        configsApiProvider.overrideWithValue(fake),
        cartaApiProvider.overrideWithValue(_StubCartaApi()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ConfigsSection()),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('k'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '%{a: 1}');
    await tester.pump(const Duration(milliseconds: 1600));

    // Inline error banner appears (not a SnackBar).
    expect(find.textContaining('Save failed'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    // Typing again clears the banner immediately.
    await tester.enterText(find.byType(TextField).last, '%{a: 2}');
    await tester.pump();
    expect(find.textContaining('Save failed'), findsNothing);
  });

  testWidgets('a successful PUT invalidates configsProvider (refetch)',
      (tester) async {
    final fake = _RecordingApi.fromSource('%{}');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        configsApiProvider.overrideWithValue(fake),
        cartaApiProvider.overrideWithValue(_StubCartaApi()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ConfigsSection()),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // Initial load.
    expect(fake.listCalls, 1);

    await tester.tap(find.text('k'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '%{a: 1}');
    await tester.pump(const Duration(milliseconds: 1600));

    // After a successful replace, the provider is invalidated → refetched.
    expect(fake.replaces, ['%{a: 1}']);
    expect(fake.listCalls, greaterThan(1));
  });
}

class _FakeEmptyApi extends ConfigsApi {
  _FakeEmptyApi() : super('/api/v1');
  @override
  Future<List<ConfigDto>> list() async => const [];
}
