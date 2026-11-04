import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/state_views.dart';

/// Painel de controle de estoque do produtor.
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _viewKey = GlobalKey<AsyncViewState<List<Product>>>();
  String _query = '';
  ProductCategory? _category;

  /// `null` = todos; `ok` aqui significa "disponíveis".
  StockLevel? _level;

  Future<void> _update(Product p) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StockUpdateSheet(product: p),
    );
    if (updated == true) _viewKey.currentState?.reload();
  }

  void _history(Product p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scroll) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Histórico — ${p.nome}', style: context.text.titleLarge),
            ),
            Expanded(
              child: AsyncView<List<StockMovement>>(
                feature: 'O histórico de estoque',
                load: () => context.read<ProductRepository>().stockHistory(p.id),
                isEmpty: (d) => d.isEmpty,
                empty: const EmptyView(
                  icon: Icons.history_rounded,
                  title: 'Sem alterações registradas',
                ),
                builder: (context, items, _) => ListView.separated(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(indent: 56),
                  itemBuilder: (context, i) {
                    final m = items[i];
                    final up = m.delta >= 0;
                    return ListTile(
                      leading: Icon(
                        up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: up ? context.palette.success : context.palette.danger,
                      ),
                      title: Text(
                        '${Formatters.quantity(m.quantidadeAnterior)} → ${Formatters.quantity(m.quantidadeNova)} ${p.unidade}',
                      ),
                      subtitle: Text([Formatters.dateTime(m.data), ?m.motivo].join(' • ')),
                      trailing: Text(
                        '${up ? '+' : ''}${Formatters.quantity(m.delta)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: up ? context.palette.success : context.palette.danger,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProductRepository>();
    return AsyncView<List<Product>>(
      key: _viewKey,
      feature: 'O controle de estoque',
      load: () => repo.list(const ProductQuery(somenteMeus: true)),
      isEmpty: (d) => d.isEmpty,
      empty: EmptyView(
        icon: Icons.warehouse_outlined,
        title: 'Estoque vazio',
        message: 'Cadastre produtos para controlar o estoque por aqui.',
        action: FilledButton.icon(
          onPressed: () async {
            final saved = await Navigator.pushNamed(context, AppRoutes.productForm);
            if (saved == true) _viewKey.currentState?.reload();
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Cadastrar produto'),
        ),
      ),
      builder: (context, all, reload) {
        final total = all.length;
        final available = all.where((p) => p.stockLevel == StockLevel.ok).length;
        final low = all.where((p) => p.stockLevel == StockLevel.low).length;
        final out = all.where((p) => p.stockLevel == StockLevel.out).length;

        final q = _query.toLowerCase();
        final items = all.where((p) {
          if (q.isNotEmpty && !p.nome.toLowerCase().contains(q)) return false;
          if (_category != null && p.categoria != _category) return false;
          if (_level != null && p.stockLevel != _level) return false;
          return true;
        }).toList()
          // Itens que precisam de atenção primeiro.
          ..sort((a, b) => b.stockLevel.index.compareTo(a.stockLevel.index));

        Widget stat(String label, int value, IconData icon, Color color, StockLevel? level) => StatCard(
              label: label,
              value: '$value',
              icon: icon,
              color: color,
              caption: _level == level ? 'Filtro ativo' : null,
              onTap: () => setState(() => _level = level),
            );

        return RefreshIndicator(
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
                    StatGrid(children: [
                      stat('Total de produtos', total, Icons.inventory_2_outlined, context.colors.primary, null),
                      stat('Disponíveis', available, Icons.check_circle_outline_rounded, context.palette.success,
                          StockLevel.ok),
                      stat('Estoque baixo', low, Icons.warning_amber_rounded, context.palette.warning, StockLevel.low),
                      stat('Sem estoque', out, Icons.remove_shopping_cart_outlined, context.palette.danger,
                          StockLevel.out),
                    ]),
                    const SizedBox(height: 16),
                    SearchField(
                      hint: 'Pesquisar no estoque',
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                    const SizedBox(height: 12),
                    CategorySelector(selected: _category, onSelected: (c) => setState(() => _category = c)),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const EmptyView(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'Nenhum produto neste filtro',
                      ),
                    for (final p in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StockTile(
                          product: p,
                          onUpdate: () => _update(p),
                          onHistory: () => _history(p),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.product, required this.onUpdate, required this.onHistory});

  final Product product;
  final VoidCallback onUpdate;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final color = switch (p.stockLevel) {
      StockLevel.ok => context.palette.success,
      StockLevel.low => context.palette.warning,
      StockLevel.out => context.palette.danger,
    };
    final ratio = p.lowStockThreshold <= 0 ? 1.0 : (p.quantidade / (p.lowStockThreshold * 3)).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 6, 12),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(width: 48, height: 48, child: NetworkThumb(url: p.coverImage, icon: p.categoria.icon, iconSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(p.categoria.label, style: context.text.bodySmall?.copyWith(color: context.palette.muted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${Formatters.quantity(p.quantidade)} ${p.unidade}',
                        style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16)),
                    StockBadge(product: p),
                  ],
                ),
                PopupMenuButton<String>(
                  tooltip: 'Ações',
                  onSelected: (v) => v == 'atualizar' ? onUpdate() : onHistory(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'atualizar', child: Text('Atualizar quantidade')),
                    PopupMenuItem(value: 'historico', child: Text('Ver histórico')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: onUpdate,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Atualizar'),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockUpdateSheet extends StatefulWidget {
  const _StockUpdateSheet({required this.product});

  final Product product;

  @override
  State<_StockUpdateSheet> createState() => _StockUpdateSheetState();
}

class _StockUpdateSheetState extends State<_StockUpdateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _qty = TextEditingController(text: Formatters.quantity(widget.product.quantidade));
  final _reason = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _adjust(double delta) {
    final current = Validators.parseDecimal(_qty.text) ?? 0;
    final next = (current + delta).clamp(0, double.infinity);
    _qty.text = Formatters.quantity(next);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<ProductRepository>().updateStock(
            widget.product.id,
            Validators.parseDecimal(_qty.text)!,
            motivo: _reason.text,
          );
      if (!mounted) return;
      AppFeedback.success(context, 'Estoque atualizado.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Atualizar estoque', style: context.text.titleLarge),
              Text(p.nome, style: TextStyle(color: context.palette.muted)),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Remover 1',
                    onPressed: () => _adjust(-1),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      label: 'Nova quantidade',
                      controller: _qty,
                      suffixText: p.unidade,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: decimalInputFormatters,
                      validator: Validators.quantity,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: 'Adicionar 1',
                    onPressed: () => _adjust(1),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Motivo (opcional)',
                controller: _reason,
                hint: 'Ex.: Colheita, perda, ajuste de inventário',
                maxLength: 120,
              ),
              const SizedBox(height: 8),
              AppButton(label: 'Salvar quantidade', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
