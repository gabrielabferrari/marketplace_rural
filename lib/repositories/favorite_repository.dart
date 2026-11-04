import '../core/network/api_client.dart';
import '../core/network/endpoints.dart';
import '../models/json_utils.dart';
import '../models/product.dart';

/// Favoritos persistidos no servidor, vinculados ao usuário do token.
class FavoriteRepository {
  FavoriteRepository(this._api);

  final ApiClient _api;

  Future<List<Product>> list() async {
    final data = await _api.get(Endpoints.favorites);
    return Json.list(data).map(Product.fromJson).toList();
  }

  Future<void> add(String produtoId) =>
      _api.post(Endpoints.favoriteAdd, body: {'produto_id': produtoId});

  Future<void> remove(String produtoId) =>
      _api.post(Endpoints.favoriteRemove, body: {'produto_id': produtoId});
}
