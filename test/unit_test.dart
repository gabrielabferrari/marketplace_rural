import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marketplace_rural/core/network/api_client.dart';
import 'package:marketplace_rural/core/network/api_exception.dart';
import 'package:marketplace_rural/core/routes/permissions.dart';
import 'package:marketplace_rural/core/utils/formatters.dart';
import 'package:marketplace_rural/core/utils/validators.dart';
import 'package:marketplace_rural/models/negotiation.dart';
import 'package:marketplace_rural/models/order.dart';
import 'package:marketplace_rural/models/product.dart';
import 'package:marketplace_rural/models/user.dart';
import 'package:marketplace_rural/repositories/order_repository.dart';
import 'package:marketplace_rural/repositories/product_repository.dart';

const producer = AppUser(id: '1', nome: 'Ana Produtora', email: 'a@x.com', tipo: UserRole.produtor);
const buyer = AppUser(id: '2', nome: 'Beto Comprador', email: 'b@x.com', tipo: UserRole.comprador);

ApiClient clientReturning(int status, Object? body, {String contentType = 'application/json'}) {
  return ApiClient(
    baseUrl: 'https://api.test',
    httpClient: MockClient((_) async => http.Response(
          body == null ? '' : (body is String ? body : jsonEncode(body)),
          status,
          headers: {'content-type': contentType},
        )),
  );
}

