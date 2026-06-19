import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_state.dart';
import '../theme/theme_controller.dart';

final settingsModalOpenProvider = StateProvider<bool>((ref) => false);

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setTweak(String key, dynamic value) {
    switch (key) {
      case 'theme':
        state = state.copyWith(theme: value as String);
        ThemeController().setTheme(value);
        break;
      case 'accent':
        state = state.copyWith(accent: value as String);
        ThemeController().setAccent(value);
        break;
      case 'density':      state = state.copyWith(density: value as String); break;
      case 'canvasStyle':  state = state.copyWith(canvasStyle: value as String); break;
      case 'edgeStyle':    state = state.copyWith(edgeStyle: value as String); break;
      case 'defaultMode':  state = state.copyWith(defaultMode: value as String); break;
      case 'workerRunner': state = state.copyWith(workerRunner: value as String); break;
      case 'confirmStop':  state = state.copyWith(confirmStop: value as bool); break;
      case 'notifyFinish': state = state.copyWith(notifyFinish: value as bool); break;
      case 'telegramEnabled': state = state.copyWith(telegramEnabled: value as bool); break;
      case 'telegramToken':   state = state.copyWith(telegramToken: value as String); break;
      case 'telegramChat':    state = state.copyWith(telegramChat: value as String); break;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
