// lib/theme/tokens.dart
//
// Type-safe Dart mirror of `tokens.json`.
// Source of truth: tokens.json. Regenerate this file if tokens change.
//
// Usage:
//   import 'package:trailhead/theme/tokens.dart';
//   Container(color: AppColors.slate.bg1, padding: EdgeInsets.all(AppSpacing.s6));

import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════════════
//  PRIMITIVES — invariant across themes
// ════════════════════════════════════════════════════════════════════════

class AppSpacing {
  AppSpacing._();
  // 4px base. Indices match tokens.json `primitives.spacing.scale`.
  static const double s1  = 2;
  static const double s2  = 4;
  static const double s3  = 6;
  static const double s4  = 8;
  static const double s5  = 12;
  static const double s6  = 16;
  static const double s7  = 20;
  static const double s8  = 24;
  static const double s9  = 32;
  static const double s10 = 40;
  static const double s11 = 48;
  static const double s12 = 64;
  static const double s13 = 80;
  static const double s14 = 96;
}

class AppRadius {
  AppRadius._();
  static const double xs   = 4;
  static const double sm   = 6;
  static const double md   = 10;
  static const double lg   = 14;
  static const double xl   = 20;
  static const double r2xl = 28;
  static const double pill = 999;

  static const Radius rxs   = Radius.circular(xs);
  static const Radius rsm   = Radius.circular(sm);
  static const Radius rmd   = Radius.circular(md);
  static const Radius rlg   = Radius.circular(lg);
  static const Radius rxl   = Radius.circular(xl);
  static const Radius r2xlR = Radius.circular(r2xl);
  static const Radius rpill = Radius.circular(pill);

  static const BorderRadius all_xs   = BorderRadius.all(rxs);
  static const BorderRadius all_sm   = BorderRadius.all(rsm);
  static const BorderRadius all_md   = BorderRadius.all(rmd);
  static const BorderRadius all_lg   = BorderRadius.all(rlg);
  static const BorderRadius all_pill = BorderRadius.all(rpill);
}

class AppType {
  AppType._();

  // Font families — assume these are loaded via google_fonts or
  // bundled in pubspec.yaml as TTF assets.
  static const String display = 'Bricolage Grotesque';
  static const String sans    = 'Plus Jakarta Sans';
  static const String mono    = 'JetBrains Mono';

  // Scale (logical px)
  static const double t3xs = 10;
  static const double t2xs = 11;
  static const double txs  = 12;
  static const double tsm  = 13;
  static const double tbase= 14;
  static const double tmd  = 15;
  static const double tlg  = 17;
  static const double txl  = 20;
  static const double t2xl = 24;
  static const double t3xl = 30;
  static const double t4xl = 38;
  static const double t5xl = 52;

  // Weights
  static const FontWeight regular  = FontWeight.w400;
  static const FontWeight medium   = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold     = FontWeight.w700;
}

class AppMotion {
  AppMotion._();
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast    = Duration(milliseconds: 160);
  static const Duration base    = Duration(milliseconds: 240);
  static const Duration slow    = Duration(milliseconds: 380);

  static const Curve easeOut   = Cubic(0.20, 0.80, 0.20, 1.00);
  static const Curve easeInOut = Cubic(0.40, 0.00, 0.20, 1.00);
  static const Curve easeSnap  = Cubic(0.32, 0.72, 0.00, 1.00);
  static const Curve easeSoft  = Cubic(0.34, 1.10, 0.64, 1.00);
}

class AppIconSize {
  AppIconSize._();
  static const double xs = 9;
  static const double sm = 11;
  static const double md = 13;
  static const double lg = 16;
  static const double xl = 22;
}

// ════════════════════════════════════════════════════════════════════════
//  THEME PALETTES
// ════════════════════════════════════════════════════════════════════════

