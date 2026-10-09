import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool showFavorite;
  final bool favorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onAdd;

  const ProductCard({
    super.key,
    required this.product,
    this.showFavorite = true,
    this.favorite = false,
    this.onFavorite,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.agriculture,
                  size: 42, color: AppColors.green),
            ),
            const SizedBox(height: 12),
            Text(product.category,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            Text(product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Text('R\$ ${product.price.toStringAsFixed(2)} / ${product.unit}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.green)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('${product.stock} disponíveis',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                ),
                if (showFavorite)
                  IconButton(
                    onPressed: onFavorite,
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      color: favorite ? Colors.red : AppColors.green,
                    ),
                  ),
                if (onAdd != null)
                  IconButton(
                    onPressed: product.stock > 0 ? onAdd : null,
                    icon: const Icon(Icons.add_shopping_cart),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}