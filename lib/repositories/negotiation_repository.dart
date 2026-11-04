import '../core/network/api_client.dart';
import '../core/network/endpoints.dart';
import '../core/routes/permissions.dart';
import '../models/json_utils.dart';
import '../models/negotiation.dart';
import '../models/user.dart';

class NegotiationRepository {
  NegotiationRepository(this._api, this._currentUser);

  final ApiClient _api;
  final AppUser? Function() _currentUser;

  Future<List<Negotiation>> list({NegotiationStatus? status}) async {
    final data =
        await _api.get(Endpoints.negotiations, query: {'status': status?.apiValue});
    return Json.list(data).map(Negotiation.fromJson).toList();
  }

  Future<Negotiation> detail(String id) async {
    final data = Json.map(await _api.get(Endpoints.negotiationDetail, query: {'id': id}));
    return Negotiation.fromJson(Json.map(data['negociacao'] ?? data));
  }

  Future<Negotiation> start({
    required String produtoId,
    required double quantidade,
    required double precoProposto,
    String? mensagem,
  }) async {
    Permissions.ensure(_currentUser(), Feature.startNegotiation);
    final data = Json.map(await _api.post(Endpoints.negotiationCreate, body: {
      'produto_id': produtoId,
      'quantidade': quantidade,
      'preco_proposto': precoProposto,
      if (mensagem != null && mensagem.trim().isNotEmpty) 'mensagem': mensagem.trim(),
    }));
    return Negotiation.fromJson(Json.map(data['negociacao'] ?? data));
  }

  Future<Negotiation> respond(
    String id,
    NegotiationAction action, {
    double? precoProposto,
    double? quantidade,
    String? mensagem,
  }) async {
    final data = Json.map(await _api.post(Endpoints.negotiationRespond, body: {
      'id': id,
      'acao': action.name,
      'preco_proposto': ?precoProposto,
      'quantidade': ?quantidade,
      if (mensagem != null && mensagem.trim().isNotEmpty) 'mensagem': mensagem.trim(),
    }));
    return Negotiation.fromJson(Json.map(data['negociacao'] ?? data));
  }
}
