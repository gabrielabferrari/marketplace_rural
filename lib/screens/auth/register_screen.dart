import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/session_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/user.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserRole? _role;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    if (_role == null) {
      setState(() => _error = 'Escolha se você é produtor ou comprador.');
      return;
    }
    if (!valid) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<SessionController>().register(
            nome: _name.text,
            email: _email.text,
            telefone: _phone.text,
            senha: _password.text,
            confirmarSenha: _confirm.text,
            tipo: _role!,
          );
      // A sessão autenticada substitui a tela inicial; fecha o cadastro.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      final error = ApiException.from(e);
      setState(() => _error = error.isPendingBackend
          ? 'O serviço de cadastro ainda não está publicado no servidor.'
          : error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: 'Criar sua conta',
              subtitle: 'Escolha como você deseja utilizar o Marketplace Rural',
              centered: false,
            ),
            Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    icon: Icons.eco_rounded,
                    title: 'Sou produtor',
                    subtitle: 'Quero vender meus produtos',
                    selected: _role == UserRole.produtor,
                    onTap: () => setState(() {
                      _role = UserRole.produtor;
                      _error = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RoleCard(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Sou comprador',
                    subtitle: 'Quero encontrar e comprar produtos',
                    selected: _role == UserRole.comprador,
                    onTap: () => setState(() {
                      _role = UserRole.comprador;
                      _error = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FormErrorBanner(message: _error),
            AppTextField(
              label: 'Nome completo',
              controller: _name,
              hint: 'Seu nome',
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: Validators.name,
            ),
            const SizedBox(height: 16),
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
              label: 'Telefone',
              controller: _phone,
              hint: '(19) 99999-9999',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [PhoneInputFormatter()],
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Senha',
              controller: _password,
              hint: 'Mínimo de 6 caracteres',
              icon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Confirmar senha',
              controller: _confirm,
              hint: 'Repita a senha',
              icon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.done,
              validator: Validators.confirmPassword(() => _password.text),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 28),
            AppButton(label: 'Criar minha conta', loading: _loading, onPressed: _submit),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Já tem uma conta?', style: TextStyle(color: context.palette.muted)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : context.palette.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, size: 36, color: scheme.primary),
                      if (selected)
                        Positioned(
                          right: -14,
                          top: -6,
                          child: Icon(Icons.check_circle_rounded, size: 18, color: scheme.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: context.text.titleSmall?.copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(color: context.palette.muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
