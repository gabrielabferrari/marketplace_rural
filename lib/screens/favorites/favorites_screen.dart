import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/favorites_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/common.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/state_views.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();

    if (favorites.loading && !favorites.loaded) return const LoadingView();
    if (favorites.error != null && !favorites.loaded) {
      return ErrorView(
        error: favorites.error!,
        feature: 'Os favoritos',
        onRetry: () => favorites.load(force: true),
      );
    }

    final q = _query.toLowerCase();
    final items = favorites.items
        .where((p) => q.isEmpty || p.nome.toLowerCase().contains(q) || p.categoria.label.toLowerCase().contains(q))
        .toList();

    return RefreshIndicator(
      onRefresh: () => favorites.load(force: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: PageContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SearchField(
                  hint: 'Pesquisar favoritos',
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
            ),
          ),
          if (favorites.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.favorite_border_rounded,
                title: 'Nenhum favorito ainda',
                message: 'Toque no coração dos produtos para guardá-los aqui.',
                action: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.catalog),
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Explorar produtos'),
                ),
              ),
            )
          else if (items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(icon: Icons.search_off_rounded, title: 'Nenhum favorito encontrado'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              sliver: ProductGrid(
                products: items,
                onTap: (p) => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: p),
              ),
            ),
        ],
      ),
    );
  }
}
