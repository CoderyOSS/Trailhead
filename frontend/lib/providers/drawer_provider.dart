import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unified drawer state (settings + logs in one panel).
///
/// Open state is session-only; view mode, split layout, sizes, and split
/// fraction persist via shared_preferences (localStorage on web).

/// Which panes the unified drawer shows.
enum DrawerViewMode { logs, settings, both }

/// Internal arrangement of the two panes when [DrawerViewMode.both]:
/// horizontal = side-by-side columns, vertical = stacked rows.
enum DrawerSplitLayout { horizontal, vertical }

/// Drawer open/closed. Session-only — never persisted. Replaces the old
/// nodeDrawerOpenProvider; selection no longer gates visibility.
final drawerOpenProvider = StateProvider<bool>((ref) => false);

/// Last-used view mode, remembered globally across sessions.
final drawerViewModeProvider =
    StateProvider<DrawerViewMode>((ref) => DrawerViewMode.both);

/// Internal split direction for the two-pane view.
final drawerLayoutProvider =
    StateProvider<DrawerSplitLayout>((ref) => DrawerSplitLayout.horizontal);

/// Outer drawer extent in px: width in landscape, height in portrait.
/// Stored per orientation.
final drawerSizeProvider =
    StateProvider<({double landscape, double portrait})>(
  (ref) => (landscape: 520, portrait: 320),
);

/// Fraction (0..1) of the content area given to the logs pane in
/// [DrawerViewMode.both]. The settings pane gets the remainder.
final drawerSplitProvider = StateProvider<double>((ref) => 0.5);

// ── Persistence ──────────────────────────────────────────────────────────

const _kViewMode = 'drawer.viewMode';
const _kLayout = 'drawer.layout';
const _kSizeLandscape = 'drawer.size.landscape';
const _kSizePortrait = 'drawer.size.portrait';
const _kSplit = 'drawer.split';

Timer? _saveTimer;

/// Load persisted drawer prefs into the providers. Call once from the app
/// shell's initState.
Future<void> loadDrawerPrefs(WidgetRef ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final vm = prefs.getString(_kViewMode);
    if (vm != null) {
      ref.read(drawerViewModeProvider.notifier).state =
          DrawerViewMode.values.asNameMap()[vm] ?? DrawerViewMode.both;
    }
    final layout = prefs.getString(_kLayout);
    if (layout != null) {
      ref.read(drawerLayoutProvider.notifier).state =
          DrawerSplitLayout.values.asNameMap()[layout] ??
              DrawerSplitLayout.horizontal;
    }
    final ls = prefs.getDouble(_kSizeLandscape);
    final ps = prefs.getDouble(_kSizePortrait);
    if (ls != null || ps != null) {
      final cur = ref.read(drawerSizeProvider);
      ref.read(drawerSizeProvider.notifier).state = (
        landscape: ls ?? cur.landscape,
        portrait: ps ?? cur.portrait,
      );
    }
    final split = prefs.getDouble(_kSplit);
    if (split != null) {
      ref.read(drawerSplitProvider.notifier).state = split.clamp(0.1, 0.9);
    }
  } catch (e) {
    debugPrint('drawer prefs load failed: $e');
  }
}

/// Debounced write of all drawer prefs. Call after any drawer pref change.
void scheduleDrawerPrefsSave(WidgetRef ref) {
  _saveTimer?.cancel();
  _saveTimer = Timer(const Duration(milliseconds: 300), () async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kViewMode, ref.read(drawerViewModeProvider).name);
      await prefs.setString(_kLayout, ref.read(drawerLayoutProvider).name);
      final size = ref.read(drawerSizeProvider);
      await prefs.setDouble(_kSizeLandscape, size.landscape);
      await prefs.setDouble(_kSizePortrait, size.portrait);
      await prefs.setDouble(_kSplit, ref.read(drawerSplitProvider));
    } catch (e) {
      debugPrint('drawer prefs save failed: $e');
    }
  });
}

// ── Sizing constraints ───────────────────────────────────────────────────

/// Minimum px each pane gets in the two-pane split (logs or settings).
const double drawerMinPaneExtent = 120;

/// Clamp the outer drawer extent for the current orientation/screen.
double clampDrawerExtent(double px, bool isPortrait, Size screen) {
  final max =
      isPortrait ? screen.height * 0.7 : screen.width * 0.8;
  final min = isPortrait ? 240.0 : 360.0;
  return px.clamp(min, max);
}

/// Clamp a split fraction so both panes keep [drawerMinPaneExtent] px.
double clampDrawerSplit(double fraction, double totalExtent) {
  if (totalExtent <= 0) return fraction.clamp(0.1, 0.9);
  final minFrac = (drawerMinPaneExtent / totalExtent).clamp(0.0, 0.5);
  return fraction.clamp(minFrac, 1 - minFrac);
}
