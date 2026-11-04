import 'package:flutter/material.dart';

import '../../core/routes/permissions.dart';
import '../../models/user.dart';

/// Seções principais acessadas pelo menu lateral.
enum AppSection {
  home(Icons.home_outlined, Icons.home_rounded),
  products(Icons.inventory_2_outlined, Icons.inventory_2_rounded),
  orders(Icons.receipt_long_outlined, Icons.receipt_long_rounded),
  negotiations(Icons.handshake_outlined, Icons.handshake_rounded),
  stock(Icons.warehouse_outlined, Icons.warehouse_rounded, Feature.manageStock),
  favorites(Icons.favorite_border_rounded, Icons.favorite_rounded),
  farm(Icons.agriculture_outlined, Icons.agriculture_rounded, Feature.manageFarm),
  settings(Icons.settings_outlined, Icons.settings_rounded);

  const AppSection(this.icon, this.selectedIcon, [this.feature]);

  final IconData icon;
  final IconData selectedIcon;

  /// Permissão exigida; `null` = disponível para qualquer conta.
  final Feature? feature;

  String labelFor(AppUser user) => switch (this) {
        AppSection.home => 'Início',
        AppSection.products => user.isProducer ? 'Meus produtos' : 'Produtos',
        AppSection.orders => 'Pedidos',
        AppSection.negotiations => 'Negociações',
        AppSection.stock => 'Estoque',
        AppSection.favorites => 'Favoritos',
        AppSection.farm => 'Gestão de fazenda',
        AppSection.settings => 'Configurações',
      };

  bool isAllowed(AppUser user) => feature == null || Permissions.can(user, feature!);

  static List<AppSection> visibleFor(AppUser user) =>
      values.where((s) => s.isAllowed(user)).toList();
}

/// Seção atual do shell. Bloqueia seções não permitidas para a conta.
class ShellController extends ChangeNotifier {
  AppSection _section = AppSection.home;

  AppSection get section => _section;

  /// Retorna `false` quando o usuário não tem acesso à seção.
  bool select(AppSection section, AppUser user) {
    if (!section.isAllowed(user)) return false;
    if (section != _section) {
      _section = section;
      notifyListeners();
    }
    return true;
  }
}
