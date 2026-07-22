import 'package:flutter/material.dart';
import 'theme_controller.dart';

// THEME REACTIVITY RULE:
// AppColors reads from ThemeController (a mutable singleton). Flutter's const
// widget canonicalization means const widgets skip rebuilds even when their
// ancestors rebuild. Therefore:
//   1. NEVER use `const` on any widget that reads AppColors (directly or in
//      descendants) unless that widget itself watches settingsProvider.
//   2. CartaApp MUST watch settingsProvider to force root rebuild.
//   3. When in doubt, remove const. The performance cost is negligible;
//      broken theme propagation is not.
// See theme_controller.dart and main.dart for related rules.
class AppColors {
  static Color get bg0 => ThemeController().current.bg0;
  static Color get bg1 => ThemeController().current.bg1;
  static Color get bg2 => ThemeController().current.bg2;
  static Color get bg3 => ThemeController().current.bg3;
  static Color get bg4 => ThemeController().current.bg4;
  static Color get bg5 => ThemeController().current.bg5;

  static Color get fg0 => ThemeController().current.fg0;
  static Color get fg1 => ThemeController().current.fg1;
  static Color get fg2 => ThemeController().current.fg2;
  static Color get fg3 => ThemeController().current.fg3;
  static Color get fg4 => ThemeController().current.fg4;
  static Color get fg5 => ThemeController().current.fg5;

  static Color get border1 => ThemeController().current.border1;
  static Color get border2 => ThemeController().current.border2;
  static Color get border3 => ThemeController().current.border3;

  static Color get accent => ThemeController().current.accent;
  static Color get accentInk => ThemeController().current.accentInk;
  static Color get trail => ThemeController().current.trail;
  static Color get chartGrid => ThemeController().current.chartGrid;

  static Color get success => ThemeController().current.success;
  static Color get warning => ThemeController().current.warning;
  static Color get danger => ThemeController().current.danger;
  static Color get info => ThemeController().current.info;

  static Color get synKeyword => ThemeController().current.synKeyword;
  static Color get synString => ThemeController().current.synString;
  static Color get synNumber => ThemeController().current.synNumber;
  static Color get synComment => ThemeController().current.synComment;
  static Color get synFunction => ThemeController().current.synFunction;
  static Color get synType => ThemeController().current.synType;
  static Color get synPunct => ThemeController().current.synPunct;

  static Gradient get hearthGradient => ThemeController().current.hearthGradient;
  static Gradient get loafGradient => ThemeController().current.loafGradient;
  static Gradient get crustGradient => ThemeController().current.crustGradient;
}

class AppSpacing {
  static const double s1 = 2;
  static const double s2 = 4;
  static const double s3 = 6;
  static const double s4 = 8;
  static const double s5 = 12;
  static const double s6 = 16;
  static const double s7 = 20;
  static const double s8 = 24;
}

class AppRadius {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 10;
}