void main() {
  group('Validators', () {
    test('e-mail', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('invalido'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('telefone no formato aceito pelo servidor', () {
      expect(Validators.phone('(19) 99999-9999'), isNull);
      expect(Validators.phone('(19) 3333-4444'), isNull);
      expect(Validators.phone('19999999999'), isNotNull);
    });

    test('senha mínima de 6 caracteres', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('decimal em formato brasileiro', () {
      expect(Validators.parseDecimal('1.234,56'), 1234.56);
      expect(Validators.parseDecimal('8,5'), 8.5);
      expect(Validators.parseDecimal('8.5'), 8.5);
      expect(Validators.parseDecimal('abc'), isNull);
      expect(Validators.price('0'), isNotNull);
    });
  });

  group('Formatters', () {
    test('máscara de telefone', () {
      final f = PhoneInputFormatter();
      String fmt(String s) => f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: s)).text;
      expect(fmt('19999998888'), '(19) 99999-8888');
      expect(fmt('1933334444'), '(19) 3333-4444');
    });

    test('iniciais', () {
      expect(Formatters.initials('Maria da Silva'), 'MS');
      expect(Formatters.initials(''), '?');
    });
  });

  group('Modelos', () {
    test('Product lê o formato do backend do site (números como string)', () {
      final p = Product.fromJson({
        'id': 7,
        'vendedor_id': 3,
        'vendedor_nome': 'Davi',
        'nome': 'Tomate',
        'categoria': 'hortalicas',
        'preco': '8.90',
        'estoque': '4',
        'descricao': '',
        'status': 'ativo',
        'imagem': 'uploads/produtos/abc.jpg',
      });
      expect(p.id, '7');
      expect(p.produtorId, '3');
      expect(p.preco, 8.90);
      expect(p.categoria, ProductCategory.hortalicas);
      expect(p.stockLevel, StockLevel.low);
      expect(p.canBePurchased, isTrue);
      expect(p.coverImage, 'https://buzzcodex.com.br/uploads/produtos/abc.jpg');
    });

    test('categoria desconhecida cai na categoria padrão', () {
      final p = Product.fromJson({'id': 1, 'nome': 'X', 'categoria': 'bebidas', 'preco': 1});
      expect(p.categoria, ProductCategory.fallback);
    });

    test('AppUser rejeita tipo de conta inválido', () {
      expect(() => AppUser.fromJson({'id': 1, 'nome': 'x', 'email': 'x', 'tipo': 'admin'}),
          throwsFormatException);
    });

    test('Order calcula total e lê data MySQL', () {
      final o = Order.fromJson({
        'id': 10,
        'status': 'preparo',
        'data': '2026-03-11',
        'papel': 'vendedor',
        'contraparte': 'Davi',
        'total': '44.50',
        'itens': [
          {'nome': 'Tomate', 'quantidade': 5, 'preco_unitario': '8.90'},
        ],
      });
      expect(o.status, OrderStatus.emPreparacao);
      expect(o.compradorNome, 'Davi');
      expect(o.itemsTotal, closeTo(44.5, 0.001));
      expect(o.grandTotal, closeTo(44.5, 0.001));
      expect(o.criadoEm, DateTime(2026, 3, 11));
    });

    test('Negociação: quem pode responder', () {
      final n = Negotiation.fromJson({
        'id': 1,
        'produto_id': 1,
        'produto_nome': 'Café',
        'comprador_id': '2',
        'produtor_id': '1',
        'status': 'aberta',
        'preco_original': 30,
        'preco_proposto': 27,
        'quantidade': 10,
        'ultima_proposta_por': '2',
      });
      expect(n.canRespond(producer.id), isTrue);
      expect(n.canRespond(buyer.id), isFalse);
      expect(n.canCancel(buyer.id), isTrue);
      expect(n.discountPercent, closeTo(10, 0.001));
    });
  });

  group('Permissões', () {
    test('gestão de fazenda e estoque só para produtor', () {
      expect(Permissions.can(producer, Feature.manageFarm), isTrue);
      expect(Permissions.can(buyer, Feature.manageFarm), isFalse);
      expect(Permissions.can(buyer, Feature.manageStock), isFalse);
      expect(Permissions.can(null, Feature.manageFarm), isFalse);
    });

    test('pedido só por comprador', () {
      expect(Permissions.can(buyer, Feature.placeOrder), isTrue);
      expect(Permissions.can(producer, Feature.placeOrder), isFalse);
    });

    test('transições de status por perfil', () {
      expect(OrderRules.allowedTransitions(OrderStatus.recebido, UserRole.produtor),
          containsAll([OrderStatus.emPreparacao, OrderStatus.cancelado]));
      expect(OrderRules.allowedTransitions(OrderStatus.recebido, UserRole.comprador), [OrderStatus.cancelado]);
      expect(OrderRules.allowedTransitions(OrderStatus.emPreparacao, UserRole.comprador), isEmpty);
      expect(OrderRules.allowedTransitions(OrderStatus.concluido, UserRole.produtor), isEmpty);
    });

    test('repositório bloqueia operação de produtor feita por comprador sem chamar a API', () async {
      var called = false;
      final api = ApiClient(
        baseUrl: 'https://api.test',
        httpClient: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );
      final repo = ProductRepository(api, () => buyer);
      await expectLater(
        repo.delete('1'),
        throwsA(isA<ApiException>().having((e) => e.type, 'type', ApiErrorType.forbidden)),
      );
      expect(called, isFalse);
    });

    test('repositório bloqueia transição de pedido não permitida', () async {
      final repo = OrderRepository(clientReturning(200, {'sucesso': true}), () => buyer);
      const order = Order(id: '1', status: OrderStatus.emPreparacao, itens: []);
      await expectLater(repo.updateStatus(order, OrderStatus.aCaminho), throwsA(isA<ApiException>()));
    });
  });

  group('ApiClient', () {
    test('devolve o próprio objeto de sucesso (formato do backend do site)', () async {
      final data = await clientReturning(200, {'sucesso': true, 'produtos': [1, 2]}).get('x.php');
      expect(data['produtos'], [1, 2]);
    });

    test('sucesso=false vira erro de validação com a mensagem do servidor', () async {
      await expectLater(
        clientReturning(200, {'sucesso': false, 'mensagem': 'E-mail já cadastrado.'}).post('x.php'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'E-mail já cadastrado.')),
      );
    });

    test('501 e 404 sem JSON = funcionalidade pendente no servidor', () async {
      await expectLater(
        clientReturning(501, {'mensagem': 'Não implementado'}).get('produtos/listar.php'),
        throwsA(isA<ApiException>().having((e) => e.isPendingBackend, 'pending', isTrue)),
      );
      await expectLater(
        clientReturning(404, '<html>Not Found</html>', contentType: 'text/html').get('x.php'),
        throwsA(isA<ApiException>().having((e) => e.isPendingBackend, 'pending', isTrue)),
      );
    });

    test('404 com JSON = registro não encontrado', () async {
      await expectLater(
        clientReturning(404, {'sucesso': false, 'mensagem': 'Produto não encontrado.'}).get('x.php'),
        throwsA(isA<ApiException>().having((e) => e.type, 'type', ApiErrorType.notFound)),
      );
    });

    test('erro 500 não expõe detalhes internos', () async {
      await expectLater(
        clientReturning(500, {'mensagem': 'SQLSTATE[42S02] tabela xyz'}).get('x.php'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', isNot(contains('SQLSTATE')))),
      );
    });

    test('401 dispara encerramento de sessão', () async {
      final api = clientReturning(401, {'mensagem': 'Token inválido'});
      var fired = false;
      api.onUnauthorized = () => fired = true;
      await expectLater(api.get('x.php'), throwsA(isA<ApiException>()));
      expect(fired, isTrue);
    });

    test('envia o cookie de sessão do servidor', () async {
      String? cookie;
      final api = ApiClient(
        baseUrl: 'https://api.test/',
        httpClient: MockClient((req) async {
          cookie = req.headers['Cookie'];
          expect(req.url.toString(), 'https://api.test/auth/sessao.php');
          return http.Response('{"sucesso":true}', 200);
        }),
      )..sessionCookie = 'PHPSESSID=abc';
      await api.get('/auth/sessao.php');
      expect(cookie, 'PHPSESSID=abc');
    });

    test('guarda o PHPSESSID enviado pelo login', () async {
      final api = ApiClient(
        baseUrl: 'https://api.test',
        httpClient: MockClient((_) async => http.Response(
              '{"sucesso":true}',
              200,
              headers: {'set-cookie': 'PHPSESSID=xyz123; path=/; HttpOnly'},
            )),
      );
      await api.post('auth/login.php', body: {'email': 'a@a.com', 'senha': 'x'});
      expect(api.sessionCookie, 'PHPSESSID=xyz123');
    });

    test('envia campos como formulário, não JSON', () async {
      String? contentType;
      String? body;
      final api = ApiClient(
        baseUrl: 'https://api.test',
        httpClient: MockClient((req) async {
          contentType = req.headers['content-type'];
          body = req.body;
          return http.Response('{"sucesso":true}', 200);
        }),
      );
      await api.post('pedidos/criar.php', body: {'anuncio_id': 3, 'quantidade': 2, 'x': null});
      expect(contentType, contains('application/x-www-form-urlencoded'));
      expect(body, 'anuncio_id=3&quantidade=2');
    });
  });
}
