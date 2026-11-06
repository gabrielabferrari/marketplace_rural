import '../core/network/api_client.dart';
import '../core/network/endpoints.dart';
import '../models/json_utils.dart';
import '../models/product.dart';

/// Favoritos persistidos no servidor, vinculados à sessão do usuário.
class FavoriteRepository {
  FavoriteRepository(this._api);

  final ApiClient _api;

  Future<List<Product>> list() async {
    final data = await _api.get(Endpoints.favorites);
    return Json.list(data['produtos']).map(Product.fromJson).toList();
  }

  Future<void> add(String produtoId) => _api.post(Endpoints.favoriteUpdate, body: {
        'acao': 'adicionar',
        'anuncio_id': produtoId,
      });

  Future<void> remove(String produtoId) => _api.post(Endpoints.favoriteUpdate, body: {
        'acao': 'remover',
        'anuncio_id': produtoId,
      });
}
