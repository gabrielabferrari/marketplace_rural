import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: TextStyle(color: context.palette.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mensagem centralizada com ícone, usada em estados vazios e de erro.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconColor,
    this.footnote,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? iconColor;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? context.colors.primary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.text.titleMedium,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.palette.muted, height: 1.45),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 22),
                action!,
              ],
              if (footnote != null) ...[
                const SizedBox(height: 18),
                Text(
                  footnote!,
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall?.copyWith(
                    color: context.palette.muted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => MessageView(
        icon: icon,
        title: title,
        message: message,
        action: action,
        iconColor: context.palette.earth,
      );
}

/// Exibe um erro da API com a mensagem adequada ao tipo de falha.
///
/// Quando o endpoint ainda não existe no servidor, informa claramente
/// que a funcionalidade aguarda a API — sem simular dados.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.feature,
  });

  final Object error;
  final VoidCallback? onRetry;

  /// Nome da funcionalidade, usado na mensagem de API pendente.
  final String? feature;

  @override
  Widget build(BuildContext context) {
    final e = ApiException.from(error);
    final retry = onRetry == null
        ? null
        : OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          );

    if (e.isPendingBackend) {
      return MessageView(
        icon: Icons.construction_rounded,
        iconColor: context.palette.info,
        title: feature == null
            ? 'Funcionalidade aguardando o servidor'
            : '$feature aguardando o servidor',
        message:
            'A interface está pronta, mas o serviço correspondente ainda não foi '
            'disponibilizado na API. Assim que o endpoint for publicado, os dados '
            'aparecerão aqui automaticamente.',
        footnote: e.endpoint == null ? null : 'Endpoint: ${e.endpoint}',
        action: retry,
      );
    }

    return MessageView(
      icon: switch (e.type) {
        ApiErrorType.network => Icons.wifi_off_rounded,
        ApiErrorType.timeout => Icons.hourglass_empty_rounded,
        ApiErrorType.forbidden => Icons.lock_outline_rounded,
        ApiErrorType.unauthorized => Icons.lock_clock_outlined,
        ApiErrorType.notFound => Icons.search_off_rounded,
        _ => Icons.error_outline_rounded,
      },
      iconColor: context.palette.danger,
      title: switch (e.type) {
        ApiErrorType.network => 'Sem conexão com o servidor',
        ApiErrorType.timeout => 'Tempo de resposta esgotado',
        ApiErrorType.forbidden => 'Acesso não permitido',
        ApiErrorType.unauthorized => 'Sessão encerrada',
        ApiErrorType.notFound => 'Não encontrado',
        _ => 'Não foi possível carregar',
      },
      message: e.message,
      action: retry,
    );
  }
}
