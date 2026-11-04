import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/preferences_controller.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final theme = context.watch<ThemeController>();
    final prefs = context.watch<PreferencesController>();

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        PageContainer(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _ProfileHeader(user: user),
              SettingsGroup(title: 'Conta', children: [
                _Tile(
                  icon: Icons.person_outline_rounded,
                  title: 'Dados pessoais',
                  subtitle: 'Nome, telefone e e-mail',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                _Tile(
                  icon: user.isProducer ? Icons.agriculture_outlined : Icons.shopping_basket_outlined,
                  title: 'Tipo de conta',
                  trailingText: user.tipo.label,
                  onTap: () => _showAccountType(context, user),
                ),
              ]),
              SettingsGroup(title: 'Preferências', children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Notificações'),
                  subtitle: Text(
                    prefs.notificationsEnabled ? 'Exibir alertas no aplicativo' : 'Alertas desativados',
                    style: TextStyle(color: context.palette.muted),
                  ),
                  value: prefs.notificationsEnabled,
                  onChanged: prefs.setNotifications,
                ),
                _Tile(
                  icon: theme.mode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  title: 'Aparência',
                  trailingText: theme.label,
                  onTap: () => _chooseTheme(context),
                ),
                _Tile(
                  icon: Icons.translate_rounded,
                  title: 'Idioma',
                  trailingText: PreferencesController.languages[prefs.language],
                  onTap: () => _chooseLanguage(context),
                ),
                _Tile(
                  icon: Icons.location_on_outlined,
                  title: 'Região',
                  trailingText: prefs.region.isEmpty ? 'Não definida' : prefs.region,
                  onTap: () => _chooseRegion(context),
                ),
              ]),
              SettingsGroup(title: 'Segurança', children: [
                _Tile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Alterar senha',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                ),
                _Tile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacidade',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
                ),
                _Tile(
                  icon: Icons.logout_rounded,
                  title: 'Encerrar sessão',
                  color: context.palette.danger,
                  onTap: () => _logout(context),
                ),
              ]),
              SettingsGroup(title: 'Ajuda', children: [
                _Tile(
                  icon: Icons.help_outline_rounded,
                  title: 'Central de ajuda',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.help),
                ),
                _Tile(
                  icon: Icons.support_agent_rounded,
                  title: 'Falar com o suporte',
                  onTap: () => showSupportDialog(context),
                ),
                _Tile(
                  icon: Icons.info_outline_rounded,
                  title: 'Sobre o aplicativo',
                  trailingText: 'v${AppConfig.appVersion}',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                ),
              ]),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.palette.danger,
                  side: BorderSide(color: context.palette.danger.withValues(alpha: 0.5)),
                  backgroundColor: context.palette.danger.withValues(alpha: 0.06),
                ),
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sair da conta'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await AppFeedback.confirm(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente para acessar o aplicativo.',
      confirmLabel: 'Sair',
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (ok && context.mounted) await context.read<SessionController>().logout();
  }

  void _showAccountType(BuildContext context, AppUser user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(user.isProducer ? Icons.agriculture_rounded : Icons.shopping_basket_rounded),
        title: Text('Conta ${user.tipo.label}'),
        content: Text(
          user.isProducer
              ? 'Você pode anunciar produtos, controlar estoque, gerenciar sua fazenda, atender pedidos e responder negociações.'
              : 'Você pode explorar o catálogo, favoritar produtos, fazer pedidos e negociar preços com os produtores.'
                  '\n\nO tipo de conta é definido no cadastro. Para vender, crie uma conta de produtor com outro e-mail.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi'))],
      ),
    );
  }

  Future<void> _chooseTheme(BuildContext context) async {
    final theme = context.read<ThemeController>();
    final mode = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<ThemeMode>(
          groupValue: theme.mode,
          onChanged: (v) => Navigator.pop(context, v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Aparência', style: context.text.titleLarge),
              const SizedBox(height: 8),
              for (final (m, label, icon) in const [
                (ThemeMode.light, 'Modo claro', Icons.light_mode_outlined),
                (ThemeMode.dark, 'Modo escuro', Icons.dark_mode_outlined),
                (ThemeMode.system, 'Automático (sistema)', Icons.brightness_auto_outlined),
              ])
                RadioListTile<ThemeMode>(value: m, title: Text(label), secondary: Icon(icon)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (mode != null) await theme.setMode(mode);
  }

  void _chooseLanguage(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Idioma', style: context.text.titleLarge),
            const SizedBox(height: 8),
            for (final e in PreferencesController.languages.entries)
              ListTile(
                leading: const Icon(Icons.check_rounded),
                title: Text(e.value),
                onTap: () => Navigator.pop(context),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Text(
                'No momento o aplicativo está disponível apenas em português.',
                style: TextStyle(color: context.palette.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseRegion(BuildContext context) async {
    final prefs = context.read<PreferencesController>();
    final controller = TextEditingController(text: prefs.region);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Região'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Usada para mostrar produtos de produtores perto de você.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Ex.: Mococa - SP'),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await prefs.setRegion(value);
  }
}

/// Mostra o canal de suporte configurado (ou informa que ainda não existe).
void showSupportDialog(BuildContext context) {
  const email = AppConfig.supportEmail;
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.support_agent_rounded),
      title: const Text('Falar com o suporte'),
      content: Text(
        email.isEmpty
            ? 'O canal oficial de suporte ainda não foi configurado para esta versão. '
                'Consulte a Central de ajuda para as dúvidas mais comuns.'
            : 'Envie sua dúvida para:\n\n$email\n\nInforme o e-mail da sua conta e descreva o problema.',
      ),
      actions: [
        if (email.isEmpty)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.help);
            },
            child: const Text('Central de ajuda'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      ],
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.forest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: UserAvatar(name: user.nome, imageUrl: user.fotoUrl, radius: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleLarge?.copyWith(color: Colors.white)),
                Text(user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                StatusBadge(
                  label: 'Conta ${user.tipo.label}',
                  color: AppColors.greenLight,
                  icon: user.isProducer ? Icons.agriculture_rounded : Icons.shopping_basket_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailingText,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(color: context.palette.muted)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(trailingText!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.palette.muted, fontSize: 13)),
            ),
          Icon(Icons.chevron_right_rounded, color: context.palette.muted),
        ],
      ),
    );
  }
}
