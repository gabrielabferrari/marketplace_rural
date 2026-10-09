enum UserRole { produtor, comprador }

UserRole roleFromString(String value) =>
    value == 'produtor' ? UserRole.produtor : UserRole.comprador;

String roleToString(UserRole role) =>
    role == UserRole.produtor ? 'produtor' : 'comprador';

class MarketUser {
  final String id;
  String name;
  String email;
  String password;
  UserRole role;
  String phone;
  String city;

  MarketUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.phone = '',
    this.city = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'role': roleToString(role),
        'phone': phone,
        'city': city,
      };

  factory MarketUser.fromJson(Map<String, dynamic> j) => MarketUser(
        id: j['id'],
        name: j['name'],
        email: j['email'],
        password: j['password'] ?? '',
        role: roleFromString(j['role'] ?? 'comprador'),
        phone: j['phone'] ?? '',
        city: j['city'] ?? '',
      );
}

class Product {
  final String id;
  final String ownerId;
  String name;
  String description;
  String category;
  double price;
  int stock;
  String unit;
  String imageUrl;

  Product({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description = '',
    this.category = 'Outros',
    required this.price,
    required this.stock,
    this.unit = 'un.',
    this.imageUrl = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'stock': stock,
        'unit': unit,
        'imageUrl': imageUrl,
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'],
        ownerId: j['ownerId'],
        name: j['name'],
        description: j['description'] ?? '',
        category: j['category'] ?? 'Outros',
        price: (j['price'] as num).toDouble(),
        stock: j['stock'] ?? 0,
        unit: j['unit'] ?? 'un.',
        imageUrl: j['imageUrl'] ?? '',
      );
}

class CartItem {
  final String productId;
  int quantity;

  CartItem({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> j) =>
      CartItem(productId: j['productId'], quantity: j['quantity'] ?? 1);
}

class OrderItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get total => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        productId: j['productId'],
        productName: j['productName'],
        unitPrice: (j['unitPrice'] as num).toDouble(),
        quantity: j['quantity'],
      );
}

class OrderModel {
  final String id;
  final String buyerId;
  final List<OrderItem> items;
  final DateTime createdAt;
  String status;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.items,
    required this.createdAt,
    this.status = 'Recebido',
  });

  double get total => items.fold(0, (sum, item) => sum + item.total);

  Map<String, dynamic> toJson() => {
        'id': id,
        'buyerId': buyerId,
        'items': items.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        id: j['id'],
        buyerId: j['buyerId'],
        items: (j['items'] as List)
            .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        createdAt: DateTime.parse(j['createdAt']),
        status: j['status'] ?? 'Recebido',
      );
}

class Negotiation {
  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  String proposedPrice;
  String status;

  Negotiation({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.proposedPrice,
    this.status = 'Aberta',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'buyerId': buyerId,
        'sellerId': sellerId,
        'proposedPrice': proposedPrice,
        'status': status,
      };

  factory Negotiation.fromJson(Map<String, dynamic> j) => Negotiation(
        id: j['id'],
        productId: j['productId'],
        buyerId: j['buyerId'],
        sellerId: j['sellerId'],
        proposedPrice: j['proposedPrice'],
        status: j['status'] ?? 'Aberta',
      );
}