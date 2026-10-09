import 'package:flutter/material.dart';
import '../data/local_store.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'login_page.dart';
import 'product_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  final store = LocalStore.instance;

  void refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final user = store.currentUser!;
    final isProducer = user.role == UserRole.produtor;

    final pages = isProducer
        ? [
            _Dashboard(user: user, onRefresh: refresh),
            _MyProducts(onRefresh: refresh),
            _OrdersPage(onRefresh: refresh),
            _StockPage(onRefresh: refresh),
            _SettingsPage(onRefresh: refresh),
          ]
        : [
            _Dashboard(user: user, onRefresh: refresh),
            _Catalog(onRefresh: refresh),
            _CartPage(onRefresh: refresh),
            _OrdersPage(onRefresh: refresh),
            _SettingsPage(onRefresh: refresh),
          ];

    final labels = isProducer
        ? ['Início', 'Produtos', 'Pedidos', 'Estoque', 'Perfil']
        : ['Início', 'Produtos', 'Carrinho', 'Pedidos', 'Perfil'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MarketPlace Rural'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () async {
              await store.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          for (final label in labels)
            NavigationDestination(
              icon: Icon(_iconFor(label)),
              label: label,
            )
        ],
      ),
    );
  }

  IconData _iconFor(String label) {
    switch (label) {
      case 'Produtos':
        return Icons.inventory_2_outlined;
      case 'Pedidos':
        return Icons.receipt_long_outlined;
      case 'Carrinho':
        return Icons.shopping_cart_outlined;
      case 'Estoque':
        return Icons.warehouse_outlined;
      case 'Perfil':
        return Icons.person_outline;
      default:
        return Icons.home_outlined;
    }
  }
}

class _Dashboard extends StatelessWidget {
  final MarketUser user;
  final VoidCallback onRefresh;

  const _Dashboard({required this.user, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    final producer = user.role == UserRole.produtor;
    final ownProducts =
        store.products.where((p) => p.ownerId == user.id).length;
    final myOrders = store.orders.where((o) => o.buyerId == user.id).length;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text('Olá, ${user.name.split(' ').first}! 👋',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(producer
            ? 'Gerencie seus produtos e estoque.'
            : 'Encontre produtos direto dos produtores.'),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                  title: producer ? 'Meus produtos' : 'Pedidos',
                  value: '${producer ? ownProducts : myOrders}',
                  icon: producer ? Icons.inventory : Icons.shopping_bag),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                  title: producer ? 'Estoque' : 'Favoritos',
                  value: producer
                      ? '${store.products.where((p) => p.ownerId == user.id).fold<int>(0, (s, p) => s + p.stock)}'
                      : '${store.favorites.length}',
                  icon: producer ? Icons.warehouse : Icons.favorite_border),
            ),
          ],
        ),
        const SizedBox(height: 25),
        const Text('Produtos em destaque',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...store.products.take(4).map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProductCard(
                  product: p,
                  favorite: store.favorites.contains(p.id),
                  onFavorite: producer
                      ? null
                      : () {
                          store.toggleFavorite(p.id);
                          onRefresh();
                        },
                  onAdd: producer
                      ? null
                      : () {
                          final current = store.cart
                              .where((i) => i.productId == p.id)
                              .fold<int>(0, (s, i) => s + i.quantity);
                          store.setCartQuantity(p.id, current + 1);
                          onRefresh();
                        },
                ),
              ),
            ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard(
      {required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: AppColors.green, size: 30),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(title, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ],
          ),
        ),
      );
}

class _Catalog extends StatefulWidget {
  final VoidCallback onRefresh;
  const _Catalog({required this.onRefresh});

