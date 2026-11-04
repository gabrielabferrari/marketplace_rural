import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

/// Limita a largura do conteúdo em telas grandes e aplica o espaçamento padrão.
class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = 1080,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      );
}

/// Título de tela com subtítulo opcional e ação à direita.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: context.text.bodyMedium?.copyWith(color: context.palette.muted)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.titleMedium?.copyWith(fontSize: 17))),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Indicador numérico (dashboard, estoque, fazenda).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.colors.primary;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: context.text.headlineSmall
                        ?.copyWith(color: context.colors.onSurface, fontSize: 24)),
              ),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(color: context.palette.muted)),
              if (caption != null)
                Text(caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(color: accent)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grade responsiva de [StatCard]s.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 720 ? 4 : 2;
      const spacing = 12.0;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final c in children) SizedBox(width: width, child: c)],
      );
    });
  }
}

/// Selo colorido de status.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.imageUrl, this.radius = 22});

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
      onForegroundImageError: imageUrl == null ? null : (_, _) {},
      child: Text(
        Formatters.initials(name),
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }
}

/// Imagem remota com placeholder temático.
class NetworkThumb extends StatelessWidget {
  const NetworkThumb({
    super.key,
    required this.url,
    this.icon = Icons.eco_rounded,
    this.radius = 12,
    this.iconSize = 32,
  });

  final String? url;
  final IconData icon;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: context.palette.accentSoft,
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: context.colors.primary.withValues(alpha: 0.7)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? placeholder
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
            ),
    );
  }
}

/// Campo de busca arredondado.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.hint = 'O que você está procurando?',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      autofocus: autofocus,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        fillColor: context.palette.softSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: context.palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: context.palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: context.colors.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Grupo de opções (configurações, perfil).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(title.toUpperCase(),
              style: context.text.labelMedium?.copyWith(
                  color: context.palette.earth, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(indent: 56),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Linha de informação "rótulo: valor".
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.icon, this.bold = false});

  final String label;
  final String value;
  final IconData? icon;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: context.palette.muted),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(label, style: TextStyle(color: context.palette.muted)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
