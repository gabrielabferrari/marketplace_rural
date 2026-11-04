import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/farm.dart';
import '../../models/product.dart';
import '../../repositories/farm_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/state_views.dart';

/// Painel da propriedade (exclusivo para produtores).
///
/// Mostra somente informações cadastradas pelo produtor e indicadores
/// calculados a partir dos produtos reais — nenhum dado de produção é
/// estimado pelo aplicativo.
class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  final _viewKey = GlobalKey<AsyncViewState<Farm?>>();

  Future<void> _edit(Farm? farm) async {
    final saved = await Navigator.pushNamed(context, AppRoutes.farmForm, arguments: farm);
    if (saved == true) _viewKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<Farm?>(
      key: _viewKey,
      feature: 'A gestão de fazenda',
      load: () => context.read<FarmRepository>().get(),
      isEmpty: (f) => f == null,
      empty: EmptyView(
        icon: Icons.agriculture_outlined,
        title: 'Cadastre sua propriedade',
        message: 'Registre as informações da fazenda para organizar sua produção e '
            'transmitir mais confiança aos compradores.',
        action: FilledButton.icon(
          onPressed: () => _edit(null),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Cadastrar fazenda'),
        ),
      ),
      builder: (context, farm, reload) => RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _FarmHeader(farm: farm!, onEdit: () => _edit(farm)),
                  SectionHeader(title: 'Área da propriedade'),
                  StatGrid(children: [
                    StatCard(
                      label: 'Área total',
                      value: farm.areaTotalHa == null ? '—' : '${Formatters.quantity(farm.areaTotalHa!)} ha',
                      icon: Icons.landscape_outlined,
                      color: context.palette.earth,
                    ),
                    StatCard(
                      label: 'Área de produção',
                      value: farm.areaProducaoHa == null ? '—' : '${Formatters.quantity(farm.areaProducaoHa!)} ha',
                      icon: Icons.grass_outlined,
                    ),
                    StatCard(
                      label: 'Aproveitamento',
                      value: farm.productionShare == null
                          ? '—'
                          : '${(farm.productionShare! * 100).toStringAsFixed(0)}%',
                      icon: Icons.pie_chart_outline_rounded,
                      color: context.palette.info,
                    ),
                    StatCard(
                      label: 'Culturas',
                      value: '${farm.culturas.length}',
                      icon: Icons.spa_outlined,
                      color: context.palette.success,
                    ),
                  ]),
                  if (farm.productionShare != null) ...[
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Uso da área', style: context.text.titleSmall),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: farm.productionShare,
                                minHeight: 12,
                                backgroundColor: context.palette.earth.withValues(alpha: 0.18),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(children: [
                              _Legend(color: context.colors.primary, label: 'Produção'),
                              const SizedBox(width: 16),
                              _Legend(color: context.palette.earth.withValues(alpha: 0.4), label: 'Demais áreas'),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                  SectionHeader(title: 'Informações de cultivo'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (farm.culturas.isEmpty)
                            Text('Nenhuma cultura informada.', style: TextStyle(color: context.palette.muted))
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final c in farm.culturas)
                                  Chip(avatar: const Icon(Icons.eco_outlined, size: 16), label: Text(c)),
                              ],
                            ),
                          if (farm.descricao != null) ...[
                            const SizedBox(height: 14),
                            Text(farm.descricao!, style: const TextStyle(height: 1.5)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const _FarmProducts(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmHeader extends StatelessWidget {
  const _FarmHeader({required this.farm, required this.onEdit});

  final Farm farm;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1F3A29), AppColors.darkCard]
              : const [AppColors.forest, AppColors.green],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.agriculture_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farm.nome,
                    style: context.text.titleLarge?.copyWith(color: Colors.white)),
                if (farm.location != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Flexible(child: Text(farm.location!, style: const TextStyle(color: Colors.white70))),
                  ]),
                ],
                if (farm.endereco != null)
                  Text(farm.endereco!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                if (farm.inscricaoEstadual != null)
                  Text('IE: ${farm.inscricaoEstadual}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar informações',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: context.text.bodySmall),
      ]);
}

/// Produtos da propriedade e indicadores calculados a partir deles.
class _FarmProducts extends StatelessWidget {
  const _FarmProducts();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'Produção anunciada'),
        InlineAsync<List<Product>>(
          load: () => context.read<ProductRepository>().list(const ProductQuery(somenteMeus: true)),
          isEmpty: (d) => d.isEmpty,
          emptyMessage: 'Nenhum produto cadastrado para esta propriedade.',
          builder: (context, products) {
            final byCategory = <ProductCategory, int>{};
            for (final p in products) {
              byCategory.update(p.categoria, (v) => v + 1, ifAbsent: () => 1);
            }
            final active = products.where((p) => p.disponivel).length;
            final stockValue = products.fold<double>(0, (s, p) => s + p.preco * p.quantidade);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatGrid(children: [
                  StatCard(label: 'Produtos', value: '${products.length}', icon: Icons.inventory_2_outlined),
                  StatCard(
                    label: 'Ativos no catálogo',
                    value: '$active',
                    icon: Icons.storefront_outlined,
                    color: context.palette.success,
                  ),
                  StatCard(
                    label: 'Categorias',
                    value: '${byCategory.length}',
                    icon: Icons.category_outlined,
                    color: context.palette.earth,
                  ),
                  StatCard(
                    label: 'Valor em estoque',
                    value: Formatters.currency(stockValue),
                    icon: Icons.account_balance_wallet_outlined,
                    color: context.palette.info,
                  ),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in byCategory.entries)
                      Chip(avatar: Icon(e.key.icon, size: 16), label: Text('${e.key.label} (${e.value})')),
                  ],
                ),
                const SizedBox(height: 12),
                for (final p in products.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProductListTile(
                      product: p,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: p),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
