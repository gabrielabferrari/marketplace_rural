import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/favorites_controller.dart';
import '../../controllers/preferences_controller.dart';
import '../../controllers/session_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/negotiation.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../repositories/negotiation_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common.dart';
import '../../widgets/order_widgets.dart';
import '../../widgets/product_widgets.dart';
import '../products/catalog_screen.dart';
import '../shell/app_section.dart';

/// Página inicial: vitrine para compradores, painel para produtores.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Incrementado no "puxar para atualizar" para recriar os blocos.
  int _refreshSeed = 0;

  Future<void> _refresh() async {
    setState(() => _refreshSeed++);
    await context.read<FavoritesController>().load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        key: ValueKey(_refreshSeed),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Greeting(user: user),
                  const SizedBox(height: 16),
                  SearchField(
                    readOnly: true,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.catalog),
                  ),
                  if (user.isProducer) _ProducerDashboard(user: user) else _BuyerDiscovery(user: user),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final region = context.watch<PreferencesController>().region;
    final location = user.cidade ?? (region.isEmpty ? null : region);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Formatters.greeting()}, ${Formatters.firstName(user.nome)}!',
                  style: context.text.headlineSmall,
                ),
                const SizedBox(height: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: location == null ? () => _askRegion(context) : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: context.palette.earth),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          location ?? 'Definir minha região',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: location == null ? context.colors.primary : context.palette.muted,
                            fontWeight: location == null ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          UserAvatar(name: user.nome, imageUrl: user.fotoUrl, radius: 26),
        ],
      ),
    );
  }
}

/// Diálogo para definir a região usada em "Produtos perto de você".
Future<void> _askRegion(BuildContext context) async {
  final prefs = context.read<PreferencesController>();
  final controller = TextEditingController(text: prefs.region);
  final value = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sua região'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Ex.: Mococa - SP'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (value != null) await prefs.setRegion(value);
}

// ───────────────────────────── COMPRADOR ─────────────────────────────

