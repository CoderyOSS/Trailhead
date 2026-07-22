import 'package:flutter/material.dart';
import 'theme_data.dart';

// NOTE: notifyListeners() alone does NOT rebuild the widget tree. Widgets must
// either (a) watch settingsProvider (see main.dart), or (b) be non-const so
// ancestor rebuilds propagate. NEVER mark widgets const if they or their
// descendants read AppColors. See tokens.dart for the full rule.
class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  CartaThemeData _current = _buildTheme('slate', 'green');
  CartaThemeData get current => _current;

  String _theme = 'slate';
  String _accent = 'green';

  String get theme => _theme;
  String get accent => _accent;

  void setTheme(String value) {
    if (_theme == value) return;
    _theme = value;
    _rebuild();
  }

  void setAccent(String value) {
    if (_accent == value) return;
    _accent = value;
    _rebuild();
  }

  void setThemeAndAccent(String theme, String accent) {
    if (_theme == theme && _accent == accent) return;
    _theme = theme;
    _accent = accent;
    _rebuild();
  }

  void _rebuild() {
    _current = _buildTheme(_theme, _accent);
    notifyListeners();
  }

  static CartaThemeData _buildTheme(String theme, String accent) {
    final base = _themeBases[theme]!;
    final accentData = _accentData[accent]!;
    final isPaperGreen = theme == 'paper' && accent == 'green';

    final accentColor = isPaperGreen ? const Color(0xFF455429) : accentData.accent;
    final accentInkColor = isPaperGreen ? const Color(0xFFFFFFFF) : accentData.accentInk;

    return CartaThemeData(
      bg0: base.bg0,
      bg1: base.bg1,
      bg2: base.bg2,
      bg3: base.bg3,
      bg4: base.bg4,
      bg5: base.bg5,
      fg0: base.fg0,
      fg1: base.fg1,
      fg2: base.fg2,
      fg3: base.fg3,
      fg4: base.fg4,
      fg5: base.fg5,
      border1: base.border1,
      border2: base.border2,
      border3: base.border3,
      accent: accentColor,
      accentInk: accentInkColor,
      trail: isPaperGreen ? const Color(0xFF455429) : base.trail,
      chartGrid: base.chartGrid,
      success: base.success,
      warning: base.warning,
      danger: base.danger,
      info: base.info,
      synKeyword: base.synKeyword,
      synString: base.synString,
      synNumber: base.synNumber,
      synComment: base.synComment,
      synFunction: base.synFunction,
      synType: base.synType,
      synPunct: base.synPunct,
      hearthGradient: base.hearthGradient,
      loafGradient: base.loafGradient,
      crustGradient: accentData.crustGradient,
    );
  }

  static final Map<String, _ThemeBase> _themeBases = {
    'hearth': _ThemeBase(
      bg0: const Color(0xFF160d07),
      bg1: const Color(0xFF1e140c),
      bg2: const Color(0xFF281a10),
      bg3: const Color(0xFF342214),
      bg4: const Color(0xFF422c1a),
      bg5: const Color(0xFF533720),
      fg0: const Color(0xFFfbf3e6),
      fg1: const Color(0xFFecd9b8),
      fg2: const Color(0xFFc9aa84),
      fg3: const Color(0xFF99765a),
      fg4: const Color(0xFF6b513c),
      fg5: const Color(0xFF4a3526),
      border1: const Color(0xFF2e1e12),
      border2: const Color(0xFF3d2a1c),
      border3: const Color(0xFF56401f),
      trail: const Color(0xFF7a8d4a),
      chartGrid: const Color(0xFF2e1e12),
      success: const Color(0xFF8fb56a),
      warning: const Color(0xFFf0b340),
      danger: const Color(0xFFdc5a4a),
      info: const Color(0xFF7aa6cc),
      synKeyword: const Color(0xFFf4a955),
      synString: const Color(0xFFb5d189),
      synNumber: const Color(0xFFf0b340),
      synComment: const Color(0xFF7a5d44),
      synFunction: const Color(0xFF7aa6cc),
      synType: const Color(0xFFe0a8d4),
      synPunct: const Color(0xFF99765a),
      hearthGradient: const RadialGradient(
        center: Alignment(0, -1.1),
        radius: 1.1,
        colors: [Color(0xFF3d2418), Color(0xFF281a10), Color(0xFF160d07)],
        stops: [0.0, 0.4, 1.0],
      ),
      loafGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF281a10), Color(0xFF2c1e13)],
      ),
    ),
    'slate': _ThemeBase(
      bg0: const Color(0xFF0c0d10),
      bg1: const Color(0xFF14161b),
      bg2: const Color(0xFF1a1d23),
      bg3: const Color(0xFF22262d),
      bg4: const Color(0xFF2b303a),
      bg5: const Color(0xFF353b46),
      fg0: const Color(0xFFf3f4f6),
      fg1: const Color(0xFFd8dade),
      fg2: const Color(0xFFa5a9b1),
      fg3: const Color(0xFF777b84),
      fg4: const Color(0xFF565a62),
      fg5: const Color(0xFF3d4148),
      border1: const Color(0xFF21242a),
      border2: const Color(0xFF2e323a),
      border3: const Color(0xFF40454f),
      trail: const Color(0xFF7a8d4a),
      chartGrid: const Color(0xFF21242a),
      success: const Color(0xFF6fbf73),
      warning: const Color(0xFFe6b341),
      danger: const Color(0xFFe26464),
      info: const Color(0xFF6ea8d9),
      synKeyword: const Color(0xFFc98a5e),
      synString: const Color(0xFFa0c97b),
      synNumber: const Color(0xFFe6b341),
      synComment: const Color(0xFF6a6e76),
      synFunction: const Color(0xFF7eb6e6),
      synType: const Color(0xFFd4a3d4),
      synPunct: const Color(0xFF777b84),
      hearthGradient: const RadialGradient(
        center: Alignment(0, -1.1),
        radius: 1.1,
        colors: [Color(0xFF1d2027), Color(0xFF14161b), Color(0xFF0c0d10)],
        stops: [0.0, 0.45, 1.0],
      ),
      loafGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1a1d23), Color(0xFF1f232a)],
      ),
    ),
    'carta': _ThemeBase(
      bg0: const Color(0xFF0a120c),
      bg1: const Color(0xFF0f1a12),
      bg2: const Color(0xFF142319),
      bg3: const Color(0xFF1c2e21),
      bg4: const Color(0xFF253a2c),
      bg5: const Color(0xFF2f4737),
      fg0: const Color(0xFFecf2e0),
      fg1: const Color(0xFFd3deb9),
      fg2: const Color(0xFFa8b88a),
      fg3: const Color(0xFF7d8d63),
      fg4: const Color(0xFF586645),
      fg5: const Color(0xFF3d4831),
      border1: const Color(0xFF1a2b1f),
      border2: const Color(0xFF25392c),
      border3: const Color(0xFF36513e),
      trail: const Color(0xFF7a8d4a),
      chartGrid: const Color(0xFF1a2b1f),
      success: const Color(0xFFa4c97a),
      warning: const Color(0xFFe6c241),
      danger: const Color(0xFFdc6555),
      info: const Color(0xFF8fc4d6),
      synKeyword: const Color(0xFFd6c258),
      synString: const Color(0xFFb5d189),
      synNumber: const Color(0xFFe6c241),
      synComment: const Color(0xFF586645),
      synFunction: const Color(0xFF8fc4d6),
      synType: const Color(0xFFe0b8a8),
      synPunct: const Color(0xFF7d8d63),
      hearthGradient: const RadialGradient(
        center: Alignment(0, -1.1),
        radius: 1.1,
        colors: [Color(0xFF1f3326), Color(0xFF142319), Color(0xFF0a120c)],
        stops: [0.0, 0.45, 1.0],
      ),
      loafGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF142319), Color(0xFF18291d)],
      ),
    ),
    'paper': _ThemeBase(
      bg0: const Color(0xFFf5f2ec),
      bg1: const Color(0xFFfdfbf6),
      bg2: const Color(0xFFf3efe6),
      bg3: const Color(0xFFe8e3d6),
      bg4: const Color(0xFFdcd6c4),
      bg5: const Color(0xFFc9c2ad),
      fg0: const Color(0xFF1a1814),
      fg1: const Color(0xFF3a352d),
      fg2: const Color(0xFF5d564a),
      fg3: const Color(0xFF837b6c),
      fg4: const Color(0xFFa8a193),
      fg5: const Color(0xFFc9c2ad),
      border1: const Color(0xFFebe6d8),
      border2: const Color(0xFFd8d2c0),
      border3: const Color(0xFFb5ad96),
      trail: const Color(0xFF5e7340),
      chartGrid: const Color(0xFFe8e3d6),
      success: const Color(0xFF5e8a3f),
      warning: const Color(0xFFb8780f),
      danger: const Color(0xFFb8331f),
      info: const Color(0xFF325f8a),
      synKeyword: const Color(0xFF944f0c),
      synString: const Color(0xFF5e8a3f),
      synNumber: const Color(0xFFa04400),
      synComment: const Color(0xFFa8a193),
      synFunction: const Color(0xFF325f8a),
      synType: const Color(0xFF7a3eba),
      synPunct: const Color(0xFF837b6c),
      hearthGradient: const RadialGradient(
        center: Alignment(0, -1.1),
        radius: 1.1,
        colors: [Color(0xFFfdfbf6), Color(0xFFf5f2ec), Color(0xFFede8d8)],
        stops: [0.0, 0.5, 1.0],
      ),
      loafGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFfdfbf6), Color(0xFFf7f3e8)],
      ),
    ),
  };

  static final Map<String, _AccentData> _accentData = {
    'orange': _AccentData(
      accent: const Color(0xFFe8923a),
      accentInk: const Color(0xFF2d1810),
      crustGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFfac788), Color(0xFFf4a955), Color(0xFFe8923a), Color(0xFFc66e1f)],
      ),
    ),
    'green': _AccentData(
      accent: const Color(0xFF7a8d4a),
      accentInk: const Color(0xFFfbf3e6),
      crustGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFc4d49a), Color(0xFFa4b475), Color(0xFF7a8d4a), Color(0xFF5e7340)],
      ),
    ),
  };
}

class _ThemeBase {
  final Color bg0, bg1, bg2, bg3, bg4, bg5;
  final Color fg0, fg1, fg2, fg3, fg4, fg5;
  final Color border1, border2, border3;
  final Color trail;
  final Color chartGrid;
  final Color success, warning, danger, info;
  final Color synKeyword, synString, synNumber, synComment, synFunction, synType, synPunct;
  final Gradient hearthGradient;
  final Gradient loafGradient;

  const _ThemeBase({
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
  });
}

class _AccentData {
  final Color accent;
  final Color accentInk;
  final Gradient crustGradient;

  const _AccentData({
    required this.accent,
    required this.accentInk,
    required this.crustGradient,
  });
}
