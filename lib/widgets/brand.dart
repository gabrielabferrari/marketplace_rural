import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Marca do aplicativo: folha em um selo arredondado.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.green, AppColors.forest],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: isDark ? 0.4 : 0.25),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Icon(Icons.eco_rounded, color: Colors.white, size: size * 0.55),
    );
  }
}
