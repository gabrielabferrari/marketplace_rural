import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/endpoints.dart';
import '../core/routes/permissions.dart';
import '../models/json_utils.dart';
import '../models/order.dart';
import '../models/user.dart';

class OrderRepository {
  OrderRepository(this._api, this._currentUser);

  final ApiClient _api;
  final AppUser? Function() _currentUser;

  /// Lista os pedidos do usuário logado. O servidor filtra pelo token:
  /// comprador vê os que fez; produtor vê os que recebeu.
  Future<List<Order>> list({OrderStatus? status}) async {
    final data = await _api.get(Endpoints.orders, query: {'status': status?.apiValue});
    return Json.list(data).map(Order.fromJson).toList();
  }

  Future<Order> detail(String id) async {
    final data = Json.map(await _api.get(Endpoints.orderDetail, query: {'id': id}));
    return Order.fromJson(Json.map(data['pedido'] ?? data));
  }

  Future<Order> create({
    required String produtoId,
    required double quantidade,
    String? negociacaoId,
    String? observacao,
  }) async {
    Permissions.ensure(_currentUser(), Feature.placeOrder);
    final data = Json.map(await _api.post(Endpoints.orderCreate, body: {
      'itens': [
        {'produto_id': produtoId, 'quantidade': quantidade},
      ],
      'negociacao_id': ?negociacaoId,
      if (observacao != null && observacao.trim().isNotEmpty) 'observacao': observacao.trim(),
    }));
    return Order.fromJson(Json.map(data['pedido'] ?? data));
  }

  Future<Order> updateStatus(Order order, OrderStatus target) async {
    final user = _currentUser();
    if (user == null) {
      throw const ApiException(ApiErrorType.unauthorized, 'Entre na sua conta para continuar.');
    }
    if (!OrderRules.allowedTransitions(order.status, user.tipo).contains(target)) {
      throw const ApiException(ApiErrorType.forbidden,
          'Esta alteração de status não é permitida para sua conta.');
    }
    final data = Json.map(await _api.post(Endpoints.orderUpdate, body: {
      'id': order.id,
      'status': target.apiValue,
    }));
    return Order.fromJson(Json.map(data['pedido'] ?? data));
  }
}