class ThemePalette {
  const ThemePalette({
    required this.brightness,
    required this.bg0,  required this.bg1, required this.bg2,
    required this.bg3,  required this.bg4, required this.bg5,
    required this.fg0,  required this.fg1, required this.fg2,
    required this.fg3,  required this.fg4, required this.fg5,
    required this.border1, required this.border2, required this.border3,
    required this.success,  required this.successSoft,
    required this.warning,  required this.warningSoft,
    required this.danger,   required this.dangerSoft,
    required this.info,     required this.infoSoft,
    required this.synKeyword, required this.synString,   required this.synNumber,
    required this.synComment, required this.synFunction, required this.synType,
    required this.synPunct,
    required this.shadow1, required this.shadow2, required this.shadow3,
  });

  final Brightness brightness;
  final Color bg0, bg1, bg2, bg3, bg4, bg5;
  final Color fg0, fg1, fg2, fg3, fg4, fg5;
  final Color border1, border2, border3;
  final Color success, successSoft;
  final Color warning, warningSoft;
  final Color danger,  dangerSoft;
  final Color info,    infoSoft;
  final Color synKeyword, synString, synNumber, synComment,
              synFunction, synType, synPunct;
  final List<BoxShadow> shadow1, shadow2, shadow3;

  // Semantic aliases — components reference these.
  Color get pageBg         => bg0;
  Color get appShell       => bg1;
  Color get surface        => bg2;
  Color get surfaceRaised  => bg3;
  Color get surfaceOverlay => bg4;
  Color get surfaceHover   => bg3;
  Color get textStrong     => fg0;
  Color get text           => fg1;
  Color get textMuted      => fg2;
  Color get textSubtle     => fg3;
  Color get textDisabled   => fg4;
  Color get divider        => border1;
  Color get border         => border2;
  Color get borderStrong   => border3;
}

// ── Slate (default dark) ─────────────────────────────────────────────────
class _PaletteSlate {
  static const ThemePalette palette = ThemePalette(
    brightness: Brightness.dark,
    bg0: Color(0xFF0C0D10), bg1: Color(0xFF14161B), bg2: Color(0xFF1A1D23),
    bg3: Color(0xFF22262D), bg4: Color(0xFF2B303A), bg5: Color(0xFF353B46),
    fg0: Color(0xFFF3F4F6), fg1: Color(0xFFD8DADE), fg2: Color(0xFFA5A9B1),
    fg3: Color(0xFF777B84), fg4: Color(0xFF565A62), fg5: Color(0xFF3D4148),
    border1: Color(0xFF21242A),
    border2: Color(0xFF2E323A),
    border3: Color(0xFF40454F),
    success: Color(0xFF6FBF73), successSoft: Color(0x296FBF73),
    warning: Color(0xFFE6B341), warningSoft: Color(0x2EE6B341),
    danger:  Color(0xFFE26464), dangerSoft:  Color(0x2EE26464),
    info:    Color(0xFF6EA8D9), infoSoft:    Color(0x2E6EA8D9),
    synKeyword:  Color(0xFFC98A5E),
    synString:   Color(0xFFA0C97B),
    synNumber:   Color(0xFFE6B341),
    synComment:  Color(0xFF6A6E76),
    synFunction: Color(0xFF7EB6E6),
    synType:     Color(0xFFD4A3D4),
    synPunct:    Color(0xFF777B84),
    shadow1: <BoxShadow>[
      BoxShadow(color: Color(0x80000000), offset: Offset(0, 2),  blurRadius: 6),
    ],
    shadow2: <BoxShadow>[
      BoxShadow(color: Color(0x8C000000), offset: Offset(0, 6),  blurRadius: 18),
    ],
    shadow3: <BoxShadow>[
      BoxShadow(color: Color(0x99000000), offset: Offset(0, 16), blurRadius: 40),
    ],
  );
}