class _BuyerDiscovery extends StatelessWidget {
  const _BuyerDiscovery({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final products = context.read<ProductRepository>();
    final region = context.watch<PreferencesController>().region;
    final favorites = context.watch<FavoritesController>();
    final favCategories = favorites.items.map((p) => p.categoria).toSet();

    void openProduct(Product p) =>
        Navigator.pushNamed(context, AppRoutes.productDetail, arguments: p);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Categorias',
          actionLabel: 'Ver todos',
          onAction: () => Navigator.pushNamed(context, AppRoutes.catalog),
        ),
        const _CategoryGrid(),
        _QuickOrdersCard(user: user),
        SectionHeader(
          title: 'Produtos perto de você',
          actionLabel: region.isEmpty ? 'Definir região' : 'Ver todos',
          onAction: region.isEmpty
              ? () => _askRegion(context)
              : () => Navigator.pushNamed(context, AppRoutes.catalog,
                  arguments: CatalogArgs(cidade: region, title: 'Perto de você')),
        ),
        if (region.isEmpty)
          _HintCard(
            icon: Icons.near_me_outlined,
            text: 'Informe sua cidade para ver produtos de produtores da sua região.',
            actionLabel: 'Definir região',
            onAction: () => _askRegion(context),
          )
        else
          InlineAsync<List<Product>>(
            key: ValueKey('near-$region'),
            load: () => products.list(ProductQuery(cidade: region, somenteDisponiveis: true, limite: 10)),
            isEmpty: (d) => d.isEmpty,
            emptyMessage: 'Ainda não há produtos anunciados em $region.',
            height: 236,
            builder: (context, data) => _ProductCarousel(products: data, onTap: openProduct),
          ),
        SectionHeader(
          title: 'Produtos em destaque',
          actionLabel: 'Ver todos',
          onAction: () => Navigator.pushNamed(context, AppRoutes.catalog),
        ),
        InlineAsync<List<Product>>(
          load: () => products.list(const ProductQuery(somenteDisponiveis: true, limite: 10)),
          isEmpty: (d) => d.isEmpty,
          emptyMessage: 'Nenhum produto anunciado no momento.',
          height: 236,
          builder: (context, data) => _ProductCarousel(products: data, onTap: openProduct),
        ),
        if (favCategories.isNotEmpty) ...[
          SectionHeader(title: 'Sugestões para você'),
          InlineAsync<List<Product>>(
            key: ValueKey(favCategories.map((c) => c.name).join()),
            load: () async {
              final results = await Future.wait(favCategories.take(3).map((c) =>
                  products.list(ProductQuery(categoria: c, somenteDisponiveis: true, limite: 6))));
              final seen = favorites.items.map((p) => p.id).toSet();
              return results.expand((l) => l).where((p) => seen.add(p.id)).toList();
            },
            isEmpty: (d) => d.isEmpty,
            emptyMessage: 'Sem novas sugestões nas categorias que você favoritou.',
            height: 236,
            builder: (context, data) => _ProductCarousel(products: data, onTap: openProduct),
          ),
        ],
        SectionHeader(
          title: 'Adicionados recentemente',
          actionLabel: 'Ver todos',
          onAction: () => Navigator.pushNamed(context, AppRoutes.catalog,
              arguments: const CatalogArgs(sort: ProductSort.recentes)),
        ),
        InlineAsync<List<Product>>(
          load: () => products.list(const ProductQuery(ordem: ProductSort.recentes, limite: 6)),
          isEmpty: (d) => d.isEmpty,
          emptyMessage: 'Nenhum produto recente.',
          builder: (context, data) => Column(
            children: [
              for (final p in data)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ProductListTile(
                    product: p,
                    onTap: () => openProduct(p),
                    subtitle: Text(
                      [p.produtorNome, p.localizacao].whereType<String>().join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(color: context.palette.muted),
                    ),
                    trailing: FavoriteButton(product: p),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 700 ? 8 : 4;
      const spacing = 10.0;
      final size = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final c in ProductCategory.values)
            SizedBox(
              width: size,
              child: Material(
                color: context.palette.softSurface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.catalog,
                      arguments: CatalogArgs(categoria: c)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.palette.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.palette.accentSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(c.icon, color: context.colors.primary, size: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _ProductCarousel extends StatelessWidget {
  const _ProductCarousel({required this.products, required this.onTap});

  final List<Product> products;
  final void Function(Product) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: 170,
          child: ProductCard(product: products[i], onTap: () => onTap(products[i])),
        ),
      ),
    );
  }
}

class _QuickOrdersCard extends StatelessWidget {
  const _QuickOrdersCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Material(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF1F3A29), AppColors.darkCard]
                  : const [AppColors.forest, AppColors.green],
            ),
          ),
          child: InkWell(
            onTap: () => context.read<ShellController>().select(AppSection.orders, user),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_shipping_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Meus pedidos',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        SizedBox(height: 2),
                        Text('Acompanhe entregas e o histórico de compras',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.icon, required this.text, this.actionLabel, this.onAction});

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: context.palette.earth),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
            if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── PRODUTOR ─────────────────────────────

class _ProducerSnapshot {
  const _ProducerSnapshot(this.products, this.orders, this.negotiations);

  final List<Product>? products;
  final List<Order>? orders;
  final List<Negotiation>? negotiations;
}

class _ProducerDashboard extends StatelessWidget {
  const _ProducerDashboard({required this.user});

  final AppUser user;

