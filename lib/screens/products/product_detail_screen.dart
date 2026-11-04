import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/session_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../repositories/negotiation_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/state_views.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId, this.initial});

  final String productId;

  /// Dados já conhecidos (da listagem) exibidos enquanto o detalhe carrega.
  final Product? initial;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product? _product = widget.initial;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await context.read<ProductRepository>().detail(widget.productId);
      if (mounted) setState(() => _product = p);
    } catch (e) {
      // Se já temos os dados da listagem, seguimos com eles.
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _loading ? const LoadingView() : ErrorView(error: _error!, onRetry: _load),
      );
    }
    final user = context.watch<SessionController>().user!;
    final isOwner = product.produtorId == user.id;
    final wide = MediaQuery.sizeOf(context).width >= 860;

    final gallery = _Gallery(product: product);
    final info = _ProductInfo(product: product, user: user, isOwner: isOwner);

    return Scaffold(
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(children: [
                    Positioned.fill(child: gallery),
                    _TopBar(product: product, isOwner: isOwner),
                  ]),
                ),
                Expanded(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: info,
                    ),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 320,
                  pinned: true,
                  stretch: true,
                  leading: const _CircleBack(),
                  actions: [
                    if (!isOwner) Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FavoriteButton(product: product, filled: true),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(background: gallery),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    transform: Matrix4.translationValues(0, -20, 0),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: info,
                  ),
                ),
              ],
            ),
    );
  }
}

class _CircleBack extends StatelessWidget {
  const _CircleBack();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: context.colors.surface.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          child: const BackButton(),
        ),
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.product, required this.isOwner});

  final Product product;
  final bool isOwner;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            const _CircleBack(),
            const Spacer(),
            if (!isOwner) FavoriteButton(product: product, filled: true),
          ]),
        ),
      );
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.product});

  final Product product;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.product.imagens;
    if (images.length <= 1) {
      return Hero(
        tag: 'product-${widget.product.id}',
        child: NetworkThumb(
          url: widget.product.coverImage,
          icon: widget.product.categoria.icon,
          radius: 0,
          iconSize: 72,
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => NetworkThumb(url: images[i], radius: 0, iconSize: 72),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < images.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: i == _page ? 1 : 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product, required this.user, required this.isOwner});

  final Product product;
  final AppUser user;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusBadge(
              label: product.categoria.label,
              color: context.palette.earth,
              icon: product.categoria.icon,
            ),
            const SizedBox(width: 8),
            StockBadge(product: product),
          ],
        ),
        const SizedBox(height: 12),
        Text(product.nome, style: context.text.headlineSmall),
        const SizedBox(height: 8),
        PriceText(price: product.preco, unit: product.unidade, size: 24),
        const SizedBox(height: 4),
        Text(
          '${Formatters.quantity(product.quantidade)} ${product.unidade} disponíveis',
          style: TextStyle(color: context.palette.muted),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 16),
        Text('Sobre o produto', style: context.text.titleMedium),
        const SizedBox(height: 8),
        Text(
          product.descricao.isEmpty ? 'O produtor não adicionou uma descrição.' : product.descricao,
          style: context.text.bodyMedium?.copyWith(
            height: 1.55,
            color: product.descricao.isEmpty ? context.palette.muted : null,
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 16),
        Text('Produtor', style: context.text.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            UserAvatar(name: product.produtorNome ?? 'Produtor', radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.produtorNome ?? 'Produtor',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  if (product.localizacao != null)
                    Row(children: [
                      Icon(Icons.location_on_outlined, size: 15, color: context.palette.muted),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(product.localizacao!,
                            style: TextStyle(color: context.palette.muted)),
                      ),
                    ]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isOwner)
          AppButton(
            label: 'Editar produto',
            icon: Icons.edit_outlined,
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.productForm, arguments: product),
          )
        else if (Permissions.can(user, Feature.placeOrder))
          _PurchasePanel(product: product)
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, color: context.palette.info),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Compras e negociações estão disponíveis para contas de comprador.'),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}

class _PurchasePanel extends StatefulWidget {
  const _PurchasePanel({required this.product});

  final Product product;

  @override
  State<_PurchasePanel> createState() => _PurchasePanelState();
}

