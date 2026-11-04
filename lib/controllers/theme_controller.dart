import 'package:flutter/material.dart';

import '../core/utils/local_preferences.dart';

/// Tema escolhido pelo usuário, salvo localmente.
class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) : _mode = _parse(_prefs.themeMode);

  final LocalPreferences _prefs;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  String get label => switch (_mode) {
        ThemeMode.light => 'Claro',
        ThemeMode.dark => 'Escuro',
        ThemeMode.system => 'Automático',
      };

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setThemeMode(mode.name);
  }

  static ThemeMode _parse(String? value) => ThemeMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => ThemeMode.light,
      );
}
