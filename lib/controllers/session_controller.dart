import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/utils/local_preferences.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

enum SessionStatus { loading, unauthenticated, authenticated }

/// Estado de autenticação do aplicativo.
///
/// A sessão é o cookie `PHPSESSID` emitido pelo backend do site; ele é
/// enviado em todas as requisições. Nenhuma senha é guardada no dispositivo.
class SessionController extends ChangeNotifier {
  SessionController({
    required this._api,
    required this._auth,
    required this._prefs,
  }) {
    _api.onUnauthorized = _onUnauthorized;
  }

  final ApiClient _api;
  final AuthRepository _auth;
  final LocalPreferences _prefs;

  SessionStatus _status = SessionStatus.loading;
  AppUser? _user;
  bool _expired = false;
  bool _persisted = true;

  SessionStatus get status => _status;
  AppUser? get user => _user;
  bool get isAuthenticated => _status == SessionStatus.authenticated;

  /// Indica que a última sessão foi encerrada pelo servidor (sessão expirada).
  bool consumeExpiredFlag() {
    final value = _expired;
    _expired = false;
    return value;
  }

  /// Restaura a sessão salva (de forma síncrona, antes do primeiro build) e
  /// valida a sessão no servidor em segundo plano.
  void restore() {
    final cookie = _prefs.sessionCookie;
    final cached = _decodeUser(_prefs.cachedUser);
    if (cookie == null || cached == null) {
      _prefs.clearSession();
      _status = SessionStatus.unauthenticated;
      _user = null;
      return;
    }
    _api.sessionCookie = cookie;
    _status = SessionStatus.authenticated;
    _user = cached;
    refreshUser();
  }

  /// Atualiza os dados do usuário a partir do servidor. Em caso de falha de
  /// rede, mantém os dados em cache (uso offline de leitura).
  Future<void> refreshUser() async {
    try {
      final fresh = await _auth.me();
      await _persistUser(fresh);
    } on ApiException catch (e) {
      if (kDebugMode) debugPrint('[Session] refresh: ${e.type}');
    }
  }

  /// [remember] = false mantém a sessão apenas em memória: ao fechar o app,
  /// será necessário entrar novamente.
  Future<void> login(String email, String senha, {bool remember = true}) async {
    final user = await _auth.login(email: email, senha: senha);
    await _start(user, persist: remember);
  }

  Future<void> register({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required String confirmarSenha,
    required UserRole tipo,
  }) async {
    await _auth.register(
      nome: nome,
      email: email,
      telefone: telefone,
      senha: senha,
      confirmarSenha: confirmarSenha,
      tipo: tipo,
    );
    // O cadastro não abre sessão no servidor: entra com as mesmas credenciais.
    await login(email, senha);
  }

  Future<void> updateProfile({required String nome, required String telefone}) async {
    final updated = await _auth.updateProfile(
      nome: nome,
      telefone: telefone,
      cidade: _user?.cidade ?? '',
    );
    await _persistUser(updated);
  }

  Future<void> changePassword({required String senhaAtual, required String novaSenha}) =>
      _auth.changePassword(senhaAtual: senhaAtual, novaSenha: novaSenha);

  Future<void> logout() async {
    await _auth.logout();
    await _clear();
  }

  Future<void> _start(AppUser user, {bool persist = true}) async {
    final cookie = _api.sessionCookie;
    if (cookie == null) {
      throw const ApiException(ApiErrorType.invalidResponse,
          'O servidor não iniciou a sessão. Tente entrar novamente.');
    }
    _persisted = persist;
    if (persist) {
      await _prefs.saveSession(cookie, jsonEncode(user.toJson()));
    } else {
      await _prefs.clearSession();
    }
    _set(SessionStatus.authenticated, user);
  }

  Future<void> _persistUser(AppUser user) async {
    if (!isAuthenticated) return;
    if (_persisted) await _prefs.updateCachedUser(jsonEncode(user.toJson()));
    _user = user;
    notifyListeners();
  }

  void _onUnauthorized() {
    if (!isAuthenticated) return; // ex.: senha incorreta no login
    _expired = true;
    _clear();
  }

  Future<void> _clear() async {
    _api.sessionCookie = null;
    await _prefs.clearSession();
    _set(SessionStatus.unauthenticated, null);
  }

  void _set(SessionStatus status, AppUser? user) {
    _status = status;
    _user = user;
    notifyListeners();
  }

  AppUser? _decodeUser(String? raw) {
    if (raw == null) return null;
    try {
      return AppUser.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}
