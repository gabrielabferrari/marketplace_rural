import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/session_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common.dart';
import '../../widgets/order_widgets.dart';
import '../../widgets/state_views.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _listKey = GlobalKey<AsyncViewState<List<Order>>>();

  /// `null` = todos.
  OrderStatus? _filter;

  static const _filters = <(OrderStatus?, String)>[
    (null, 'Todos'),
    (OrderStatus.recebido, 'Recebidos'),
    (OrderStatus.emPreparacao, 'Em preparação'),
    (OrderStatus.aCaminho, 'A caminho'),
    (OrderStatus.concluido, 'Concluídos'),
    (OrderStatus.cancelado, 'Cancelados'),
  ];

  Future<void> _open(Order order) async {
    final changed = await Navigator.pushNamed(context, AppRoutes.orderDetail, arguments: order.id);
    if (changed == true) _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<OrderRepository>();
    final user = context.watch<SessionController>().user!;

    return Column(
      children: [
        PageContainer(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (status, label) in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _filter == status,
                        onSelected: (_) => setState(() => _filter = status),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: AsyncView<List<Order>>(
            key: _listKey,
            feature: 'Os pedidos',
            // A lista completa é carregada uma vez; o filtro é local para
            // trocar de aba sem nova requisição.
            load: () => repo.list(),
            builder: (context, all, reload) {
              final orders = _filter == null ? all : all.where((o) => o.status == _filter).toList();
              if (orders.isEmpty) {
                return RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 40),
                      EmptyView(
                        icon: Icons.receipt_long_outlined,
                        title: all.isEmpty ? 'Nenhum pedido ainda' : 'Nenhum pedido neste filtro',
                        message: all.isEmpty
                            ? (user.isProducer
                                ? 'Os pedidos feitos pelos compradores aparecerão aqui.'
                                : 'Quando você comprar um produto, poderá acompanhar a entrega aqui.')
                            : 'Selecione outro filtro para ver mais pedidos.',
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: reload,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => PageContainer(
                    child: _OrderCard(
                      order: orders[i],
                      counterpart: user.isProducer ? orders[i].compradorNome : orders[i].produtorNome,
                      counterpartLabel: user.isProducer ? 'Comprador' : 'Produtor',
                      onTap: () => _open(orders[i]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.counterpartLabel,
    this.counterpart,
  });

  final Order order;
  final VoidCallback onTap;
  final String counterpartLabel;
  final String? counterpart;

  @override
  Widget build(BuildContext context) {
    final cover = order.itens.isEmpty ? null : order.itens.first.imagem;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 56, height: 56, child: NetworkThumb(url: cover, iconSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pedido #${order.id}', style: context.text.titleSmall?.copyWith(fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(order.summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: context.palette.muted)),
                        if (counterpart != null)
                          Text('$counterpartLabel: $counterpart',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall?.copyWith(color: context.palette.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(Formatters.date(order.criadoEm), style: context.text.bodySmall),
                      const SizedBox(height: 6),
                      OrderStatusBadge(status: order.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OrderProgressBar(status: order.status),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('${order.itens.length} item(ns)', style: TextStyle(color: context.palette.muted)),
                  const Spacer(),
                  Text(Formatters.currency(order.grandTotal),
                      style: context.text.titleSmall?.copyWith(fontSize: 15)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
