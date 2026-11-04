import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_notification.dart';
import '../../repositories/notification_repository.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/state_views.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _viewKey = GlobalKey<AsyncViewState<List<AppNotification>>>();

  Future<void> _markAll() async {
    try {
      await context.read<NotificationRepository>().markAllRead();
      _viewKey.currentState?.reload();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    }
  }

  void _open(AppNotification n) {
    final id = n.referenciaId;
    if (id == null) return;
    switch (n.tipo) {
      case 'pedido':
        Navigator.pushNamed(context, AppRoutes.orderDetail, arguments: id);
      case 'negociacao':
        Navigator.pushNamed(context, AppRoutes.negotiationDetail, arguments: id);
      case 'produto':
        Navigator.pushNamed(context, AppRoutes.productDetail, arguments: id);
    }
  }

  IconData _icon(String? tipo) => switch (tipo) {
        'pedido' => Icons.receipt_long_outlined,
        'negociacao' => Icons.handshake_outlined,
        'produto' => Icons.inventory_2_outlined,
        _ => Icons.notifications_none_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            tooltip: 'Marcar todas como lidas',
            onPressed: _markAll,
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: AsyncView<List<AppNotification>>(
        key: _viewKey,
        feature: 'As notificações',
        load: () => context.read<NotificationRepository>().list(),
        isEmpty: (d) => d.isEmpty,
        empty: const EmptyView(
          icon: Icons.notifications_off_outlined,
          title: 'Nenhuma notificação',
          message: 'Avisos sobre pedidos e negociações aparecerão aqui.',
        ),
        builder: (context, items, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = items[i];
              return PageContainer(
                maxWidth: 760,
                child: Card(
                  color: n.lida ? null : context.palette.accentSoft,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    onTap: () => _open(n),
                    leading: CircleAvatar(
                      backgroundColor: context.colors.primaryContainer,
                      child: Icon(_icon(n.tipo), color: context.colors.primary),
                    ),
                    title: Text(n.titulo,
                        style: TextStyle(fontWeight: n.lida ? FontWeight.w500 : FontWeight.w700)),
                    subtitle: Text('${n.mensagem}\n${Formatters.dateTime(n.data)}'),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
