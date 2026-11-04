import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/order_widgets.dart';

/// Detalhes do pedido com linha do tempo e ações permitidas ao perfil.
/// Retorna `true` ao fechar quando o status foi alterado.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _viewKey = GlobalKey<AsyncViewState<Order>>();
  bool _changed = false;
  OrderStatus? _updating;

  Future<void> _update(Order order, OrderStatus target, UserRole role) async {
    final cancelling = target == OrderStatus.cancelado;
    final ok = await AppFeedback.confirm(
      context,
      title: cancelling ? 'Cancelar pedido?' : OrderRules.actionLabel(target, role),
      message: cancelling
          ? 'O pedido #${order.id} será cancelado. Esta ação não pode ser desfeita.'
          : 'O status do pedido #${order.id} será alterado para "${target.label}".',
      confirmLabel: cancelling ? 'Cancelar pedido' : 'Confirmar',
      destructive: cancelling,
      icon: target.icon,
    );
    if (!ok || !mounted) return;
    setState(() => _updating = target);
    try {
      await context.read<OrderRepository>().updateStatus(order, target);
      if (!mounted) return;
      _changed = true;
      AppFeedback.success(context, 'Pedido atualizado para "${target.label}".');
      await _viewKey.currentState?.reload();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _updating = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Pedido #${widget.orderId}')),
        body: AsyncView<Order>(
          key: _viewKey,
          feature: 'Os detalhes do pedido',
          load: () => context.read<OrderRepository>().detail(widget.orderId),
          builder: (context, order, reload) {
            final actions = OrderRules.allowedTransitions(order.status, user.tipo);
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  PageContainer(
                    maxWidth: 760,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: OrderStatusBadge(status: order.status)),
                        const SizedBox(height: 6),
                        Center(
                          child: Text('Realizado em ${Formatters.dateTime(order.criadoEm)}',
                              style: context.text.bodySmall?.copyWith(color: context.palette.muted)),
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'Resumo do pedido',
                          child: Column(
                            children: [
                              for (final item in order.itens)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: NetworkThumb(url: item.imagem, iconSize: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            Text(
                                              '${Formatters.quantity(item.quantidade)} ${item.unidade} × '
                                              '${Formatters.currency(item.precoUnitario)}',
                                              style: TextStyle(color: context.palette.muted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(Formatters.currency(item.subtotal),
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              const Divider(),
                              const SizedBox(height: 6),
                              InfoRow(label: 'Subtotal', value: Formatters.currency(order.itemsTotal)),
                              if (order.taxaEntrega != null)
                                InfoRow(label: 'Taxa de entrega', value: Formatters.currency(order.taxaEntrega!)),
                              InfoRow(label: 'Total', value: Formatters.currency(order.grandTotal), bold: true),
                            ],
                          ),
                        ),
                        _Section(
                          title: 'Participantes',
                          child: Column(
                            children: [
                              InfoRow(
                                icon: Icons.shopping_basket_outlined,
                                label: 'Comprador',
                                value: order.compradorNome ?? '—',
                              ),
                              InfoRow(
                                icon: Icons.agriculture_outlined,
                                label: 'Produtor',
                                value: order.produtorNome ?? '—',
                              ),
                            ],
                          ),
                        ),
                        if (order.enderecoEntrega != null)
                          _Section(
                            title: 'Endereço de entrega',
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined, color: context.palette.earth),
                                const SizedBox(width: 10),
                                Expanded(child: Text(order.enderecoEntrega!, style: const TextStyle(height: 1.5))),
                              ],
                            ),
                          ),
                        _Section(title: 'Acompanhe o pedido', child: OrderTimeline(order: order)),
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          for (final target in actions)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppButton(
                                label: OrderRules.actionLabel(target, user.tipo),
                                icon: target.icon,
                                loading: _updating == target,
                                variant: target == OrderStatus.cancelado
                                    ? AppButtonVariant.outlined
                                    : AppButtonVariant.filled,
                                onPressed: _updating != null ? null : () => _update(order, target, user.tipo),
                              ),
                            ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleMedium),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
