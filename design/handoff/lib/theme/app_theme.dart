// lib/theme/app_theme.dart
//
// Material 3 ThemeData + a custom ThemeExtension (`AppTokens`) for the
// values that don't fit cleanly into ColorScheme — surface elevation
// levels, syntax highlight colors, soft semantic tints, shadows, etc.
//
// Read this file second, after `tokens.dart`.
//
// Usage:
//   MaterialApp(
//     theme: appTheme(palette: AppPalettes.slate, accent: AppAccents.orangeOnSlate),
//     ...
//   );
//
//   // In a component:
//   final t = Theme.of(context).extension<AppTokens>()!;
//   Container(color: t.palette.surface, ...);

import 'package:flutter/material.dart';
import 'tokens.dart';

// ════════════════════════════════════════════════════════════════════════
//  AppTokens — non-M3 design tokens packaged as a ThemeExtension
// ════════════════════════════════════════════════════════════════════════

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.palette,
    required this.accent,
  });

  final ThemePalette palette;
  final AccentPalette accent;

  /// Look up a status color (base + soft) using the active palette + accent.
  StatusColor statusColor(WorkflowStatus s) =>
      AppStatusColors.of(s, palette, accent);

  @override
  AppTokens copyWith({ThemePalette? palette, AccentPalette? accent}) {
    return AppTokens(
      palette: palette ?? this.palette,
      accent:  accent  ?? this.accent,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    // Palettes & accents change discretely — no per-color interpolation.
    if (other is! AppTokens) return this;
    return t < 0.5 ? this : other;
  }
}

// ════════════════════════════════════════════════════════════════════════
//  TextTheme — derived from AppType primitives
// ════════════════════════════════════════════════════════════════════════

TextTheme _buildTextTheme(ThemePalette p) {
  TextStyle base({
    required double size,
    FontWeight weight = AppType.regular,
    String family = AppType.sans,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? p.text,
    );
  }

  return TextTheme(
    // displays — Bricolage (header titles like "Workflows", "Past jobs")
    displayLarge:  base(size: AppType.t5xl, family: AppType.display, weight: AppType.bold,    height: 1.08, letterSpacing: -0.40, color: p.textStrong),
    displayMedium: base(size: AppType.t3xl, family: AppType.display, weight: AppType.semibold, height: 1.25, letterSpacing: -0.24, color: p.textStrong),
    displaySmall:  base(size: AppType.txl,  family: AppType.display, weight: AppType.semibold, height: 1.25, color: p.textStrong),
    // headlines / titles
    headlineMedium: base(size: AppType.tlg, family: AppType.display, weight: AppType.semibold, color: p.textStrong),
    titleLarge:     base(size: AppType.tmd, weight: AppType.semibold, color: p.textStrong),
    titleMedium:    base(size: AppType.tbase, weight: AppType.semibold, color: p.textStrong),
    titleSmall:     base(size: AppType.tsm,   weight: AppType.medium,   color: p.text),
    // body
    bodyLarge:  base(size: AppType.tbase, height: 1.5),
    bodyMedium: base(size: AppType.tsm,   height: 1.5),
    bodySmall:  base(size: AppType.txs,   color: p.textMuted),
    // labels — used for buttons, chips, tags
    labelLarge:  base(size: AppType.tsm,  weight: AppType.medium),
    labelMedium: base(size: AppType.txs,  weight: AppType.medium, color: p.textMuted),
    labelSmall:  base(size: AppType.t2xs, weight: AppType.medium, family: AppType.mono, letterSpacing: 1.20, color: p.textSubtle),
  );
}

// ════════════════════════════════════════════════════════════════════════
//  ColorScheme — map palette + accent to Material 3 roles
// ════════════════════════════════════════════════════════════════════════

