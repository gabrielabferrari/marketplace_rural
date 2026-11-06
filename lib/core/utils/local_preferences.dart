import 'package:shared_preferences/shared_preferences.dart';

/// Preferências locais do dispositivo (tema, sessão, preferências de UI).
///
/// Dados de negócio (produtos, pedidos, favoritos...) NÃO são guardados
/// aqui: eles pertencem ao servidor.
class LocalPreferences {
  LocalPreferences(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalPreferences> load() async =>
      LocalPreferences(await SharedPreferences.getInstance());

  static const _kThemeMode = 'pref_theme_mode';
  static const _kSessionCookie = 'session_cookie';
  static const _kUser = 'session_user';
  static const _kNotifications = 'pref_notifications';
  static const _kRegion = 'pref_region';
  static const _kMenuCollapsed = 'pref_menu_collapsed';

  String? get themeMode => _prefs.getString(_kThemeMode);
  Future<void> setThemeMode(String value) =>
      _prefs.setString(_kThemeMode, value);

  /// Cookie de sessão do servidor (`PHPSESSID=...`).
  String? get sessionCookie => _prefs.getString(_kSessionCookie);
  String? get cachedUser => _prefs.getString(_kUser);

  Future<void> saveSession(String sessionCookie, String userJson) async {
    await _prefs.setString(_kSessionCookie, sessionCookie);
    await _prefs.setString(_kUser, userJson);
  }

  Future<void> updateCachedUser(String userJson) =>
      _prefs.setString(_kUser, userJson);

  Future<void> clearSession() async {
    await _prefs.remove(_kSessionCookie);
    await _prefs.remove(_kUser);
  }

  bool get notificationsEnabled => _prefs.getBool(_kNotifications) ?? true;
  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_kNotifications, value);

  String get region => _prefs.getString(_kRegion) ?? '';
  Future<void> setRegion(String value) => _prefs.setString(_kRegion, value);

  bool get menuCollapsed => _prefs.getBool(_kMenuCollapsed) ?? false;
  Future<void> setMenuCollapsed(bool value) =>
      _prefs.setBool(_kMenuCollapsed, value);
}
