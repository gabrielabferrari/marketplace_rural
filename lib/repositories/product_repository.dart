import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
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

  /// Filtros aceitos pelo backend (`escopo`, `categoria`, `busca`).
  Map<String, dynamic> toServerQuery() => {
        'escopo': somenteMeus ? 'meus' : 'catalogo',
        'categoria': categoria?.name,
        'busca': busca?.trim(),
      };
}

/// Produtos e estoque no backend do site (`backend/produtos/`).
///
/// Filtros que o servidor não oferece (disponíveis, ordenação e limite) são
/// aplicados aqui, sobre a lista recebida. A cidade ainda não é filtrada:
/// o backend não expõe a localização do anúncio na listagem.
class ProductRepository {
  ProductRepository(this._api, this._currentUser);

  final ApiClient _api;
  final AppUser? Function() _currentUser;

  Future<List<Product>> list([ProductQuery query = const ProductQuery()]) async {
    if (query.somenteMeus) {
      Permissions.ensure(_currentUser(), Feature.manageProducts);
    }
    final data = await _api.get(Endpoints.products, query: query.toServerQuery());
    var items = Json.list(data['produtos']).map(Product.fromJson).toList();

    if (query.somenteDisponiveis) {
      items = items.where((p) => p.canBePurchased).toList();
    }
    switch (query.ordem) {
      case ProductSort.recentes:
        break; // o servidor já devolve do mais recente para o mais antigo
      case ProductSort.menorPreco:
        items.sort((a, b) => a.preco.compareTo(b.preco));
      case ProductSort.maiorPreco:
        items.sort((a, b) => b.preco.compareTo(a.preco));
      case ProductSort.nome:
        items.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    }
    final limit = query.limite;
    if (limit != null && items.length > limit) items = items.sublist(0, limit);
    return items;
  }

  /// O backend não tem rota de detalhe: procura no catálogo e, para o próprio
  /// produtor, nos seus anúncios (inclusive pausados).
  Future<Product> detail(String id) async {
    final catalogo = await list(const ProductQuery());
    for (final p in catalogo) {
      if (p.id == id) return p;
    }
    if (_currentUser()?.isProducer ?? false) {
      final meus = await list(const ProductQuery(somenteMeus: true));
      for (final p in meus) {
        if (p.id == id) return p;
      }
    }
    throw const ApiException(ApiErrorType.notFound, 'Produto não encontrado.');
  }

  /// Cadastra ou edita. O backend aceita uma foto por produto, enviada junto
  /// com os campos (multipart). Sem [imagem], a foto atual é mantida.
  Future<Product> save(Product product, {UploadFile? imagem}) async {
    Permissions.ensure(_currentUser(), Feature.manageProducts);
    final isNew = product.id.isEmpty;
    final data = await _api.multipart(
      isNew ? Endpoints.productCreate : Endpoints.productUpdate,
      fields: product.toRequest(),
      files: imagem == null ? const [] : [imagem],
    );
    return Product.fromJson(Json.map(data['produto']));
  }

  /// Exclusão lógica no servidor (o anúncio fica inativo e some das listas).
  Future<void> delete(String id) async {
    Permissions.ensure(_currentUser(), Feature.manageProducts);
    await _api.post(Endpoints.productDelete, body: {'id': id});
  }

  /// Define o novo saldo em estoque. O backend não guarda motivo nem histórico,
  /// então [motivo] não é enviado.
  Future<Product> updateStock(String id, double quantidade, {String? motivo}) async {
    Permissions.ensure(_currentUser(), Feature.manageStock);
    await _api.post(Endpoints.stockUpdate, body: {
      'id': id,
      'quantidade': quantidade.round(),
    });
    return detail(id);
  }

  /// Histórico de estoque: rota ainda não existe no backend do site.
  Future<List<StockMovement>> stockHistory(String id) async {
    Permissions.ensure(_currentUser(), Feature.manageStock);
    final data = await _api.get(Endpoints.stockHistory, query: {'id': id});
    return Json.list(data['movimentos']).map(StockMovement.fromJson).toList();
  }
}
