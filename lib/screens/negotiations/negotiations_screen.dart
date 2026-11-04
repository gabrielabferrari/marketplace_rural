import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/session_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/negotiation.dart';
import '../../models/user.dart';
import '../../repositories/negotiation_repository.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common.dart';
import '../../widgets/state_views.dart';
import 'negotiation_widgets.dart';

class NegotiationsScreen extends StatefulWidget {
  const NegotiationsScreen({super.key});

  @override
  State<NegotiationsScreen> createState() => _NegotiationsScreenState();
}

class _NegotiationsScreenState extends State<NegotiationsScreen> {
  final _listKey = GlobalKey<AsyncViewState<List<Negotiation>>>();
  bool _history = false;

  Future<void> _open(Negotiation n) async {
    await Navigator.pushNamed(context, AppRoutes.negotiationDetail, arguments: n.id);
    _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final repo = context.read<NegotiationRepository>();

    return Scaffold(
      floatingActionButton: user.isBuyer
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.catalog),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova negociação'),
            )
          : null,
      body: Column(
        children: [
          PageContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Icons.forum_outlined), label: Text('Em andamento')),
                    ButtonSegment(value: true, icon: Icon(Icons.history_rounded), label: Text('Histórico')),
                  ],
                  selected: {_history},
                  onSelectionChanged: (s) => setState(() => _history = s.first),
                ),
              ),
            ),
          ),
          Expanded(
            child: AsyncView<List<Negotiation>>(
              key: _listKey,
              feature: 'As negociações',
              load: () => repo.list(),
              builder: (context, all, reload) {
                final items = all
                    .where((n) => _history
                        ? n.status != NegotiationStatus.aberta
                        : n.status == NegotiationStatus.aberta)
                    .toList();
                return RefreshIndicator(
                  onRefresh: reload,
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 40),
                            EmptyView(
                              icon: Icons.handshake_outlined,
                              title: _history ? 'Sem histórico' : 'Nenhuma negociação em andamento',
                              message: _history
                                  ? 'Negociações aceitas, recusadas ou canceladas aparecerão aqui.'
                                  : user.isBuyer
                                      ? 'Abra um produto e toque em "Negociar preço" para enviar uma proposta ao produtor.'
                                      : 'Quando um comprador enviar uma proposta, ela aparecerá aqui.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(0, 4, 0, 96),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => PageContainer(
                            child: _NegotiationCard(
                              negotiation: items[i],
                              user: user,
                              onTap: () => _open(items[i]),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NegotiationCard extends StatelessWidget {
  const _NegotiationCard({required this.negotiation, required this.user, required this.onTap});

  final Negotiation negotiation;
  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = negotiation;
    final awaitingMe = n.canRespond(user.id);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(width: 60, height: 60, child: NetworkThumb(url: n.produtoImagem, iconSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(n.produtoNome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleSmall?.copyWith(fontSize: 15)),
                        ),
                        NegotiationStatusBadge(status: n.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Com ${n.counterpartName(user.id)}',
                        style: TextStyle(color: context.palette.muted)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${Formatters.currency(n.precoProposto)}/${n.unidade}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        if (n.precoOriginal != n.precoProposto)
                          Text(
                            Formatters.currency(n.precoOriginal),
                            style: TextStyle(
                              color: context.palette.muted,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                            ),
                          ),
                        const Spacer(),
                        if (awaitingMe)
                          StatusBadge(
                            label: 'Aguardando você',
                            color: context.palette.warning,
                            icon: Icons.notifications_active_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
