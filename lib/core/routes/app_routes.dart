import 'package:flutter/material.dart';

import '../../models/farm.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/farm/farm_form_screen.dart';
import '../../screens/home/notifications_screen.dart';
import '../../screens/negotiations/negotiation_detail_screen.dart';
import '../../screens/orders/order_detail_screen.dart';
import '../../screens/products/catalog_screen.dart';
import '../../screens/products/product_detail_screen.dart';
import '../../screens/products/product_form_screen.dart';
import '../../screens/settings/settings_pages.dart';
import '../../screens/shell/access_denied_screen.dart';
import 'permissions.dart';

/// Rotas nomeadas com verificação de autenticação e permissão.
abstract final class AppRoutes {
  static const register = '/cadastro';
  static const forgotPassword = '/recuperar-senha';
  static const catalog = '/produtos/catalogo';
  static const productDetail = '/produtos/detalhe';
  static const productForm = '/produtos/formulario';
  static const orderDetail = '/pedidos/detalhe';
  static const negotiationDetail = '/negociacoes/detalhe';
  static const notifications = '/notificacoes';
  static const farmForm = '/fazenda/formulario';
  static const editProfile = '/configuracoes/perfil';
  static const changePassword = '/configuracoes/senha';
  static const privacy = '/configuracoes/privacidade';
  static const help = '/configuracoes/ajuda';
  static const about = '/configuracoes/sobre';

  static final Map<String, _RouteSpec> _routes = {
    register: _RouteSpec((_) => const RegisterScreen(), requiresAuth: false),
    forgotPassword: _RouteSpec((_) => const ForgotPasswordScreen(), requiresAuth: false),
    catalog: _RouteSpec((args) => CatalogScreen(args: args is CatalogArgs ? args : const CatalogArgs())),
    productDetail: _RouteSpec((args) => ProductDetailScreen(
          initial: args is Product ? args : null,
          productId: args is Product ? args.id : args as String,
        )),
    productForm: _RouteSpec(
      (args) => ProductFormScreen(product: args is Product ? args : null),
      feature: Feature.manageProducts,
    ),
    orderDetail: _RouteSpec((args) => OrderDetailScreen(orderId: args as String)),
    negotiationDetail: _RouteSpec((args) => NegotiationDetailScreen(negotiationId: args as String)),
    notifications: _RouteSpec((_) => const NotificationsScreen()),
    farmForm: _RouteSpec(
      (args) => FarmFormScreen(farm: args is Farm ? args : null),
      feature: Feature.manageFarm,
    ),
    editProfile: _RouteSpec((_) => const EditProfileScreen()),
    changePassword: _RouteSpec((_) => const ChangePasswordScreen()),
    privacy: _RouteSpec((_) => const PrivacyScreen()),
    help: _RouteSpec((_) => const HelpScreen()),
    about: _RouteSpec((_) => const AboutScreen()),
  };

  static Route<dynamic>? generate(RouteSettings settings, AppUser? user) {
    final spec = _routes[settings.name];
    if (spec == null) return null;

    Widget page;
    if (spec.requiresAuth && user == null) {
      page = const AccessDeniedScreen(
        message: 'Entre na sua conta para acessar esta página.',
      );
    } else if (spec.feature != null && !Permissions.can(user, spec.feature!)) {
      page = const AccessDeniedScreen();
    } else {
      try {
        page = spec.builder(settings.arguments);
      } catch (_) {
        page = const AccessDeniedScreen(
          title: 'Página indisponível',
          message: 'Não foi possível abrir esta página.',
        );
      }
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

class _RouteSpec {
  const _RouteSpec(this.builder, {this.requiresAuth = true, this.feature});

  final Widget Function(Object? args) builder;
  final bool requiresAuth;
  final Feature? feature;
}
