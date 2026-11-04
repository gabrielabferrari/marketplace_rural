import 'package:flutter/material.dart';

enum AppButtonVariant { filled, outlined, tonal, danger }

/// Botão padrão com estado de carregamento.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = AppButtonVariant.filled,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final AppButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final callback = loading ? null : onPressed;
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: variant == AppButtonVariant.filled ||
                        variant == AppButtonVariant.danger
                    ? scheme.onPrimary
                    : scheme.primary,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    final button = switch (variant) {
      AppButtonVariant.filled => FilledButton(onPressed: callback, child: content),
      AppButtonVariant.tonal => FilledButton.tonal(onPressed: callback, child: content),
      AppButtonVariant.outlined => OutlinedButton(onPressed: callback, child: content),
      AppButtonVariant.danger => FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: content,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
