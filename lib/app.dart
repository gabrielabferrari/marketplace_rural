import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'controllers/favorites_controller.dart';
import 'controllers/preferences_controller.dart';
import 'controllers/session_controller.dart';
import 'controllers/theme_controller.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/local_preferences.dart';
import 'repositories/auth_repository.dart';
import 'repositories/farm_repository.dart';
import 'repositories/favorite_repository.dart';
import 'repositories/negotiation_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/product_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/home_shell.dart';
import 'screens/shell/splash_screen.dart';
import 'widgets/feedback.dart';

class MarketplaceRuralApp extends StatefulWidget {
  const MarketplaceRuralApp({super.key, required this.prefs, this.apiClient});

  final LocalPreferences prefs;

  /// Permite injetar um cliente HTTP falso nos testes.
  final ApiClient? apiClient;

  @override
  State<MarketplaceRuralApp> createState() => _MarketplaceRuralAppState();
}

class _MarketplaceRuralAppState extends State<MarketplaceRuralApp> {
  // Dependências criadas uma única vez durante a vida do aplicativo.
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  late final AuthRepository _auth = AuthRepository(_api);
  late final SessionController _session =
      SessionController(api: _api, auth: _auth, prefs: widget.prefs)..restore();

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = _api;
    final prefs = widget.prefs;

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        Provider<LocalPreferences>.value(value: prefs),
        ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
        ChangeNotifierProvider(create: (_) => PreferencesController(prefs)),
        ChangeNotifierProvider<SessionController>.value(value: _session),
        Provider<AuthRepository>.value(value: _auth),
        Provider<ProductRepository>(
          create: (c) => ProductRepository(api, () => c.read<SessionController>().user),
        ),
        Provider<OrderRepository>(
          create: (c) => OrderRepository(api, () => c.read<SessionController>().user),
        ),
        Provider<NegotiationRepository>(
          create: (c) => NegotiationRepository(api, () => c.read<SessionController>().user),
        ),
        Provider<FarmRepository>(
          create: (c) => FarmRepository(api, () => c.read<SessionController>().user),
        ),
        Provider<NotificationRepository>(create: (_) => NotificationRepository(api)),
        ChangeNotifierProvider(create: (_) => FavoritesController(FavoriteRepository(api))),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final SessionController _session;
  SessionStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _session = context.read<SessionController>();
    _session.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final status = _session.status;
    if (status == _lastStatus) return;
    _lastStatus = status;
    final favorites = context.read<FavoritesController>();
    // Executado após o frame atual: alterar outro ChangeNotifier durante a
    // construção da árvore não é permitido.
    void afterFrame(VoidCallback action) =>
        WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? action() : null);

    if (status == SessionStatus.authenticated) {
      afterFrame(() => favorites.load(force: true));
    } else if (status == SessionStatus.unauthenticated) {
      afterFrame(favorites.reset);
      // Fecha qualquer tela aberta ao encerrar a sessão.
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      if (_session.consumeExpiredFlag()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _messengerKey.currentContext;
          if (ctx != null) AppFeedback.info(ctx, 'Sua sessão expirou. Entre novamente.');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final session = context.watch<SessionController>();

    final Widget home = switch (session.status) {
      SessionStatus.loading => const SplashScreen(),
      SessionStatus.unauthenticated => const LoginScreen(),
      SessionStatus.authenticated => HomeShell(key: ValueKey(session.user!.id)),
    };

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: theme.mode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: (settings) => AppRoutes.generate(settings, session.user),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: KeyedSubtree(key: ValueKey(session.status), child: home),
      ),
    );
  }
}