// ── Paper (light) ────────────────────────────────────────────────────────
class _PalettePaper {
  static const ThemePalette palette = ThemePalette(
    brightness: Brightness.light,
    bg0: Color(0xFFF5F2EC), bg1: Color(0xFFFDFBF6), bg2: Color(0xFFF3EFE6),
    bg3: Color(0xFFE8E3D6), bg4: Color(0xFFDCD6C4), bg5: Color(0xFFC9C2AD),
    fg0: Color(0xFF1A1814), fg1: Color(0xFF3A352D), fg2: Color(0xFF5D564A),
    fg3: Color(0xFF837B6C), fg4: Color(0xFFA8A193), fg5: Color(0xFFC9C2AD),
    border1: Color(0xFFEBE6D8),
    border2: Color(0xFFD8D2C0),
    border3: Color(0xFFB5AD96),
    success: Color(0xFF5E8A3F), successSoft: Color(0x1F5E8A3F),
    warning: Color(0xFFB8780F), warningSoft: Color(0x1FB8780F),
    danger:  Color(0xFFB8331F), dangerSoft:  Color(0x1FB8331F),
    info:    Color(0xFF325F8A), infoSoft:    Color(0x1F325F8A),
    synKeyword:  Color(0xFF944F0C),
    synString:   Color(0xFF5E8A3F),
    synNumber:   Color(0xFFA04400),
    synComment:  Color(0xFFA8A193),
    synFunction: Color(0xFF325F8A),
    synType:     Color(0xFF7A3EBA),
    synPunct:    Color(0xFF837B6C),
    shadow1: <BoxShadow>[
      BoxShadow(color: Color(0x0F4A2F1A), offset: Offset(0, 1),  blurRadius: 2),
    ],
    shadow2: <BoxShadow>[
      BoxShadow(color: Color(0x1A4A2F1A), offset: Offset(0, 4),  blurRadius: 12),
    ],
    shadow3: <BoxShadow>[
      BoxShadow(color: Color(0x294A2F1A), offset: Offset(0, 16), blurRadius: 40),
    ],
  );
}

class AppPalettes {
  AppPalettes._();
  static const ThemePalette slate = _PaletteSlate.palette;
  static const ThemePalette paper = _PalettePaper.palette;
}

// ════════════════════════════════════════════════════════════════════════
//  ACCENTS — orthogonal axis on top of the theme palette
// ════════════════════════════════════════════════════════════════════════

class AccentPalette {
  const AccentPalette({
    required this.accent200, required this.accent300,
    required this.accent400, required this.accent500, required this.accent600,
    required this.accent,    required this.accentInk, required this.accentSoft,
    required this.gradient,
  });

  final Color accent200, accent300, accent400, accent500, accent600;
  final Color accent;       // primary tone
  final Color accentInk;    // text/icon ON the accent
  final Color accentSoft;   // background tint behind accent text/pips
  final List<Color> gradient;
}

class AppAccents {
  AppAccents._();

  /// Orange accent on slate/dark surface.
  static const AccentPalette orangeOnSlate = AccentPalette(
    accent200: Color(0xFFFAC788),
    accent300: Color(0xFFF4A955),
    accent400: Color(0xFFE8923A),
    accent500: Color(0xFFC66E1F),
    accent600: Color(0xFF9C4F0E),
    accent:    Color(0xFFE8923A),
    accentInk: Color(0xFF2D1810),
    accentSoft:Color(0x38E8923A),
    gradient: [Color(0xFFFAC788), Color(0xFFF4A955), Color(0xFFE8923A), Color(0xFFC66E1F)],
  );

  /// Orange accent on paper/light surface (shifted darker for AA).
  static const AccentPalette orangeOnPaper = AccentPalette(
    accent200: Color(0xFFF0BD80),
    accent300: Color(0xFFD68C3D),
    accent400: Color(0xFFB86A1A),
    accent500: Color(0xFF944F0C),
    accent600: Color(0xFF6B3A08),
    accent:    Color(0xFFB86A1A),
    accentInk: Color(0xFFFFFFFF),
    accentSoft:Color(0x24B86A1A),
    gradient: [Color(0xFFF0BD80), Color(0xFFD68C3D), Color(0xFFB86A1A), Color(0xFF944F0C)],
  );

  /// Green accent on slate.
  static const AccentPalette greenOnSlate = AccentPalette(
    accent200: Color(0xFFC4D49A),
    accent300: Color(0xFFA4B475),
    accent400: Color(0xFF7A8D4A),
    accent500: Color(0xFF5E7340),
    accent600: Color(0xFF455429),
    accent:    Color(0xFF7A8D4A),
    accentInk: Color(0xFFFBF3E6),
    accentSoft:Color(0x387A8D4A),
    gradient: [Color(0xFFC4D49A), Color(0xFFA4B475), Color(0xFF7A8D4A), Color(0xFF5E7340)],
  );

