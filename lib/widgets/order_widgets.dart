import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/order.dart';
import 'common.dart';

Color orderStatusColor(BuildContext context, OrderStatus status) => switch (status) {
      OrderStatus.recebido => context.palette.info,
      OrderStatus.emPreparacao => context.palette.warning,
      OrderStatus.aCaminho => context.palette.earth,
      OrderStatus.concluido => context.palette.success,
      OrderStatus.cancelado => context.palette.danger,
    };

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) =>
      StatusBadge(label: status.label, color: orderStatusColor(context, status));
}

/// Linha do tempo compacta (horizontal) usada nos cards de pedido.
class OrderProgressBar extends StatelessWidget {
  const OrderProgressBar({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelado) {
      return Row(children: [
        Icon(Icons.cancel_outlined, size: 18, color: context.palette.danger),
        const SizedBox(width: 6),
        Text('Pedido cancelado', style: TextStyle(color: context.palette.danger)),
      ]);
    }
    final current = OrderStatus.flow.indexOf(status);
    final active = context.colors.primary;
    return Row(
      children: [
        for (var i = 0; i < OrderStatus.flow.length; i++) ...[
          if (i > 0)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3,
                color: i <= current ? active : context.palette.border,
              ),
            ),
          Tooltip(
            message: OrderStatus.flow[i].label,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= current ? active : Colors.transparent,
                border: Border.all(
                  color: i <= current ? active : context.palette.border,
                  width: 2,
                ),
              ),
              child: Icon(
                OrderStatus.flow[i].icon,
                size: 14,
                color: i <= current ? context.colors.onPrimary : context.palette.muted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Linha do tempo detalhada (vertical) para a tela do pedido.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ...OrderStatus.flow,
      if (order.status == OrderStatus.cancelado) OrderStatus.cancelado,
    ];
    final cancelled = order.status == OrderStatus.cancelado;
    final currentIndex = cancelled
        ? _lastReachedBeforeCancel()
        : OrderStatus.flow.indexOf(order.status);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineTile(
            status: steps[i],
            done: steps[i] == OrderStatus.cancelado || i <= currentIndex,
            isLast: i == steps.length - 1,
            date: order.dateOf(steps[i]),
            muted: cancelled && steps[i] != OrderStatus.cancelado && i > currentIndex,
          ),
      ],
    );
  }

  int _lastReachedBeforeCancel() {
    var last = 0;
    for (var i = 0; i < OrderStatus.flow.length; i++) {
      if (order.dateOf(OrderStatus.flow[i]) != null) last = i;
    }
    return last;
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.status,
    required this.done,
    required this.isLast,
    required this.muted,
    this.date,
  });

  final OrderStatus status;
  final bool done;
  final bool isLast;
  final bool muted;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final color = status == OrderStatus.cancelado
        ? context.palette.danger
        : done
            ? context.colors.primary
            : context.palette.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? color : Colors.transparent,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done
                      ? Icon(
                          status == OrderStatus.cancelado ? Icons.close : Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: done ? color : context.palette.border)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: muted || !done ? context.palette.muted : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? Formatters.dateTime(date) : (done ? 'Concluído' : 'Aguardando'),
                    style: context.text.bodySmall?.copyWith(color: context.palette.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
