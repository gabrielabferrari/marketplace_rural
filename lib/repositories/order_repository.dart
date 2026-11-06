import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/endpoints.dart';
import '../core/routes/permissions.dart';
import '../models/json_utils.dart';
import '../models/order.dart';
import '../models/user.dart';

/// Pedidos no backend do site (`backend/pedidos/`).
///
/// O servidor filtra pela sessão: comprador vê os pedidos que fez; produtor
/// vê os que recebeu. Não há rota de detalhe, então o detalhe sai da lista.
class OrderRepository {
  OrderRepository(this._api, this._currentUser);

  final ApiClient _api;
  final AppUser? Function() _currentUser;

  Future<List<Order>> list({OrderStatus? status}) async {
    final data = await _api.get(Endpoints.orders);
    final orders = Json.list(data['pedidos']).map(Order.fromJson).toList();
    if (status == null) return orders;
    return orders.where((o) => o.status == status).toList();
  }

  Future<Order> detail(String id) async {
    for (final order in await list()) {
      if (order.id == id) return order;
    }
    throw const ApiException(ApiErrorType.notFound, 'Pedido não encontrado.');
  }

  /// Cria um pedido de um produto. O backend baixa o estoque na criação.
  /// [negociacaoId] e [observacao] não são suportados pelo backend do site.
  Future<Order> create({
    required String produtoId,
    required double quantidade,
    String? negociacaoId,
    String? observacao,
  }) async {
    Permissions.ensure(_currentUser(), Feature.placeOrder);
    final data = await _api.post(Endpoints.orderCreate, body: {
      'anuncio_id': produtoId,
      'quantidade': quantidade.round(),
    });
    return detail(Json.string(data['pedido_id']));
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
    await _api.post(Endpoints.orderUpdate, body: {
      'id': order.id,
      'status': target.apiValue,
    });
    return detail(order.id);
  }
}