  /// Green accent on paper (shifted darker).
  static const AccentPalette greenOnPaper = AccentPalette(
    accent200: Color(0xFFA4B475),
    accent300: Color(0xFF7A8D4A),
    accent400: Color(0xFF455429),
    accent500: Color(0xFF34401E),
    accent600: Color(0xFF253017),
    accent:    Color(0xFF455429),
    accentInk: Color(0xFFFFFFFF),
    accentSoft:Color(0x24455429),
    gradient: [Color(0xFFA4B475), Color(0xFF7A8D4A), Color(0xFF455429), Color(0xFF34401E)],
  );

  /// Helper to pick the right accent variant for a given theme.
  static AccentPalette resolve({
    required Brightness brightness,
    required bool isGreen,
  }) {
    if (brightness == Brightness.dark) {
      return isGreen ? greenOnSlate : orangeOnSlate;
    } else {
      return isGreen ? greenOnPaper : orangeOnPaper;
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
//  STATUS COLORS — used by pips, tags, edges, node rails
// ════════════════════════════════════════════════════════════════════════

enum WorkflowStatus {
  passed, failed, running, retrying, paused, queued, skipped, cancelled,
}

class StatusColor {
  const StatusColor(this.base, this.soft);
  final Color base;
  final Color soft;
}

class AppStatusColors {
  AppStatusColors._();

  /// Resolve status → (base, soft) using the active palette + accent.
  static StatusColor of(
    WorkflowStatus status,
    ThemePalette palette,
    AccentPalette accent,
  ) {
    switch (status) {
      case WorkflowStatus.passed:
        return StatusColor(palette.success, palette.successSoft);
      case WorkflowStatus.failed:
        return StatusColor(palette.danger, palette.dangerSoft);
      case WorkflowStatus.running:
        return StatusColor(accent.accent, accent.accentSoft);
      case WorkflowStatus.retrying:
      case WorkflowStatus.paused:
        return StatusColor(palette.warning, palette.warningSoft);
      case WorkflowStatus.queued:
      case WorkflowStatus.skipped:
      case WorkflowStatus.cancelled:
        return StatusColor(palette.fg3, palette.bg3);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
//  COMPONENT TOKENS — per-component sizes the agent shouldn't have to guess
// ════════════════════════════════════════════════════════════════════════

class CompModeRail {
  CompModeRail._();
  static const double width    = 52;
  static const double itemSize = 40;
  static const double iconSize = 16;
}

class CompSidebar {
  CompSidebar._();
  static const double jobsWidth     = 260;
  static const double workflowWidth = 240;
  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(14, 14, 14, 12);
  static const EdgeInsets rowPadding    = EdgeInsets.symmetric(horizontal: 10, vertical: 7);
}

class CompDrawer {
  CompDrawer._();
  static const double width        = 460;
  static const double headerHeight = 56;
  static const double tabsHeight   = 38;
  static const double footerHeight = 48;
  static const double fieldGap     = 16;
}

class CompTopBar {
  CompTopBar._();
  static const double minHeight = 56;
}

class CompFilmstrip {
  CompFilmstrip._();
  static const double cardWidth = 268;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(14, 8, 14, 10);
  static const double gap = 8;
}

class CompNode {
  CompNode._();
  static const Size worker  = Size(192, 80);
  static const Size routing = Size(124, 50);
  static const double borderRadius   = 10;
  static const double statusRailWidth = 3;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(14, 10, 12, 10);
}

class CompButton {
  CompButton._();
  // sm  / md / lg
  static const Size      smMin      = Size(0, 26);
  static const EdgeInsets smPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 5);
  static const double    smFontSize = 12;
  static const double    smIconSize = 11;

  static const Size      mdMin      = Size(0, 32);
  static const EdgeInsets mdPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 7);
  static const double    mdFontSize = 13;
  static const double    mdIconSize = 12;

  static const Size      lgMin      = Size(0, 40);
  static const EdgeInsets lgPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 10);
  static const double    lgFontSize = 14;
  static const double    lgIconSize = 14;
}
