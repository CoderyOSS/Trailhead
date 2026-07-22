import 'package:flutter/material.dart';

@immutable
class CartaThemeData {
  final Color bg0, bg1, bg2, bg3, bg4, bg5;
  final Color fg0, fg1, fg2, fg3, fg4, fg5;
  final Color border1, border2, border3;
  final Color accent;
  final Color accentInk;
  final Color trail;
  final Color chartGrid;
  final Color success, warning, danger, info;
  final Color synKeyword, synString, synNumber, synComment, synFunction, synType, synPunct;
  final Gradient hearthGradient;
  final Gradient loafGradient;
  final Gradient crustGradient;

  const CartaThemeData({
    required this.bg0,
    required this.bg1,
    required this.bg2,
    required this.bg3,
    required this.bg4,
    required this.bg5,
    required this.fg0,
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.fg4,
    required this.fg5,
    required this.border1,
    required this.border2,
    required this.border3,
    required this.accent,
    required this.accentInk,
    required this.trail,
    required this.chartGrid,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.synKeyword,
    required this.synString,
    required this.synNumber,
    required this.synComment,
    required this.synFunction,
    required this.synType,
    required this.synPunct,
    required this.hearthGradient,
    required this.loafGradient,
    required this.crustGradient,
  });
}
