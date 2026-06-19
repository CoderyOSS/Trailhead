import 'package:flutter/material.dart';

@immutable
class SettingsState {
  final String theme;
  final String accent;
  final String density;
  final String canvasStyle;
  final String edgeStyle;
  final String defaultMode;
  final String workerRunner;
  final bool confirmStop;
  final bool notifyFinish;
  final bool telegramEnabled;
  final String telegramToken;
  final String telegramChat;

  const SettingsState({
    this.theme = 'slate',
    this.accent = 'orange',
    this.density = 'comfortable',
    this.canvasStyle = 'graph',
    this.edgeStyle = 'curved',
    this.defaultMode = 'active',
    this.workerRunner = 'localhost',
    this.confirmStop = true,
    this.notifyFinish = true,
    this.telegramEnabled = true,
    this.telegramToken = '',
    this.telegramChat = '',
  });

  SettingsState copyWith({
    String? theme,
    String? accent,
    String? density,
    String? canvasStyle,
    String? edgeStyle,
    String? defaultMode,
    String? workerRunner,
    bool? confirmStop,
    bool? notifyFinish,
    bool? telegramEnabled,
    String? telegramToken,
    String? telegramChat,
  }) {
    return SettingsState(
      theme: theme ?? this.theme,
      accent: accent ?? this.accent,
      density: density ?? this.density,
      canvasStyle: canvasStyle ?? this.canvasStyle,
      edgeStyle: edgeStyle ?? this.edgeStyle,
      defaultMode: defaultMode ?? this.defaultMode,
      workerRunner: workerRunner ?? this.workerRunner,
      confirmStop: confirmStop ?? this.confirmStop,
      notifyFinish: notifyFinish ?? this.notifyFinish,
      telegramEnabled: telegramEnabled ?? this.telegramEnabled,
      telegramToken: telegramToken ?? this.telegramToken,
      telegramChat: telegramChat ?? this.telegramChat,
    );
  }
}