  Future<_ProducerSnapshot> _load(BuildContext context) async {
    final products = context.read<ProductRepository>();
    final orders = context.read<OrderRepository>();
    final negotiations = context.read<NegotiationRepository>();
    // Cada fonte é independente: uma falha não esconde as demais.
    Future<T?> safe<T>(Future<T> f) => f.then<T?>((v) => v).catchError((_) => null);
    final results = await Future.wait([
      safe(products.list(const ProductQuery(somenteMeus: true))),
      safe(orders.list()),
      safe(negotiations.list(status: NegotiationStatus.aberta)),
    ]);
    final snapshot = _ProducerSnapshot(
      results[0] as List<Product>?,
      results[1] as List<Order>?,
      results[2] as List<Negotiation>?,
    );
    if (snapshot.products == null && snapshot.orders == null && snapshot.negotiations == null) {
      // Propaga o erro real (para exibir "aguardando servidor" ou "sem conexão").
      await products.list(const ProductQuery(somenteMeus: true));
    }
    return snapshot;
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.read<ShellController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        SectionHeader(title: 'Ações rápidas'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Novo produto'),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.productForm),
            ),
            ActionChip(
              avatar: const Icon(Icons.warehouse_outlined, size: 18),
              label: const Text('Atualizar estoque'),
              onPressed: () => shell.select(AppSection.stock, user),
            ),
            ActionChip(
              avatar: const Icon(Icons.handshake_outlined, size: 18),
              label: const Text('Negociações'),
              onPressed: () => shell.select(AppSection.negotiations, user),
            ),
            ActionChip(
              avatar: const Icon(Icons.agriculture_outlined, size: 18),
              label: const Text('Minha fazenda'),
              onPressed: () => shell.select(AppSection.farm, user),
            ),
          ],
        ),
        SectionHeader(title: 'Resumo do seu negócio'),
        InlineAsync<_ProducerSnapshot>(
          load: () => _load(context),
          builder: (context, data) {
            String count(List? l) => l == null ? '—' : '${l.length}';
            final low = data.products?.where((p) => p.stockLevel != StockLevel.ok).length;
            final pending = data.orders?.where((o) => !o.status.isFinal).length;
            final revenue = data.orders
                ?.where((o) => o.status == OrderStatus.concluido)
                .fold<double>(0, (s, o) => s + o.grandTotal);
            final recentOrders = (data.orders ?? const <Order>[])
                .where((o) => !o.status.isFinal)
                .take(4)
                .toList();
            final attention = (data.products ?? const <Product>[])
                .where((p) => p.stockLevel != StockLevel.ok)
                .take(4)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatGrid(children: [
                  StatCard(
                    label: 'Produtos anunciados',
                    value: count(data.products),
                    icon: Icons.inventory_2_outlined,
                    onTap: () => shell.select(AppSection.products, user),
                  ),
                  StatCard(
                    label: 'Pedidos em andamento',
                    value: pending?.toString() ?? '—',
                    icon: Icons.receipt_long_outlined,
                    color: context.palette.info,
                    onTap: () => shell.select(AppSection.orders, user),
                  ),
                  StatCard(
                    label: 'Estoque em atenção',
                    value: low?.toString() ?? '—',
                    icon: Icons.warning_amber_rounded,
                    color: context.palette.warning,
                    onTap: () => shell.select(AppSection.stock, user),
                  ),
                  StatCard(
                    label: 'Vendas concluídas',
                    value: revenue == null ? '—' : Formatters.currency(revenue),
                    icon: Icons.payments_outlined,
                    color: context.palette.earth,
                    caption: data.negotiations == null
                        ? null
                        : '${data.negotiations!.length} negociação(ões) aberta(s)',
                    onTap: () => shell.select(AppSection.negotiations, user),
                  ),
                ]),
                if (recentOrders.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Pedidos para atender',
                    actionLabel: 'Ver todos',
                    onAction: () => shell.select(AppSection.orders, user),
                  ),
                  for (final o in recentOrders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.orderDetail, arguments: o.id),
                          leading: Icon(o.status.icon, color: orderStatusColor(context, o.status)),
                          title: Text('Pedido #${o.id}'),
                          subtitle: Text('${o.summary} • ${o.compradorNome ?? 'Comprador'}',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: OrderStatusBadge(status: o.status),
                        ),
                      ),
                    ),
                ],
                if (attention.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Estoque que precisa de atenção',
                    actionLabel: 'Ver estoque',
                    onAction: () => shell.select(AppSection.stock, user),
                  ),
                  for (final p in attention)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ProductListTile(
                        product: p,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.productForm, arguments: p),
                      ),
                    ),
                ],
                if (data.products != null && data.products!.isEmpty) ...[
                  const SizedBox(height: 16),
                  _HintCard(
                    icon: Icons.storefront_outlined,
                    text: 'Você ainda não anunciou produtos. Cadastre o primeiro para começar a vender.',
                    actionLabel: 'Cadastrar',
                    onAction: () => Navigator.pushNamed(context, AppRoutes.productForm),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
