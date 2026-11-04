import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'auth_layout.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final message = await context.read<AuthRepository>().requestPasswordReset(_email.text);
      if (mounted) setState(() => _success = message);
    } catch (e) {
      if (!mounted) return;
      final error = ApiException.from(e);
      setState(() => _error = error.isPendingBackend
          ? 'A recuperação de senha depende de envio de e-mail pelo servidor, '
              'que ainda não foi configurado. Procure o suporte para redefinir sua senha.'
          : error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _success != null ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Recuperar senha',
            subtitle: 'Informe o e-mail da sua conta para receber as instruções de redefinição.',
          ),
          FormErrorBanner(message: _error),
          AppTextField(
            label: 'E-mail',
            controller: _email,
            hint: 'seu@email.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Enviar instruções', loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      children: [
        Icon(Icons.mark_email_read_outlined, size: 72, color: context.colors.primary),
        const SizedBox(height: 20),
        Text('Verifique seu e-mail', style: context.text.headlineSmall),
        const SizedBox(height: 10),
        Text(
          _success!,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.muted, height: 1.5),
        ),
        const SizedBox(height: 28),
        AppButton(label: 'Voltar ao login', onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
