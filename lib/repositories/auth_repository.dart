import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/endpoints.dart';
import '../models/json_utils.dart';
import '../models/user.dart';

class AuthResult {
  const AuthResult(this.token, this.user);

  final String token;
  final AppUser user;
}

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthResult> login({required String email, required String senha}) async {
    final data = await _api.post(Endpoints.login, body: {
      'email': email.trim().toLowerCase(),
      'senha': senha,
    });
    return _parseAuth(data);
  }

  Future<AuthResult> register({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required String confirmarSenha,
    required UserRole tipo,
  }) async {
    final data = await _api.post(Endpoints.register, body: {
      'nome': nome.trim(),
      'email': email.trim().toLowerCase(),
      'telefone': telefone.trim(),
      'senha': senha,
      'confirmarSenha': confirmarSenha,
      'tipo': tipo.apiValue,
    });
    return _parseAuth(data);
  }

  Future<AppUser> me() async {
    final data = Json.map(await _api.get(Endpoints.me));
    return AppUser.fromJson(Json.map(data['usuario'] ?? data));
  }

  /// Envio de instruções de recuperação. O servidor deve responder com a
  /// mesma mensagem existindo ou não o e-mail, para não revelar cadastros.
  Future<String> requestPasswordReset(String email) async {
    final data = Json.map(await _api.post(Endpoints.forgotPassword,
        body: {'email': email.trim().toLowerCase()}));
    return Json.stringOrNull(data['mensagem']) ??
        'Se o e-mail estiver cadastrado, você receberá as instruções em instantes.';
  }

  /// Retorna o novo token emitido pelo servidor (os anteriores deixam de
  /// valer após a troca de senha), ou `null` se o servidor não enviar.
  Future<String?> changePassword({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final data = Json.map(await _api.post(Endpoints.changePassword, body: {
      'senhaAtual': senhaAtual,
      'novaSenha': novaSenha,
    }));
    return Json.stringOrNull(data['token']);
  }

  Future<AppUser> updateProfile({required String nome, required String telefone}) async {
    final data = Json.map(await _api.put(Endpoints.profileUpdate, body: {
      'nome': nome.trim(),
      'telefone': telefone.trim(),
    }));
    return AppUser.fromJson(Json.map(data['usuario'] ?? data));
  }

  /// Notifica o servidor (melhor esforço). A sessão local é encerrada
  /// mesmo que o servidor esteja indisponível.
  Future<void> logout() async {
    try {
      await _api.post(Endpoints.logout);
    } on ApiException {
      // ignorado: o token é descartado localmente de qualquer forma.
    }
  }

  AuthResult _parseAuth(dynamic data) {
    final map = Json.map(data);
    final token = Json.stringOrNull(map['token']);
    final userJson = Json.map(map['usuario']);
    if (token == null || userJson.isEmpty) {
      throw const ApiException(ApiErrorType.invalidResponse,
          'Resposta de autenticação inválida do servidor.');
    }
    try {
      return AuthResult(token, AppUser.fromJson(userJson));
    } on FormatException {
      throw const ApiException(ApiErrorType.invalidResponse,
          'Os dados da conta retornados pelo servidor são inválidos.');
    }
  }
}
