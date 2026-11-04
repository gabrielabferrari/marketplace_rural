import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/product.dart';
import '../repositories/favorite_repository.dart';

/// Favoritos do usuário logado, sincronizados com o servidor.
class FavoritesController extends ChangeNotifier {
  FavoritesController(this._repository);

  final FavoriteRepository _repository;

  List<Product> _items = const [];
  final Set<String> _ids = {};
  bool _loading = false;
  bool _loaded = false;
  ApiException? _error;

  List<Product> get items => _items;
  bool get loading => _loading;
  bool get loaded => _loaded;
  ApiException? get error => _error;

  bool isFavorite(String productId) => _ids.contains(productId);

  Future<void> load({bool force = false}) async {
    if (_loading || (_loaded && !force)) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repository.list();
      _ids
        ..clear()
        ..addAll(_items.map((p) => p.id));
      _loaded = true;
    } catch (e) {
      _error = ApiException.from(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Alterna o favorito com atualização otimista; desfaz se o servidor falhar.
  Future<void> toggle(Product product) async {
    final wasFavorite = _ids.contains(product.id);
    final previousItems = _items;
    if (wasFavorite) {
      _ids.remove(product.id);
      _items = _items.where((p) => p.id != product.id).toList();
    } else {
      _ids.add(product.id);
      _items = [product, ..._items];
    }
    notifyListeners();
    try {
      if (wasFavorite) {
        await _repository.remove(product.id);
      } else {
        await _repository.add(product.id);
      }
    } catch (e) {
      if (wasFavorite) {
        _ids.add(product.id);
      } else {
        _ids.remove(product.id);
      }
      _items = previousItems;
      notifyListeners();
      throw ApiException.from(e);
    }
  }

  void reset() {
    _items = const [];
    _ids.clear();
    _loaded = false;
    _error = null;
    notifyListeners();
  }
}
