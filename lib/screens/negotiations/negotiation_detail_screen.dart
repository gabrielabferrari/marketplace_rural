import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/session_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/negotiation.dart';
import '../../models/user.dart';
import '../../repositories/negotiation_repository.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'negotiation_widgets.dart';

class NegotiationDetailScreen extends StatefulWidget {
  const NegotiationDetailScreen({super.key, required this.negotiationId});

  final String negotiationId;

  @override
  State<NegotiationDetailScreen> createState() => _NegotiationDetailScreenState();
}

class _NegotiationDetailScreenState extends State<NegotiationDetailScreen> {
  final _viewKey = GlobalKey<AsyncViewState<Negotiation>>();
  NegotiationAction? _busy;
  bool _ordering = false;

  Future<void> _respond(Negotiation n, NegotiationAction action) async {
    double? price;
    double? qty;
    String? message;

    if (action == NegotiationAction.contraproposta) {
      final result = await showModalBottomSheet<(double, double, String)>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _CounterSheet(negotiation: n),
      );
      if (result == null) return;
      (price, qty, message) = result;
    } else {
      final (title, body, label, destructive) = switch (action) {
        NegotiationAction.aceitar => (
            'Aceitar proposta?',
            'Você concorda com ${Formatters.currency(n.precoProposto)}/${n.unidade} '
                'para ${Formatters.quantity(n.quantidade)} ${n.unidade}.',
            'Aceitar',
            false
          ),
        NegotiationAction.recusar => ('Recusar proposta?', 'A negociação será encerrada.', 'Recusar', true),
        _ => ('Cancelar negociação?', 'Sua proposta será retirada.', 'Cancelar negociação', true),
      };
      final ok = await AppFeedback.confirm(context,
          title: title, message: body, confirmLabel: label, destructive: destructive);
      if (!ok) return;
    }
    if (!mounted) return;

    setState(() => _busy = action);
    try {
      await context.read<NegotiationRepository>().respond(
            n.id,
            action,
            precoProposto: price,
            quantidade: qty,
            mensagem: message,
          );
      if (!mounted) return;
      AppFeedback.success(context, switch (action) {
        NegotiationAction.aceitar => 'Proposta aceita.',
        NegotiationAction.recusar => 'Proposta recusada.',
        NegotiationAction.contraproposta => 'Contraproposta enviada.',
        NegotiationAction.cancelar => 'Negociação cancelada.',
      });
      await _viewKey.currentState?.reload();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _placeOrder(Negotiation n) async {
    setState(() => _ordering = true);
    try {
      final order = await context.read<OrderRepository>().create(
            produtoId: n.produtoId,
            quantidade: n.quantidade,
            negociacaoId: n.id,
          );
      if (!mounted) return;
      AppFeedback.success(context, 'Pedido criado com o valor negociado.');
      Navigator.pushReplacementNamed(context, AppRoutes.orderDetail, arguments: order.id);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Negociação')),
      body: AsyncView<Negotiation>(
        key: _viewKey,
        feature: 'Os detalhes da negociação',
        load: () => context.read<NegotiationRepository>().detail(widget.negotiationId),
        builder: (context, n, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              PageContainer(
                maxWidth: 760,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: n.produtoId),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              SizedBox(width: 64, height: 64, child: NetworkThumb(url: n.produtoImagem)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.produtoNome, style: context.text.titleMedium),
                                    Text('Com ${n.counterpartName(user.id)}',
                                        style: TextStyle(color: context.palette.muted)),
                                    const SizedBox(height: 6),
                                    NegotiationStatusBadge(status: n.status),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            InfoRow(label: 'Preço original', value: '${Formatters.currency(n.precoOriginal)}/${n.unidade}'),
                            InfoRow(label: 'Preço proposto', value: '${Formatters.currency(n.precoProposto)}/${n.unidade}'),
                            InfoRow(label: 'Quantidade', value: '${Formatters.quantity(n.quantidade)} ${n.unidade}'),
                            if (n.discountPercent.abs() >= 0.1)
                              InfoRow(
                                label: n.discountPercent > 0 ? 'Desconto' : 'Acréscimo',
                                value: '${n.discountPercent.abs().toStringAsFixed(1).replaceAll('.', ',')}%',
                              ),
                            const Divider(),
                            InfoRow(label: 'Total proposto', value: Formatters.currency(n.totalProposto), bold: true),
                            InfoRow(label: 'Iniciada em', value: Formatters.dateTime(n.criadoEm)),
                          ],
                        ),
                      ),
                    ),
                    if (n.propostas.isNotEmpty) ...[
                      SectionHeader(title: 'Histórico de propostas'),
                      for (final p in n.propostas) _ProposalBubble(proposal: p, mine: p.autorId == user.id, unit: n.unidade),
                    ],
                    const SizedBox(height: 16),
                    ..._actions(n, user),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _actions(Negotiation n, AppUser user) {
    final busy = _busy != null;
    if (n.canRespond(user.id)) {
      return [
        AppButton(
          label: 'Aceitar proposta',
          icon: Icons.check_rounded,
          loading: _busy == NegotiationAction.aceitar,
          onPressed: busy ? null : () => _respond(n, NegotiationAction.aceitar),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AppButton(
              label: 'Contraproposta',
              variant: AppButtonVariant.outlined,
              loading: _busy == NegotiationAction.contraproposta,
              onPressed: busy ? null : () => _respond(n, NegotiationAction.contraproposta),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(
              label: 'Recusar',
              variant: AppButtonVariant.outlined,
              loading: _busy == NegotiationAction.recusar,
              onPressed: busy ? null : () => _respond(n, NegotiationAction.recusar),
            ),
          ),
        ]),
      ];
    }
    if (n.canCancel(user.id)) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(Icons.hourglass_top_rounded, color: context.palette.info),
              const SizedBox(width: 10),
              Expanded(child: Text('Aguardando resposta de ${n.counterpartName(user.id)}.')),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Cancelar negociação',
          variant: AppButtonVariant.outlined,
          loading: _busy == NegotiationAction.cancelar,
          onPressed: busy ? null : () => _respond(n, NegotiationAction.cancelar),
        ),
      ];
    }
    if (n.status == NegotiationStatus.aceita && Permissions.can(user, Feature.placeOrder)) {
      return [
        AppButton(
          label: 'Fazer pedido com o valor negociado',
          icon: Icons.shopping_bag_outlined,
          loading: _ordering,
          onPressed: () => _placeOrder(n),
        ),
      ];
    }
    return const [];
  }
}

