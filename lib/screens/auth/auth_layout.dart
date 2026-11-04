import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/brand.dart';

/// Layout das telas de autenticação: formulário centralizado no celular e
/// painel institucional ao lado em telas largas.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.showBack = false});

  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final form = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: child,
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: showBack
          ? AppBar(backgroundColor: Colors.transparent)
          : null,
      body: wide
          ? Row(
              children: [
                const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(flex: 6, child: form),
              ],
            )
          : form,
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forest, Color(0xFF2B6B37), AppColors.brown],
          stops: [0, 0.65, 1],
        ),
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandMark(size: 64),
          const SizedBox(height: 28),
          Text(
            AppConfig.appName,
            style: context.text.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Conectando quem produz a quem consome — direto do campo, sem intermediários.',
            style: context.text.titleMedium?.copyWith(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 36),
          for (final (icon, text) in const [
            (Icons.storefront_rounded, 'Venda sua produção com preço justo'),
            (Icons.handshake_rounded, 'Negocie diretamente com o produtor'),
            (Icons.local_shipping_rounded, 'Acompanhe cada etapa do pedido'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(children: [
                Icon(icon, color: AppColors.greenLight, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

/// Cabeçalho com marca + título das telas de autenticação.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle, this.centered = true});

  final String title;
  final String subtitle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const BrandMark(size: 56),
        const SizedBox(height: 20),
        Text(title,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: context.text.headlineMedium),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: context.text.bodyLarge?.copyWith(color: context.palette.muted),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

/// Mensagem de erro em destaque no topo de formulários.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: context.colors.onErrorContainer, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(message!,
                        style: TextStyle(color: context.colors.onErrorContainer)),
                  ),
                ],
              ),
            ),
    );
  }
}
