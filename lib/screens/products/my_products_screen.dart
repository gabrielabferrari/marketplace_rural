import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/state_views.dart';

enum _Availability { todos, disponiveis, indisponiveis }

/// Gestão dos produtos do produtor logado.
class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final _listKey = GlobalKey<AsyncViewState<List<Product>>>();
  String _query = '';
  ProductCategory? _category;
  _Availability _availability = _Availability.todos;

  Future<void> _openForm([Product? product]) async {
    final saved = await Navigator.pushNamed(context, AppRoutes.productForm, arguments: product);
    if (saved == true) _listKey.currentState?.reload();
  }

  Future<void> _delete(Product product) async {
    final ok = await AppFeedback.confirm(
      context,
      title: 'Excluir produto?',
      message: '"${product.nome}" será removido do catálogo. Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ProductRepository>().delete(product.id);
      if (!mounted) return;
      AppFeedback.success(context, 'Produto excluído.');
      _listKey.currentState?.reload();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    }
  }

  List<Product> _filter(List<Product> all) {
    final q = _query.toLowerCase();
    return all.where((p) {
      if (q.isNotEmpty && !p.nome.toLowerCase().contains(q)) return false;
      if (_category != null && p.categoria != _category) return false;
      return switch (_availability) {
        _Availability.todos => true,
        _Availability.disponiveis => p.disponivel,
        _Availability.indisponiveis => !p.disponivel,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProductRepository>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo produto'),
      ),
      body: AsyncView<List<Product>>(
        key: _listKey,
        feature: 'Meus produtos',
        load: () => repo.list(const ProductQuery(somenteMeus: true)),
        isEmpty: (d) => d.isEmpty,
        empty: EmptyView(
          icon: Icons.storefront_outlined,
          title: 'Nenhum produto cadastrado',
          message: 'Cadastre seu primeiro produto para que compradores possam encontrá-lo.',
          action: FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Cadastrar produto'),
          ),
        ),
        builder: (context, all, reload) {
          final items = _filter(all);
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                PageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      SearchField(
                        hint: 'Pesquisar meus produtos',
                        onChanged: (v) => setState(() => _query = v.trim()),
                      ),
                      const SizedBox(height: 12),
                      CategorySelector(
                        selected: _category,
                        onSelected: (c) => setState(() => _category = c),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<_Availability>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: _Availability.todos, label: Text('Todos')),
                          ButtonSegment(value: _Availability.disponiveis, label: Text('Ativos')),
                          ButtonSegment(value: _Availability.indisponiveis, label: Text('Pausados')),
                        ],
                        selected: {_availability},
                        onSelectionChanged: (s) => setState(() => _availability = s.first),
                      ),
                      const SizedBox(height: 14),
                      Text('${items.length} de ${all.length} produto(s)',
                          style: context.text.bodySmall?.copyWith(color: context.palette.muted)),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: EmptyView(
                            icon: Icons.filter_alt_off_outlined,
                            title: 'Nenhum resultado',
                            message: 'Ajuste a pesquisa ou os filtros.',
                          ),
                        ),
                      for (final p in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ProductListTile(
                            product: p,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: p),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Ações',
                              onSelected: (v) => switch (v) {
                                'ver' => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: p),
                                'editar' => _openForm(p),
                                _ => _delete(p),
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'ver',
                                  child: ListTile(leading: Icon(Icons.visibility_outlined), title: Text('Visualizar')),
                                ),
                                const PopupMenuItem(
                                  value: 'editar',
                                  child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar')),
                                ),
                                PopupMenuItem(
                                  value: 'excluir',
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline_rounded, color: context.palette.danger),
                                    title: Text('Excluir', style: TextStyle(color: context.palette.danger)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
