import '../core/network/api_client.dart';
import '../core/network/endpoints.dart';
import '../core/routes/permissions.dart';
import '../models/json_utils.dart';
import '../models/product.dart';
import '../models/user.dart';

enum ProductSort { recentes, menorPreco, maiorPreco, nome }

class ProductQuery {
  const ProductQuery({
    this.busca,
    this.categoria,
    this.cidade,
    this.somenteMeus = false,
    this.somenteDisponiveis = false,
    this.ordem = ProductSort.recentes,
    this.limite,
  });

  final String? busca;
  final ProductCategory? categoria;
  final String? cidade;
  final bool somenteMeus;
  final bool somenteDisponiveis;
  final ProductSort ordem;
  final int? limite;

  Map<String, dynamic> toQuery() => {
        'busca': busca?.trim(),
        'categoria': categoria?.label,
        'cidade': cidade?.trim(),
        if (somenteMeus) 'meus': 1,
        if (somenteDisponiveis) 'disponiveis': 1,
        'ordem': ordem.name,
        'limite': limite,
      };
}

class ProductRepository {
  ProductRepository(this._api, this._currentUser);

  final ApiClient _api;
  final AppUser? Function() _currentUser;

  Future<List<Product>> list([ProductQuery query = const ProductQuery()]) async {
    if (query.somenteMeus) {
      Permissions.ensure(_currentUser(), Feature.manageProducts);
    }
    final data = await _api.get(Endpoints.products, query: query.toQuery());
    return Json.list(data).map(Product.fromJson).toList();
  }

  Future<Product> detail(String id) async {
    final data = await _api.get(Endpoints.productDetail, query: {'id': id});
    return Product.fromJson(Json.map(Json.map(data)['produto'] ?? data));
  }

  Future<Product> save(Product product) async {
    Permissions.ensure(_currentUser(), Feature.manageProducts);
    final isNew = product.id.isEmpty;
    final data = isNew
        ? await _api.post(Endpoints.productCreate, body: product.toRequest())
        : await _api.put(Endpoints.productUpdate, body: product.toRequest());
    final map = Json.map(data);
    return Product.fromJson(Json.map(map['produto'] ?? map));
  }

  Future<void> delete(String id) async {
    Permissions.ensure(_currentUser(), Feature.manageProducts);
    await _api.delete(Endpoints.productDelete, query: {'id': id});
  }

  /// Envia uma imagem e devolve a URL pública gerada pelo servidor.
  Future<String> uploadImage(UploadFile file) async {
    Permissions.ensure(_currentUser(), Feature.manageProducts);
    final data = Json.map(await _api.multipart(
      Endpoints.productImageUpload,
      files: [file],
    ));
    final url = Json.stringOrNull(data['url']);
    if (url == null) {
      throw const FormatException('O servidor não retornou a URL da imagem.');
    }
    return url;
  }

  Future<Product> updateStock(String id, double quantidade, {String? motivo}) async {
    Permissions.ensure(_currentUser(), Feature.manageStock);
    final data = await _api.post(Endpoints.stockUpdate, body: {
      'id': id,
      'quantidade': quantidade,
      if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
    });
    final map = Json.map(data);
    return Product.fromJson(Json.map(map['produto'] ?? map));
  }

  Future<List<StockMovement>> stockHistory(String id) async {
    Permissions.ensure(_currentUser(), Feature.manageStock);
    final data = await _api.get(Endpoints.stockHistory, query: {'id': id});
    return Json.list(data).map(StockMovement.fromJson).toList();
  }
}
