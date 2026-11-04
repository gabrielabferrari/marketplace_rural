import 'package:flutter/material.dart';

import '../../widgets/state_views.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({
    super.key,
    this.title = 'Acesso restrito',
    this.message = 'Esta área não está disponível para o seu tipo de conta.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: MessageView(
        icon: Icons.lock_outline_rounded,
        title: title,
        message: message,
        action: OutlinedButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Voltar'),
        ),
      ),
    );
  }
}
