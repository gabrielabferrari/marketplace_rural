import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/state_views.dart';

class CatalogArgs {
  const CatalogArgs({
    this.busca,
    this.categoria,
    this.cidade,
    this.title,
    this.sort = ProductSort.recentes,
  });

  final String? busca;
  final ProductCategory? categoria;
  final String? cidade;
  final String? title;
  final ProductSort sort;
}

/// Catálogo como página própria (aberto pela busca/categorias).
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key, this.args = const CatalogArgs()});

  final CatalogArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(args.title ?? 'Produtos')),
      body: CatalogView(args: args, autofocus: args.categoria == null && args.cidade == null),
    );
  }
}

/// Catálogo com busca, filtro por categoria e ordenação.
class CatalogView extends StatefulWidget {
  const CatalogView({super.key, this.args = const CatalogArgs(), this.autofocus = false});

  final CatalogArgs args;
  final bool autofocus;

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  late final _search = TextEditingController(text: widget.args.busca);
  late ProductCategory? _category = widget.args.categoria;
  late ProductSort _sort = widget.args.sort;
  late String _query = widget.args.busca ?? '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProductRepository>();
    final query = ProductQuery(
      busca: _query,
      categoria: _category,
      cidade: widget.args.cidade,
      ordem: _sort,
    );

    return Column(
      children: [
        PageContainer(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SearchField(
                      controller: _search,
                      autofocus: widget.autofocus,
                      hint: 'Buscar produtos ou produtores',
                      onChanged: _onSearch,
                      onSubmitted: (v) => setState(() => _query = v.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<ProductSort>(
                    tooltip: 'Ordenar',
                    initialValue: _sort,
                    onSelected: (v) => setState(() => _sort = v),
                    icon: const Icon(Icons.sort_rounded),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: ProductSort.recentes, child: Text('Mais recentes')),
                      PopupMenuItem(value: ProductSort.menorPreco, child: Text('Menor preço')),
                      PopupMenuItem(value: ProductSort.maiorPreco, child: Text('Maior preço')),
                      PopupMenuItem(value: ProductSort.nome, child: Text('Nome (A–Z)')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CategorySelector(
                selected: _category,
                onSelected: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<Product>>(
            key: ValueKey('${query.toQuery()}'),
            feature: 'O catálogo de produtos',
            load: () => repo.list(query),
            isEmpty: (d) => d.isEmpty,
            empty: EmptyView(
              icon: Icons.search_off_rounded,
              title: 'Nenhum produto encontrado',
              message: _query.isEmpty && _category == null
                  ? 'Ainda não há produtos anunciados.'
                  : 'Tente outro termo de busca ou remova os filtros.',
            ),
            builder: (context, products, reload) => RefreshIndicator(
              onRefresh: reload,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: PageContainer(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 10),
                        child: Text('${products.length} produto(s)',
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: ProductGrid(
                      products: products,
                      onTap: (p) => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: p),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
