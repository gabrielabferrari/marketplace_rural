import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/preferences_controller.dart';
import '../../controllers/session_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/user.dart';
import '../../widgets/feedback.dart';
import '../farm/farm_screen.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../negotiations/negotiations_screen.dart';
import '../orders/orders_screen.dart';
import '../products/catalog_screen.dart';
import '../products/my_products_screen.dart';
import '../settings/settings_screen.dart';
import '../stock/stock_screen.dart';
import 'app_menu.dart';
import 'app_section.dart';

/// Estrutura principal após o login: menu lateral + conteúdo da seção.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShellController(),
      child: const _ShellView(),
    );
  }
}

class _ShellView extends StatefulWidget {
  const _ShellView();

  @override
  State<_ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<_ShellView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const _wideBreakpoint = 1000.0;

  void _select(AppSection section, AppUser user, {required bool fromDrawer}) {
    if (fromDrawer) Navigator.of(context).pop();
    final ok = context.read<ShellController>().select(section, user);
    if (!ok) {
      AppFeedback.info(context, 'Esta área não está disponível para sua conta.');
    }
  }

  Future<void> _logout({required bool fromDrawer}) async {
    if (fromDrawer) Navigator.of(context).pop();
    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente para acessar o aplicativo.',
      confirmLabel: 'Sair',
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !mounted) return;
    await context.read<SessionController>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<SessionController, AppUser?>((s) => s.user);
    if (user == null) return const SizedBox.shrink();
    final section = context.watch<ShellController>().section;
    final prefs = context.watch<PreferencesController>();
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(section), child: _sectionBody(section, user)),
    );

    final appBar = AppBar(
      automaticallyImplyLeading: !wide,
      title: Text(section.labelFor(user)),
      actions: [
        if (prefs.notificationsEnabled)
          IconButton(
            tooltip: 'Notificações',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        const SizedBox(width: 4),
      ],
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              width: prefs.menuCollapsed ? 84 : 288,
              decoration: BoxDecoration(
                color: Theme.of(context).drawerTheme.backgroundColor,
                border: Border(right: BorderSide(color: Theme.of(context).dividerTheme.color!)),
              ),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: prefs.menuCollapsed ? 84 : 288,
                  maxWidth: prefs.menuCollapsed ? 84 : 288,
                  child: AppMenu(
                    user: user,
                    current: section,
                    collapsed: prefs.menuCollapsed,
                    onToggleCollapse: prefs.toggleMenuCollapsed,
                    onSelect: (s) => _select(s, user, fromDrawer: false),
                    onLogout: () => _logout(fromDrawer: false),
                  ),
                ),
              ),
            ),
            Expanded(child: Scaffold(appBar: appBar, body: body)),
          ],
        ),
      );
    }

    return PopScope(
      canPop: section == AppSection.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.read<ShellController>().select(AppSection.home, user);
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: appBar,
        drawer: Drawer(
          width: 304,
          child: AppMenu(
            user: user,
            current: section,
            onClose: () => _scaffoldKey.currentState?.closeDrawer(),
            onSelect: (s) => _select(s, user, fromDrawer: true),
            onLogout: () => _logout(fromDrawer: true),
          ),
        ),
        body: body,
      ),
    );
  }

  Widget _sectionBody(AppSection section, AppUser user) {
    // Segunda barreira: mesmo que a seção seja selecionada por engano,
    // a tela restrita não é construída.
    if (!section.isAllowed(user)) return const HomeScreen();
    return switch (section) {
      AppSection.home => const HomeScreen(),
      AppSection.products =>
        user.isProducer ? const MyProductsScreen() : const CatalogView(),
      AppSection.orders => const OrdersScreen(),
      AppSection.negotiations => const NegotiationsScreen(),
      AppSection.stock => const StockScreen(),
      AppSection.favorites => const FavoritesScreen(),
      AppSection.farm => const FarmScreen(),
      AppSection.settings => const SettingsScreen(),
    };
  }
}
