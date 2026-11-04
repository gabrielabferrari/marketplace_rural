import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';

/// Mensagens rápidas padronizadas.
abstract final class AppFeedback {
  // O SnackBar usa a superfície inversa (escura no tema claro e clara no
  // escuro), então os ícones usam tons invertidos para manter o contraste.
  static bool _dark(BuildContext c) => c.theme.brightness == Brightness.dark;

  static void success(BuildContext context, String message) => _show(context, message,
      Icons.check_circle_rounded, _dark(context) ? AppColors.green : const Color(0xFFA8DB8C));

  static void info(BuildContext context, String message) => _show(context, message,
      Icons.info_outline_rounded, _dark(context) ? AppColors.info : const Color(0xFFA9CCEB));

  static void error(BuildContext context, Object error) {
    final e = ApiException.from(error);
    final message = e.isPendingBackend
        ? 'Funcionalidade ainda não disponível no servidor.'
        : e.message;
    _show(context, message, Icons.error_outline_rounded,
        _dark(context) ? AppColors.danger : const Color(0xFFFFB4AB));
  }

  static void _show(BuildContext context, String message, IconData icon, Color color) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ));
  }

  /// Diálogo de confirmação. Retorna `true` quando o usuário confirma.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = context.colors;
        return AlertDialog(
          icon: icon == null
              ? null
              : Icon(icon, color: destructive ? scheme.error : scheme.primary),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      minimumSize: const Size(0, 44),
                    )
                  : FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
