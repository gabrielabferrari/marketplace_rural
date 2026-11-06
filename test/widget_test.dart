import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:marketplace_rural/app.dart';
import 'package:marketplace_rural/core/network/api_client.dart';
import 'package:marketplace_rural/core/utils/local_preferences.dart';
import 'package:marketplace_rural/screens/shell/app_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servidor falso no formato do backend do site: login abre a sessão
/// (cookie PHPSESSID) e `auth/sessao.php` devolve o usuário; o resto responde 501.
ApiClient fakeApi({String role = 'comprador'}) {
  return ApiClient(
    baseUrl: 'https://api.test',
    httpClient: MockClient((req) async {
      final path = req.url.path;
      if (path.endsWith('auth/login.php')) {
        return http.Response(
          jsonEncode({'sucesso': true, 'redirect': 'inicio.html'}),
          200,
          headers: {
            'content-type': 'application/json',
            'set-cookie': 'PHPSESSID=tok; path=/; HttpOnly',
          },
        );
      }
      if (path.endsWith('auth/sessao.php')) {
        return http.Response(
          jsonEncode({
            'sucesso': true,
            'usuario': {
              'id': 9,
              'nome': 'Usuária Teste',
              'email': 'teste@exemplo.com',
              'telefone': '(19) 99999-9999',
              'cidade': 'Arceburgo',
              'tipo_acesso': role,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path.endsWith('auth/cadastro.php')) {
        return http.Response(
          jsonEncode({'sucesso': true, 'mensagem': 'Cadastro realizado com sucesso!'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{"mensagem":"Não implementado"}', 501,
          headers: {'content-type': 'application/json'});
    }),
  );
}

Future<LocalPreferences> prefsWith([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return LocalPreferences.load();
}

Map<String, Object> loggedAs(String role) => {
      'session_cookie': 'PHPSESSID=tok',
      'session_user': jsonEncode({
        'id': '9',
        'nome': 'Usuária Teste',
        'email': 'teste@exemplo.com',
        'telefone': '(19) 99999-9999',
        'tipo': role,
      }),
    };

Future<void> pumpApp(WidgetTester tester, LocalPreferences prefs, ApiClient api) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MarketplaceRuralApp(prefs: prefs, apiClient: api));
  await tester.pumpAndSettle();
}

Future<void> openDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Abrir menu de navegação'));
  await tester.pumpAndSettle();
}

Future<void> initForTests() async {
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');
}

void main() {
  setUpAll(initForTests);

  testWidgets('sem sessão abre o login e valida campos', (tester) async {
    await pumpApp(tester, await prefsWith(), fakeApi());

    expect(find.text('Acesse sua conta'), findsOneWidget);
    await tester.tap(find.text('Entrar na plataforma'));
    await tester.pumpAndSettle();
    expect(find.text('O e-mail é obrigatório.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('login bem-sucedido abre o início e salva a sessão', (tester) async {
    final prefs = await prefsWith();
    await pumpApp(tester, prefs, fakeApi());

    await tester.enterText(find.byType(TextFormField).at(0), 'teste@exemplo.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'segredo1');
    await tester.tap(find.text('Entrar na plataforma'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Usuária'), findsWidgets);
    expect(prefs.sessionCookie, 'PHPSESSID=tok');
  });

  testWidgets('cadastro exige escolher o tipo de conta', (tester) async {
    await pumpApp(tester, await prefsWith(), fakeApi());
    await tester.tap(find.text('Criar conta gratuita'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Criar minha conta'));
    await tester.tap(find.text('Criar minha conta'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha se você é produtor ou comprador.'), findsOneWidget);
  });

  testWidgets('menu do produtor mostra Gestão de fazenda e Estoque', (tester) async {
    await pumpApp(tester, await prefsWith(loggedAs('produtor')), fakeApi(role: 'produtor'));
    await openDrawer(tester);

    expect(find.text('Gestão de fazenda'), findsOneWidget);
    expect(find.text('Estoque'), findsOneWidget);
    expect(find.text('Meus produtos'), findsOneWidget);
    expect(find.text('Conta Produtor'), findsOneWidget);
  });

  testWidgets('menu do comprador NÃO mostra Gestão de fazenda', (tester) async {
    await pumpApp(tester, await prefsWith(loggedAs('comprador')), fakeApi());
    await openDrawer(tester);

    expect(find.text('Gestão de fazenda'), findsNothing);
    expect(find.text('Estoque'), findsNothing);
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Conta Comprador'), findsOneWidget);
  });

  testWidgets('comprador não acessa rota de fazenda nem diretamente', (tester) async {
    await pumpApp(tester, await prefsWith(loggedAs('comprador')), fakeApi());
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pushNamed('/fazenda/formulario');
    await tester.pumpAndSettle();
    expect(find.text('Acesso restrito'), findsOneWidget);
  });

  testWidgets('endpoint ausente mostra aviso de servidor, sem dados falsos', (tester) async {
    await pumpApp(tester, await prefsWith(loggedAs('comprador')), fakeApi());
    await openDrawer(tester);
    await tester.tap(find.text('Pedidos'));
    await tester.pumpAndSettle();

    expect(find.text('Os pedidos aguardando o servidor'), findsOneWidget);
  });

  testWidgets('modo escuro é aplicado e salvo', (tester) async {
    final prefs = await prefsWith(loggedAs('comprador'));
    await pumpApp(tester, prefs, fakeApi());
    await openDrawer(tester);
    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aparência'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modo escuro'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(prefs.themeMode, 'dark');
  });

  for (final role in ['produtor', 'comprador']) {
    for (final (label, size) in const [('celular 360px', Size(360, 690)), ('desktop', Size(1280, 800))]) {
      testWidgets('todas as seções sem overflow — $role, $label', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final prefs = await prefsWith({...loggedAs(role), 'pref_region': 'Mococa - SP'});
        await tester.pumpWidget(MarketplaceRuralApp(prefs: prefs, apiClient: fakeApi(role: role)));
        await tester.pumpAndSettle();

        final sections = role == 'produtor'
            ? ['Meus produtos', 'Pedidos', 'Negociações', 'Estoque', 'Favoritos', 'Gestão de fazenda', 'Configurações', 'Início']
            : ['Produtos', 'Pedidos', 'Negociações', 'Favoritos', 'Configurações', 'Início'];
        final wide = size.width >= 1000;
        for (final s in sections) {
          if (!wide) await openDrawer(tester);
          await tester.tap(find.descendant(of: find.byType(AppMenu), matching: find.text(s)).first,
              warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'seção $s');
        }
        if (wide) {
          await tester.tap(find.byTooltip('Recolher menu'));
          await tester.pumpAndSettle();
          expect(find.byTooltip('Expandir menu'), findsOneWidget);
          expect(prefs.menuCollapsed, isTrue);
        }
      });
    }
  }

  testWidgets('sair encerra a sessão após confirmação', (tester) async {
    final prefs = await prefsWith(loggedAs('produtor'));
    await pumpApp(tester, prefs, fakeApi());
    await openDrawer(tester);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Acesse sua conta'), findsOneWidget);
    expect(prefs.sessionCookie, isNull);
  });
}