ColorScheme _buildColorScheme(ThemePalette p, AccentPalette a) {
  return ColorScheme(
    brightness: p.brightness,
    primary:           a.accent,
    onPrimary:         a.accentInk,
    primaryContainer:  a.accent200,
    onPrimaryContainer:p.textStrong,

    secondary:         p.fg2,
    onSecondary:       p.bg0,
    secondaryContainer: p.bg3,
    onSecondaryContainer: p.textStrong,

    tertiary:          p.info,
    onTertiary:        p.bg0,

    error:             p.danger,
    onError:           p.bg0,
    errorContainer:    p.dangerSoft,
    onErrorContainer:  p.danger,

    surface:           p.bg1,
    onSurface:         p.text,
    surfaceContainer:        p.bg2,
    surfaceContainerLow:     p.bg2,
    surfaceContainerLowest:  p.bg1,
    surfaceContainerHigh:    p.bg3,
    surfaceContainerHighest: p.bg4,
    onSurfaceVariant:        p.textMuted,

    outline:           p.border2,
    outlineVariant:    p.border1,

    inverseSurface:    p.bg5,
    onInverseSurface:  p.textStrong,
    inversePrimary:    a.accent300,

    surfaceTint:       a.accent,
    shadow:            Color(0xCC000000),
    scrim:             Color(0xB3000000),
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Top-level builder — call this from MaterialApp.theme
// ════════════════════════════════════════════════════════════════════════

ThemeData appTheme({
  required ThemePalette palette,
  required AccentPalette accent,
}) {
  final scheme = _buildColorScheme(palette, accent);
  final textTheme = _buildTextTheme(palette);

  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.pageBg,
    canvasColor: palette.pageBg,
    dividerColor: palette.divider,

    textTheme: textTheme,
    fontFamily: AppType.sans,

    // ── Component themes ────────────────────────────────────────────────
    iconTheme: IconThemeData(color: palette.textMuted, size: AppIconSize.md),

    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.all_md,
        side: BorderSide(color: palette.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    dividerTheme: DividerThemeData(
      color: palette.divider,
      thickness: 1,
      space: 1,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      hoverColor: palette.surfaceHover,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: AppRadius.all_md,
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.all_md,
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.all_md,
        borderSide: BorderSide(color: accent.accent, width: 1.5),
      ),
      hintStyle: TextStyle(color: palette.textSubtle, fontFamily: AppType.mono, fontSize: 12),
      labelStyle: TextStyle(color: palette.textMuted, fontFamily: AppType.mono, fontSize: 11),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent.accent,
        foregroundColor: accent.accentInk,
        minimumSize: CompButton.mdMin,
        padding: CompButton.mdPadding,
        textStyle: TextStyle(
          fontFamily: AppType.sans,
          fontSize: CompButton.mdFontSize,
          fontWeight: AppType.medium,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all_sm),
        elevation: 0,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.surfaceRaised,
        foregroundColor: palette.textStrong,
        minimumSize: CompButton.mdMin,
        padding: CompButton.mdPadding,
        textStyle: TextStyle(
          fontFamily: AppType.sans,
          fontSize: CompButton.mdFontSize,
          fontWeight: AppType.medium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all_sm,
          side: BorderSide(color: palette.border, width: 1),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.text,
        minimumSize: CompButton.smMin,
        padding: CompButton.smPadding,
        textStyle: TextStyle(
          fontFamily: AppType.sans,
          fontSize: CompButton.smFontSize,
          fontWeight: AppType.medium,
        ),
      ),
    ),

    extensions: <ThemeExtension<dynamic>>[
      AppTokens(palette: palette, accent: accent),
    ],
  );
}

/// Convenience — the default project theme (Slate + Orange).
ThemeData defaultDarkTheme() => appTheme(
  palette: AppPalettes.slate,
  accent:  AppAccents.orangeOnSlate,
);

/// Convenience — Paper light theme with the orange accent.
ThemeData defaultLightTheme() => appTheme(
  palette: AppPalettes.paper,
  accent:  AppAccents.orangeOnPaper,
);
