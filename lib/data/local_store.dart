import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class LocalStore {
  LocalStore._();
  static final instance = LocalStore._();

  late SharedPreferences _prefs;

  final users = <MarketUser>[];
  final products = <Product>[];
  final orders = <OrderModel>[];
  final negotiations = <Negotiation>[];
  final cart = <CartItem>[];
  final favorites = <String>[];

  String? currentUserId;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    _loadUsers();
    _loadProducts();
    _loadOrders();
    _loadNegotiations();
    _loadCart();
    favorites
      ..clear()
      ..addAll(_prefs.getStringList('favorites') ?? []);
    currentUserId = _prefs.getString('currentUserId');

    if (users.isEmpty) _seed();
  }

  MarketUser? get currentUser {
    if (currentUserId == null) return null;
    for (final user in users) {
      if (user.id == currentUserId) return user;
    }
    return null;
  }

  void _seed() {
    users.addAll([
      MarketUser(
        id: 'u1',
        name: 'Produtor Rural',
        email: 'produtor@email.com',
        password: '123456',
        role: UserRole.produtor,
        city: 'Mococa - SP',
      ),
      MarketUser(
        id: 'u2',
        name: 'Comprador',
        email: 'comprador@email.com',
        password: '123456',
        role: UserRole.comprador,
        city: 'Mococa - SP',
      ),
    ]);

    products.addAll([
      Product(
        id: 'p1',
        ownerId: 'u1',
        name: 'Café Especial',
        description: 'Café especial produzido na região.',
        category: 'Café',
        price: 28.90,
        stock: 35,
        unit: 'kg',
      ),
      Product(
        id: 'p2',
        ownerId: 'u1',
        name: 'Queijo Artesanal',
        description: 'Queijo artesanal fresco.',
        category: 'Laticínios',
        price: 42.00,
        stock: 18,
        unit: 'un.',
      ),
      Product(
        id: 'p3',
        ownerId: 'u1',
        name: 'Alface',
        description: 'Alface fresca.',
        category: 'Hortaliças',
        price: 4.50,
        stock: 80,
        unit: 'un.',
      ),
    ]);
    _persist();
  }

  void _loadUsers() => _decodeList('users', (j) => users.add(MarketUser.fromJson(j)));
  void _loadProducts() => _decodeList('products', (j) => products.add(Product.fromJson(j)));
  void _loadOrders() => _decodeList('orders', (j) => orders.add(OrderModel.fromJson(j)));
  void _loadNegotiations() =>
      _decodeList('negotiations', (j) => negotiations.add(Negotiation.fromJson(j)));
  void _loadCart() => _decodeList('cart', (j) => cart.add(CartItem.fromJson(j)));

  void _decodeList(String key, void Function(Map<String, dynamic>) add) {
    final raw = _prefs.getString(key);
    if (raw == null) return;
    try {
      for (final item in jsonDecode(raw)) {
        add(Map<String, dynamic>.from(item));
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    await _prefs.setString(
        'users', jsonEncode(users.map((e) => e.toJson()).toList()));
    await _prefs.setString(
        'products', jsonEncode(products.map((e) => e.toJson()).toList()));
    await _prefs.setString(
        'orders', jsonEncode(orders.map((e) => e.toJson()).toList()));
    await _prefs.setString('negotiations',
        jsonEncode(negotiations.map((e) => e.toJson()).toList()));
    await _prefs.setString(
        'cart', jsonEncode(cart.map((e) => e.toJson()).toList()));
    await _prefs.setStringList('favorites', favorites);
    if (currentUserId == null) {
      await _prefs.remove('currentUserId');
    } else {
      await _prefs.setString('currentUserId', currentUserId!);
    }
  }

  Future<MarketUser?> login(String email, String password) async {
    for (final user in users) {
      if (user.email.toLowerCase() == email.trim().toLowerCase() &&
          user.password == password) {
        currentUserId = user.id;
        await _persist();
        return user;
      }
    }
    return null;
  }

  Future<MarketUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String phone = '',
    String city = '',
  }) async {
    if (users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      throw Exception('E-mail já cadastrado.');
    }
    final user = MarketUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email.trim(),
      password: password,
      role: role,
      phone: phone,
      city: city,
    );
    users.add(user);
    await _persist();
    return user;
  }

  Future<void> logout() async {
    currentUserId = null;
    cart.clear();
    await _persist();
  }

  Future<void> saveProduct(Product product) async {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      products[index] = product;
    } else {
      products.add(product);
    }
    await _persist();
  }

  Future<void> deleteProduct(String id) async {
    products.removeWhere((p) => p.id == id);
    cart.removeWhere((i) => i.productId == id);
    favorites.remove(id);
    await _persist();
  }

  Future<void> setCartQuantity(String productId, int quantity) async {
    cart.removeWhere((i) => i.productId == productId);
    if (quantity > 0) cart.add(CartItem(productId: productId, quantity: quantity));
    await _persist();
  }

  Future<void> toggleFavorite(String productId) async {
    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }
    await _persist();
  }

  Future<OrderModel> checkout() async {
    final user = currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
    if (cart.isEmpty) throw Exception('Carrinho vazio.');

    final items = <OrderItem>[];

    for (final item in cart) {
      final product = products.firstWhere((p) => p.id == item.productId);
      if (item.quantity > product.stock) {
        throw Exception('Estoque insuficiente para ${product.name}.');
      }
      items.add(OrderItem(
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
        quantity: item.quantity,
      ));
      product.stock -= item.quantity;
    }

    final order = OrderModel(
      id: 'ped_${DateTime.now().millisecondsSinceEpoch}',
      buyerId: user.id,
      items: items,
      createdAt: DateTime.now(),
    );
    orders.add(order);
    cart.clear();
    await _persist();
    return order;
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String city,
  }) async {
    final user = currentUser;
    if (user == null) return;
    user.name = name;
    user.phone = phone;
    user.city = city;
    await _persist();
  }
}