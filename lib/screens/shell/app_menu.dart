import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user.dart';
import '../../widgets/common.dart';
import 'app_section.dart';

/// Menu lateral. Usado como Drawer (celular) ou barra fixa recolhível
/// (tablet/desktop).
class AppMenu extends StatelessWidget {
  const AppMenu({
    super.key,
    required this.user,
    required this.current,
    required this.onSelect,
    required this.onLogout,
    this.collapsed = false,
    this.onToggleCollapse,
    this.onClose,
  });

  final AppUser user;
  final AppSection current;
  final ValueChanged<AppSection> onSelect;
  final VoidCallback onLogout;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final sections = AppSection.visibleFor(user);
    final main = sections.where((s) => s != AppSection.settings).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            user: user,
            collapsed: collapsed,
            onToggleCollapse: onToggleCollapse,
            onClose: onClose,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 12, vertical: 4),
              children: [
                for (final s in main)
                  _MenuItem(
                    icon: s == current ? s.selectedIcon : s.icon,
                    label: s.labelFor(user),
                    selected: s == current,
                    collapsed: collapsed,
                    onTap: () => onSelect(s),
                  ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 12, vertical: 8),
            child: Column(
              children: [
                _MenuItem(
                  icon: current == AppSection.settings
                      ? AppSection.settings.selectedIcon
                      : AppSection.settings.icon,
                  label: AppSection.settings.labelFor(user),
                  selected: current == AppSection.settings,
                  collapsed: collapsed,
                  onTap: () => onSelect(AppSection.settings),
                ),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Sair',
                  collapsed: collapsed,
                  color: context.palette.danger,
                  onTap: onLogout,
                ),
              ],
            ),
          ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 2),
              child: Text(
                '${AppConfig.appName} • v${AppConfig.appVersion}',
                textAlign: TextAlign.center,
                style: context.text.labelSmall?.copyWith(color: context.palette.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.collapsed,
    this.onToggleCollapse,
    this.onClose,
  });

  final AppUser user;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final toggle = onToggleCollapse != null
        ? IconButton(
            tooltip: collapsed ? 'Expandir menu' : 'Recolher menu',
            onPressed: onToggleCollapse,
            icon: Icon(collapsed
                ? Icons.keyboard_double_arrow_right_rounded
                : Icons.keyboard_double_arrow_left_rounded),
            color: Colors.white,
          )
        : IconButton(
            tooltip: 'Fechar menu',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: Colors.white,
          );

    if (collapsed) {
      return Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.forest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(children: [
          Tooltip(
            message: '${user.nome}\n${user.tipo.label}',
            child: UserAvatar(name: user.nome, imageUrl: user.fotoUrl, radius: 20),
          ),
          const SizedBox(height: 6),
          toggle,
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1F3A29), AppColors.darkCard]
              : const [AppColors.forest, AppColors.green],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: AppColors.greenLight, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppConfig.appName,
                  style: context.text.labelLarge?.copyWith(color: Colors.white70),
                ),
              ),
              toggle,
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: UserAvatar(name: user.nome, imageUrl: user.fotoUrl, radius: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium?.copyWith(color: Colors.white),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user.isProducer ? Icons.agriculture_rounded : Icons.shopping_basket_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Conta ${user.tipo.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.collapsed,
    this.selected = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool collapsed;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final fg = color ?? (selected ? scheme.onPrimaryContainer : scheme.onSurface);
    final item = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 14),
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: color ?? (selected ? scheme.primary : context.palette.muted)),
                if (!collapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return collapsed ? Tooltip(message: label, preferBelow: false, child: item) : item;
  }
}
