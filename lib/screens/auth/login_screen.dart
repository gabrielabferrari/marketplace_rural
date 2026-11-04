import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/session_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
      await context
          .read<SessionController>()
          .login(_email.text, _password.text, remember: _remember);
    } catch (e) {
      if (!mounted) return;
      final error = ApiException.from(e);
      setState(() => _error = error.isPendingBackend
          ? 'O serviço de login ainda não está publicado no servidor.'
          : error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(
                title: 'Acesse sua conta',
                subtitle: 'Entre para continuar no Marketplace Rural',
              ),
              FormErrorBanner(message: _error),
              AppTextField(
                label: 'E-mail',
                controller: _email,
                hint: 'seu@email.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Senha',
                controller: _password,
                hint: 'Digite sua senha',
                icon: Icons.lock_outline_rounded,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (v) => (v == null || v.isEmpty) ? 'Informe sua senha.' : null,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _remember = !_remember),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _remember,
                            onChanged: (v) => setState(() => _remember = v ?? true),
                          ),
                          const Flexible(child: Text('Lembrar acesso')),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                    child: const Text('Esqueci minha senha'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Entrar na plataforma',
                icon: Icons.login_rounded,
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou', style: TextStyle(color: context.palette.muted)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 20),
              AppButton(
                label: 'Criar conta gratuita',
                variant: AppButtonVariant.outlined,
                onPressed: _loading
                    ? null
                    : () => Navigator.pushNamed(context, AppRoutes.register),
              ),
              const SizedBox(height: 28),
              Text(
                'Ao continuar você concorda com os Termos de Uso e a Política de Privacidade.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(color: context.palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