  @override
  State<_Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<_Catalog> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    final products = store.products
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: const InputDecoration(
                hintText: 'Buscar produtos...',
                prefixIcon: Icon(Icons.search)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProductCard(
                  product: p,
                  favorite: store.favorites.contains(p.id),
                  onFavorite: () async {
                    await store.toggleFavorite(p.id);
                    setState(() {});
                  },
                  onAdd: () async {
                    final old = store.cart
                        .where((x) => x.productId == p.id)
                        .fold<int>(0, (s, x) => s + x.quantity);
                    await store.setCartQuantity(p.id, old + 1);
                    if (mounted) setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Adicionado ao carrinho.')));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MyProducts extends StatefulWidget {
  final VoidCallback onRefresh;
  const _MyProducts({required this.onRefresh});

  @override
  State<_MyProducts> createState() => _MyProductsState();
}

class _MyProductsState extends State<_MyProducts> {
  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    final mine = store.products
        .where((p) => p.ownerId == store.currentUser!.id)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Meus Produtos',
                    style:
                        TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              ),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProductFormPage()),
                  );
                  setState(() {});
                },
                icon: const Icon(Icons.add),
                label: const Text('Novo'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...mine.map(
            (p) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.agriculture),
                ),
                title: Text(p.name),
                subtitle:
                    Text('R\$ ${p.price.toStringAsFixed(2)} • Estoque: ${p.stock}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'editar') {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProductFormPage(product: p)));
                    } else {
                      await store.deleteProduct(p.id);
                    }
                    setState(() {});
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartPage extends StatefulWidget {
  final VoidCallback onRefresh;
  const _CartPage({required this.onRefresh});

  @override
  State<_CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<_CartPage> {
  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    final items = store.cart.toList();
    double total = 0;

    for (final item in items) {
      final p = store.products.where((p) => p.id == item.productId);
      if (p.isNotEmpty) total += p.first.price * item.quantity;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Meu Carrinho',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        if (items.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Center(child: Text('Seu carrinho está vazio.')),
            ),
          ),
        ...items.map((item) {
          final p = store.products.firstWhere((p) => p.id == item.productId);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(p.name),
              subtitle: Text('R\$ ${p.price.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () async {
                        await store.setCartQuantity(
                            p.id, item.quantity - 1);
                        setState(() {});
                      },
                      icon: const Icon(Icons.remove)),
                  Text('${item.quantity}'),
                  IconButton(
                      onPressed: item.quantity < p.stock
                          ? () async {
                              await store.setCartQuantity(
                                  p.id, item.quantity + 1);
                              setState(() {});
                            }
                          : null,
                      icon: const Icon(Icons.add)),
                ],
              ),
            ),
          );
        }),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Total: R\$ ${total.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              try {
                final order = await store.checkout();
                if (!context.mounted) return;
                setState(() {});
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Pedido realizado!'),
                    content: Text(
                        'Pedido ${order.id} criado com sucesso.\nEstoque atualizado automaticamente.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'))
                    ],
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            },
            child: const Text('Finalizar pedido'),
          ),
        ],
      ],
    );
  }
}

class _OrdersPage extends StatelessWidget {
  final VoidCallback onRefresh;
  const _OrdersPage({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    final orders = store.orders
        .where((o) => o.buyerId == store.currentUser!.id)
        .toList()
        .reversed
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Pedidos',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        if (orders.isEmpty)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(25),
                  child: Center(child: Text('Nenhum pedido ainda.')))),
        ...orders.map((o) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                title: Text('Pedido ${o.id}'),
                subtitle: Text(o.status),
                trailing: Text('R\$ ${o.total.toStringAsFixed(2)}'),
                children: o.items
                    .map((i) => ListTile(
                          title: Text(i.productName),
                          subtitle: Text('${i.quantity} x R\$ ${i.unitPrice.toStringAsFixed(2)}'),
                        ))
                    .toList(),
              ),
            )),
      ],
    );
  }
}

class _StockPage extends StatelessWidget {
  final VoidCallback onRefresh;
  const _StockPage({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    final mine =
        store.products.where((p) => p.ownerId == store.currentUser!.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Estoque',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        ...mine.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  p.stock == 0 ? Icons.warning : Icons.inventory,
                  color: p.stock == 0 ? Colors.red : AppColors.green,
                ),
                title: Text(p.name),
                subtitle: Text('${p.stock} ${p.unit} disponíveis'),
              ),
            )),
      ],
    );
  }
}

class _SettingsPage extends StatefulWidget {
  final VoidCallback onRefresh;
  const _SettingsPage({required this.onRefresh});

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  late TextEditingController name;
  late TextEditingController phone;
  late TextEditingController city;

  @override
  void initState() {
    super.initState();
    final u = LocalStore.instance.currentUser!;
    name = TextEditingController(text: u.name);
    phone = TextEditingController(text: u.phone);
    city = TextEditingController(text: u.city);
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = LocalStore.instance.currentUser!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Meu Perfil',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        CircleAvatar(
          radius: 38,
          child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: 20),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 12),
        TextField(
            controller: phone,
            decoration: const InputDecoration(labelText: 'Telefone')),
        const SizedBox(height: 12),
        TextField(
            controller: city,
            decoration: const InputDecoration(labelText: 'Cidade')),
        const SizedBox(height: 12),
        Text('E-mail: ${u.email}'),
        const SizedBox(height: 15),
        FilledButton(
          onPressed: () async {
            await LocalStore.instance.updateProfile(
              name: name.text.trim(),
              phone: phone.text.trim(),
              city: city.text.trim(),
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Perfil atualizado.')));
              setState(() {});
            }
          },
          child: const Text('Salvar alterações'),
        ),
      ],
    );
  }
}