class _ProposalBubble extends StatelessWidget {
  const _ProposalBubble({required this.proposal, required this.mine, required this.unit});

  final NegotiationProposal proposal;
  final bool mine;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final bg = mine ? context.colors.primaryContainer : context.palette.softSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${mine ? 'Você' : 'Contraparte'} propôs ${Formatters.currency(proposal.preco)}/$unit '
                '• ${Formatters.quantity(proposal.quantidade)} $unit',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (proposal.mensagem != null) ...[
                const SizedBox(height: 4),
                Text(proposal.mensagem!),
              ],
              const SizedBox(height: 4),
              Text(Formatters.dateTime(proposal.data),
                  style: context.text.labelSmall?.copyWith(color: context.palette.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterSheet extends StatefulWidget {
  const _CounterSheet({required this.negotiation});

  final Negotiation negotiation;

  @override
  State<_CounterSheet> createState() => _CounterSheetState();
}

class _CounterSheetState extends State<_CounterSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _price = TextEditingController(text: Formatters.decimalInput(widget.negotiation.precoProposto));
  late final _qty = TextEditingController(text: Formatters.quantity(widget.negotiation.quantidade));
  final _message = TextEditingController();

  @override
  void dispose() {
    _price.dispose();
    _qty.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.negotiation;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Contraproposta', style: context.text.titleLarge),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Preço',
                      controller: _price,
                      prefixText: 'R\$ ',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.price,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Quantidade',
                      controller: _qty,
                      suffixText: n.unidade,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => Validators.quantity(v, allowZero: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Mensagem (opcional)', controller: _message, maxLines: 3, maxLength: 500),
              const SizedBox(height: 12),
              AppButton(
                label: 'Enviar contraproposta',
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(context, (
                    Validators.parseDecimal(_price.text)!,
                    Validators.parseDecimal(_qty.text)!,
                    _message.text,
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