class _PurchasePanelState extends State<_PurchasePanel> {
  double _qty = 1;
  bool _ordering = false;

  Product get p => widget.product;

  void _change(double delta) {
    setState(() => _qty = (_qty + delta).clamp(1, p.quantidade < 1 ? 1 : p.quantidade).toDouble());
  }

  Future<void> _order() async {
    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Confirmar pedido',
      message:
          '${Formatters.quantity(_qty)} ${p.unidade} de ${p.nome}\nTotal: ${Formatters.currency(_qty * p.preco)}',
      confirmLabel: 'Fazer pedido',
      icon: Icons.shopping_bag_outlined,
    );
    if (!confirmed || !mounted) return;
    setState(() => _ordering = true);
    try {
      final order = await context.read<OrderRepository>().create(produtoId: p.id, quantidade: _qty);
      if (!mounted) return;
      AppFeedback.success(context, 'Pedido realizado com sucesso!');
      Navigator.pushReplacementNamed(context, AppRoutes.orderDetail, arguments: order.id);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  Future<void> _negotiate() async {
    final created = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NegotiationSheet(product: p, initialQuantity: _qty),
    );
    if (created != null && mounted) {
      AppFeedback.success(context, 'Proposta enviada ao produtor.');
      Navigator.pushNamed(context, AppRoutes.negotiationDetail, arguments: created);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!p.canBePurchased) {
      return AppButton(label: 'Produto indisponível no momento', onPressed: null);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Quantidade', style: context.text.titleMedium),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.palette.softSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.palette.border),
          ),
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Diminuir',
                onPressed: _qty > 1 ? () => _change(-1) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  '${Formatters.quantity(_qty)} ${p.unidade}',
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium,
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Aumentar',
                onPressed: _qty < p.quantidade ? () => _change(1) : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InfoRow(label: 'Total estimado', value: Formatters.currency(_qty * p.preco), bold: true),
        const SizedBox(height: 16),
        AppButton(
          label: 'Fazer pedido',
          icon: Icons.shopping_bag_outlined,
          loading: _ordering,
          onPressed: _order,
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Negociar preço',
          icon: Icons.handshake_outlined,
          variant: AppButtonVariant.outlined,
          onPressed: _ordering ? null : _negotiate,
        ),
      ],
    );
  }
}

/// Formulário de proposta de negociação. Retorna o id da negociação criada.
class NegotiationSheet extends StatefulWidget {
  const NegotiationSheet({super.key, required this.product, this.initialQuantity = 1});

  final Product product;
  final double initialQuantity;

  @override
  State<NegotiationSheet> createState() => _NegotiationSheetState();
}

class _NegotiationSheetState extends State<NegotiationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _qty = TextEditingController(text: Formatters.quantity(widget.initialQuantity));
  late final _price = TextEditingController(text: Formatters.decimalInput(widget.product.preco));
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final n = await context.read<NegotiationRepository>().start(
            produtoId: widget.product.id,
            quantidade: Validators.parseDecimal(_qty.text)!,
            precoProposto: Validators.parseDecimal(_price.text)!,
            mensagem: _message.text,
          );
      if (mounted) Navigator.pop(context, n.id);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
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
              Text('Propor negociação', style: context.text.titleLarge),
              const SizedBox(height: 4),
              Text('${p.nome} • preço atual ${Formatters.currency(p.preco)}/${p.unidade}',
                  style: TextStyle(color: context.palette.muted)),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Quantidade',
                      controller: _qty,
                      suffixText: p.unidade,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final base = Validators.quantity(v, allowZero: false);
                        if (base != null) return base;
                        if (Validators.parseDecimal(v!)! > p.quantidade) {
                          return 'Máximo: ${Formatters.quantity(p.quantidade)}';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Preço proposto',
                      controller: _price,
                      prefixText: 'R\$ ',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.price,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Mensagem (opcional)',
                controller: _message,
                hint: 'Ex.: Compro semanalmente, posso retirar na propriedade.',
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 12),
              AppButton(label: 'Enviar proposta', loading: _sending, onPressed: _send),
            ],
          ),
        ),
      ),
    );
  }
}
