import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/favorites_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/product.dart';
import 'common.dart';
import 'feedback.dart';

/// Botão de favorito sincronizado com o servidor.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.product, this.filled = false});

  final Product product;

  /// Fundo circular (para uso sobre imagens).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final active = favorites.isFavorite(product.id);
    final button = IconButton(
      tooltip: active ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        try {
          await favorites.toggle(product);
        } catch (e) {
          if (context.mounted) AppFeedback.error(context, e);
        }
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Icon(
          active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(active),
          color: active ? context.palette.danger : context.palette.muted,
        ),
      ),
    );
    if (!filled) return button;
    return Material(
      color: context.colors.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: button,
    );
  }
}

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (!product.disponivel) {
      return StatusBadge(label: 'Indisponível', color: context.palette.muted);
    }
    return switch (product.stockLevel) {
      StockLevel.out => StatusBadge(label: 'Sem estoque', color: context.palette.danger),
      StockLevel.low => StatusBadge(label: 'Estoque baixo', color: context.palette.warning),
      StockLevel.ok => StatusBadge(label: 'Disponível', color: context.palette.success),
    };
  }
}

class PriceText extends StatelessWidget {
  const PriceText({super.key, required this.price, required this.unit, this.size = 16});

  final double price;
  final String unit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: Formatters.currency(price),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: context.theme.brightness == Brightness.dark
                ? context.colors.primary
                : AppColors.forest,
          ),
        ),
        TextSpan(
          text: ' /$unit',
          style: TextStyle(fontSize: size * 0.78, color: context.palette.muted),
        ),
      ]),
    );
  }
}

/// Card vertical para vitrines (grade/carrossel).
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap, this.showFavorite = true});

  final Product product;
  final VoidCallback? onTap;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product-${product.id}',
                    child: NetworkThumb(
                      url: product.coverImage,
                      icon: product.categoria.icon,
                      radius: 0,
                    ),
                  ),
                  if (showFavorite)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: FavoriteButton(product: product, filled: true),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.categoria.label.toUpperCase(),
                      style: context.text.labelSmall?.copyWith(
                          color: context.palette.earth, letterSpacing: 0.6)),
                  const SizedBox(height: 2),
                  Text(product.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(fontSize: 15)),
                  if (product.localizacao != null || product.produtorNome != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        product.localizacao ?? product.produtorNome!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(color: context.palette.muted),
                      ),
                    ),
                  const SizedBox(height: 8),
                  PriceText(price: product.preco, unit: product.unidade, size: 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item horizontal para listas de gestão.
class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    this.onTap,
    this.trailing,
    this.subtitle,
  });

  final Product product;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: NetworkThumb(url: product.coverImage, icon: product.categoria.icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    PriceText(price: product.preco, unit: product.unidade, size: 14),
                    const SizedBox(height: 6),
                    subtitle ?? StockBadge(product: product),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Seletor horizontal de categorias.
class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key, required this.selected, required this.onSelected});

  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Todas'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final c in ProductCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(c.icon, size: 16),
                label: Text(c.label),
                selected: selected == c,
                onSelected: (_) => onSelected(selected == c ? null : c),
              ),
            ),
        ],
      ),
    );
  }
}

/// Grade responsiva de produtos.
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, required this.onTap});

  final List<Product> products;
  final void Function(Product) onTap;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(builder: (context, constraints) {
      final width = constraints.crossAxisExtent;
      final columns = width >= 1000 ? 4 : width >= 680 ? 3 : 2;
      // A altura do card cresce com o tamanho do texto do sistema (acessibilidade).
      final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 2.0);
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: (width / columns) * 0.75 + 128 + 130 * (textScale - 1),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => ProductCard(product: products[i], onTap: () => onTap(products[i])),
          childCount: products.length,
        ),
      );
    });
  }
}
