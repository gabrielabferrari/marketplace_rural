import 'package:flutter/foundation.dart';

import '../core/utils/local_preferences.dart';

/// Preferências de uso guardadas no dispositivo.
class PreferencesController extends ChangeNotifier {
  PreferencesController(this._prefs)
      : _notifications = _prefs.notificationsEnabled,
        _region = _prefs.region,
        _menuCollapsed = _prefs.menuCollapsed;

  final LocalPreferences _prefs;

  bool _notifications;
  String _region;
  bool _menuCollapsed;

  /// Quando desativado, o app não busca nem exibe alertas de notificações.
  bool get notificationsEnabled => _notifications;

  /// Cidade/região usada para sugerir "Produtos perto de você".
  String get region => _region;

  bool get menuCollapsed => _menuCollapsed;

  /// Idiomas disponíveis. Apenas português está traduzido no momento.
  static const languages = {'pt_BR': 'Português (Brasil)'};
  String get language => 'pt_BR';

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    notifyListeners();
    await _prefs.setNotificationsEnabled(value);
  }

  Future<void> setRegion(String value) async {
    _region = value.trim();
    notifyListeners();
    await _prefs.setRegion(_region);
  }

  Future<void> toggleMenuCollapsed() async {
    _menuCollapsed = !_menuCollapsed;
    notifyListeners();
    await _prefs.setMenuCollapsed(_menuCollapsed);
  }
}
