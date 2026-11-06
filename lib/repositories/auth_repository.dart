import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/endpoints.dart';
import '../models/json_utils.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// Abre a sessão no servidor (o cookie `PHPSESSID` é guardado pelo
  /// [ApiClient]) e devolve o usuário logado.
  Future<AppUser> login({required String email, required String senha}) async {
    await _api.post(Endpoints.login, body: {
      'email': email.trim().toLowerCase(),
      'senha': senha,
    });
    return me();
  }

  /// O backend do site não inicia sessão no cadastro: quem chama deve
  /// fazer login em seguida.
  Future<void> register({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required String confirmarSenha,
    required UserRole tipo,
  }) async {
    await _api.post(Endpoints.register, body: {
      'nome': nome.trim(),
      'email': email.trim().toLowerCase(),
      'telefone': telefone.trim(),
      'senha': senha,
      'confirmarSenha': confirmarSenha,
      'tipoConta': tipo.apiValue,
    });
  }

  /// Dados do usuário da sessão atual.
  Future<AppUser> me() async {
    final data = await _api.get(Endpoints.me);
    return _parseUser(data['usuario']);
  }

  /// Recuperação de senha: a rota ainda não existe no backend do site.
  Future<String> requestPasswordReset(String email) async {
    final data = await _api.post(Endpoints.forgotPassword,
        body: {'email': email.trim().toLowerCase()});
    return Json.stringOrNull(data['mensagem']) ??
        'Se o e-mail estiver cadastrado, você receberá as instruções em instantes.';
  }

  /// Troca de senha: a rota ainda não existe no backend do site.
  Future<void> changePassword({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    await _api.post(Endpoints.changePassword, body: {
      'senhaAtual': senhaAtual,
      'novaSenha': novaSenha,
    });
  }

  /// O backend exige nome, telefone e cidade ao atualizar o perfil.
  Future<AppUser> updateProfile({
    required String nome,
    required String telefone,
    required String cidade,
  }) async {
    final data = await _api.post(Endpoints.profileUpdate, body: {
      'nome': nome.trim(),
      'telefone': telefone.trim(),
      'cidade': cidade.trim(),
    });
    return _parseUser(data['usuario']);
  }

  /// Encerra a sessão no servidor (melhor esforço). A sessão local é
  /// encerrada mesmo que o servidor esteja indisponível.
  Future<void> logout() async {
    try {
      await _api.get(Endpoints.logout);
    } on ApiException {
      // ignorado: o cookie é descartado localmente de qualquer forma.
    }
  }

  AppUser _parseUser(dynamic raw) {
    final map = Json.map(raw);
    if (map.isEmpty) {
      throw const ApiException(ApiErrorType.invalidResponse,
          'Resposta de autenticação inválida do servidor.');
    }
    try {
      return AppUser.fromJson(map);
    } on FormatException {
      throw const ApiException(ApiErrorType.invalidResponse,
          'Os dados da conta retornados pelo servidor são inválidos.');
    }
  }
}
