import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/session_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'settings_screen.dart';

/// Estrutura comum das subpáginas de configurações.
class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          PageContainer(
            maxWidth: 720,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── PERFIL ─────────────────────────────

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _user = context.read<SessionController>().user!;
  late final _name = TextEditingController(text: _user.nome);
  late final _phone = TextEditingController(text: _user.telefone);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<SessionController>().updateProfile(nome: _name.text, telefone: _phone.text);
      if (!mounted) return;
      AppFeedback.success(context, 'Dados atualizados.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _SettingsPage(
        title: 'Dados pessoais',
        children: [
          const SizedBox(height: 8),
          Center(child: UserAvatar(name: _user.nome, imageUrl: _user.fotoUrl, radius: 40)),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Nome completo',
            controller: _name,
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            validator: Validators.name,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Telefone',
            controller: _phone,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            validator: Validators.phone,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'E-mail',
            controller: TextEditingController(text: _user.email),
            icon: Icons.mail_outline_rounded,
            enabled: false,
            helper: 'O e-mail identifica sua conta e não pode ser alterado pelo aplicativo.',
          ),
          const SizedBox(height: 16),
          InfoRow(icon: Icons.badge_outlined, label: 'Tipo de conta', value: _user.tipo.label),
          const SizedBox(height: 24),
          AppButton(label: 'Salvar alterações', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

// ───────────────────────────── SENHA ─────────────────────────────

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<SessionController>().changePassword(senhaAtual: _current.text, novaSenha: _new.text);
      if (!mounted) return;
      AppFeedback.success(context, 'Senha alterada com sucesso.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _SettingsPage(
        title: 'Alterar senha',
        children: [
          AppTextField(
            label: 'Senha atual',
            controller: _current,
            obscure: true,
            icon: Icons.lock_outline_rounded,
            validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha atual.' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Nova senha',
            controller: _new,
            obscure: true,
            icon: Icons.lock_reset_rounded,
            validator: (v) {
              final base = Validators.password(v);
              if (base != null) return base;
              if (v == _current.text) return 'A nova senha deve ser diferente da atual.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Confirmar nova senha',
            controller: _confirm,
            obscure: true,
            icon: Icons.lock_reset_rounded,
            validator: Validators.confirmPassword(() => _new.text),
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Alterar senha', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

// ───────────────────────────── PRIVACIDADE ─────────────────────────────

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String title, String body) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: context.colors.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.titleSmall),
                      const SizedBox(height: 4),
                      Text(body, style: TextStyle(color: context.palette.muted, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return _SettingsPage(
      title: 'Privacidade',
      children: [
        Text(
          'Como seus dados são tratados',
          style: context.text.titleLarge,
        ),
        const SizedBox(height: 12),
        item(Icons.storage_outlined, 'Dados da conta',
            'Nome, e-mail, telefone e tipo de conta ficam armazenados no servidor do Marketplace Rural e são usados para identificar você nas compras, vendas e negociações.'),
        const SizedBox(height: 10),
        item(Icons.key_outlined, 'Senha',
            'Sua senha é protegida com hash no servidor e nunca é armazenada neste dispositivo.'),
        const SizedBox(height: 10),
        item(Icons.phone_android_outlined, 'Neste dispositivo',
            'O aplicativo guarda apenas o cookie da sessão (quando você marca "Lembrar acesso") e suas preferências: tema, região e notificações.'),
        const SizedBox(height: 10),
        item(Icons.visibility_outlined, 'O que outros usuários veem',
            'Compradores veem o nome e a localização informados nos produtos. Produtores veem o nome do comprador nos pedidos e negociações.'),
        const SizedBox(height: 10),
        item(Icons.lock_outline_rounded, 'Comunicação segura',
            'Toda a comunicação com o servidor é feita por HTTPS com autenticação por sessão.'),
        const SizedBox(height: 16),
        Text(
          'Para solicitar a exclusão da sua conta ou dos seus dados, entre em contato com o suporte.',
          style: TextStyle(color: context.palette.muted),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => showSupportDialog(context),
          icon: const Icon(Icons.support_agent_rounded),
          label: const Text('Falar com o suporte'),
        ),
      ],
    );
  }
}

// ───────────────────────────── AJUDA ─────────────────────────────

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faq = <(String, String)>[
    ('Qual a diferença entre conta de produtor e comprador?',
        'Produtores anunciam produtos, controlam estoque, gerenciam a fazenda e atendem pedidos. '
            'Compradores exploram o catálogo, favoritam, negociam e fazem pedidos.'),
    ('Como cadastro um produto?',
        'Na conta de produtor, abra o menu > Meus produtos e toque em "Novo produto". Informe nome, '
            'categoria, preço, unidade, quantidade e localização.'),
    ('Como negociar um preço?',
        'Abra o produto e toque em "Negociar preço". O produtor pode aceitar, recusar ou enviar uma '
            'contraproposta. Com a proposta aceita, você pode fazer o pedido com o valor negociado.'),
    ('Como acompanho meu pedido?',
        'Acesse o menu > Pedidos e toque no pedido para ver a linha do tempo: recebido, em preparação, '
            'a caminho e concluído.'),
    ('Quem altera o status do pedido?',
        'O produtor avança o pedido (preparação, envio e entrega). O comprador pode cancelar enquanto o '
            'pedido não entrou em preparação e confirmar o recebimento quando estiver a caminho.'),
    ('O que significa "Estoque baixo"?',
        'O produto está com quantidade igual ou inferior a ${AppConfig.defaultLowStockThreshold} unidades '
            'de venda (ou ao mínimo definido para ele). Atualize o estoque em menu > Estoque.'),
    ('Por que aparece "aguardando o servidor"?',
        'Algumas funcionalidades dependem de serviços que ainda estão sendo publicados no servidor. '
            'A tela já está pronta e passará a exibir os dados assim que o serviço estiver disponível.'),
    ('Como mudo para o modo escuro?', 'Em Configurações > Aparência, escolha "Modo escuro".'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SettingsPage(
      title: 'Central de ajuda',
      children: [
        Text('Perguntas frequentes', style: context.text.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < _faq.length; i++) ...[
                if (i > 0) const Divider(),
                ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(_faq[i].$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(_faq[i].$2, style: TextStyle(color: context.palette.muted, height: 1.5))],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => showSupportDialog(context),
          icon: const Icon(Icons.support_agent_rounded),
          label: const Text('Ainda precisa de ajuda? Fale com o suporte'),
        ),
      ],
    );
  }
}

// ───────────────────────────── SOBRE ─────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsPage(
      title: 'Sobre o aplicativo',
      children: [
        const SizedBox(height: 16),
        const Center(child: BrandMark(size: 76)),
        const SizedBox(height: 16),
        Center(child: Text(AppConfig.appName, style: context.text.headlineSmall)),
        Center(
          child: Text('Versão ${AppConfig.appVersion}', style: TextStyle(color: context.palette.muted)),
        ),
        const SizedBox(height: 24),
        Text(
          'O Marketplace Rural conecta produtores rurais e compradores, facilitando a venda direta de '
          'produtos do campo, a negociação de preços e o acompanhamento de pedidos.',
          textAlign: TextAlign.center,
          style: context.text.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const InfoRow(icon: Icons.school_outlined, label: 'Projeto', value: 'TCC — SESI/SENAI'),
                const InfoRow(icon: Icons.phone_android_outlined, label: 'Aplicativo', value: 'Flutter / Dart'),
                const InfoRow(icon: Icons.dns_outlined, label: 'Servidor', value: 'API REST em PHP + MySQL'),
                InfoRow(icon: Icons.language_rounded, label: 'API', value: Uri.parse(AppConfig.apiBaseUrl).host),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: AppConfig.appName,
              applicationVersion: AppConfig.appVersion,
              applicationIcon: const Padding(padding: EdgeInsets.all(12), child: BrandMark(size: 48)),
            ),
            child: const Text('Licenças de código aberto'),
          ),
        ),
      ],
    );
  }
}
