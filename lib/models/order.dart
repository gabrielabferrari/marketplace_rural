import 'package:flutter/material.dart';

import 'json_utils.dart';
import 'user.dart';

enum OrderStatus {
  recebido('recebido', 'Recebido', Icons.assignment_rounded),
  emPreparacao('em_preparacao', 'Em preparação', Icons.inventory_2_rounded),
  aCaminho('a_caminho', 'A caminho', Icons.local_shipping_rounded),
  concluido('concluido', 'Concluído', Icons.check_circle_rounded),
  cancelado('cancelado', 'Cancelado', Icons.cancel_rounded);

  const OrderStatus(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;

  /// Etapas exibidas na linha do tempo (cancelado é tratado à parte).
  static const flow = [recebido, emPreparacao, aCaminho, concluido];

  static OrderStatus parse(String? value) {
    final v = value?.toLowerCase().trim().replaceAll(' ', '_');
    for (final s in values) {
      if (s.apiValue == v || s.name.toLowerCase() == v) return s;
    }
    return recebido;
  }

  bool get isFinal => this == concluido || this == cancelado;
}

/// Regras de transição de status por tipo de conta.
///
/// O servidor deve aplicar as mesmas regras; o app apenas oferece as
/// ações permitidas.
abstract final class OrderRules {
  static List<OrderStatus> allowedTransitions(OrderStatus current, UserRole role) {
    switch (role) {
      // Espelha TRANSICOES_PEDIDO em server/api/lib/dominio.php. O banco não tem
      // a etapa "a caminho", então ela não é oferecida.
      case UserRole.produtor:
        return switch (current) {
          OrderStatus.recebido => [OrderStatus.emPreparacao, OrderStatus.cancelado],
          OrderStatus.emPreparacao => [OrderStatus.concluido, OrderStatus.cancelado],
          _ => const [],
        };
      case UserRole.comprador:
        return switch (current) {
          OrderStatus.recebido => [OrderStatus.cancelado],
          _ => const [],
        };
    }
  }

  static String actionLabel(OrderStatus target, UserRole role) => switch (target) {
        OrderStatus.emPreparacao => 'Iniciar preparação',
        OrderStatus.aCaminho => 'Marcar como enviado',
        OrderStatus.concluido =>
          role == UserRole.comprador ? 'Confirmar recebimento' : 'Marcar como entregue',
        OrderStatus.cancelado => 'Cancelar pedido',
        OrderStatus.recebido => 'Reabrir',
      };
}

class OrderItem {
  const OrderItem({
    required this.produtoId,
    required this.nome,
    required this.quantidade,
    required this.precoUnitario,
    this.unidade = 'un.',
    this.imagem,
  });

  final String produtoId;
  final String nome;
  final double quantidade;
  final double precoUnitario;
  final String unidade;
  final String? imagem;

  double get subtotal => quantidade * precoUnitario;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        produtoId: Json.string(json['produto_id']),
        nome: Json.string(json['nome'] ?? json['produto_nome']),
        quantidade: Json.number(json['quantidade']),
        precoUnitario: Json.number(json['preco_unitario']),
        unidade: Json.string(json['unidade'], 'un.'),
        imagem: Json.stringOrNull(json['imagem']),
      );
}

class OrderEvent {
  const OrderEvent({required this.status, this.data});

  final OrderStatus status;
  final DateTime? data;

  factory OrderEvent.fromJson(Map<String, dynamic> json) => OrderEvent(
        status: OrderStatus.parse(Json.stringOrNull(json['status'])),
        data: Json.date(json['data']),
      );
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.itens,
    this.compradorId,
    this.compradorNome,
    this.produtorId,
    this.produtorNome,
    this.total,
    this.taxaEntrega,
    this.enderecoEntrega,
    this.criadoEm,
    this.historico = const [],
  });

  final String id;
  final OrderStatus status;
  final List<OrderItem> itens;
  final String? compradorId;
  final String? compradorNome;
  final String? produtorId;
  final String? produtorNome;
  final double? total;
  final double? taxaEntrega;
  final String? enderecoEntrega;
  final DateTime? criadoEm;
  final List<OrderEvent> historico;

  double get itemsTotal => itens.fold(0, (sum, i) => sum + i.subtotal);
  double get grandTotal => total ?? itemsTotal + (taxaEntrega ?? 0);

  String get summary {
    if (itens.isEmpty) return 'Sem itens';
    if (itens.length == 1) return itens.first.nome;
    return '${itens.first.nome} e mais ${itens.length - 1}';
  }

  DateTime? dateOf(OrderStatus step) {
    for (final e in historico) {
      if (e.status == step) return e.data;
    }
    return step == OrderStatus.recebido ? criadoEm : null;
  }

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: Json.string(json['id']),
        status: OrderStatus.parse(Json.stringOrNull(json['status'])),
        itens: Json.list(json['itens']).map(OrderItem.fromJson).toList(),
        compradorId: Json.stringOrNull(json['comprador_id']),
        compradorNome: Json.stringOrNull(json['comprador_nome']),
        produtorId: Json.stringOrNull(json['produtor_id']),
        produtorNome: Json.stringOrNull(json['produtor_nome']),
        total: Json.numberOrNull(json['total']),
        taxaEntrega: Json.numberOrNull(json['taxa_entrega']),
        enderecoEntrega: Json.stringOrNull(json['endereco_entrega']),
        criadoEm: Json.date(json['criado_em']),
        historico: Json.list(json['historico']).map(OrderEvent.fromJson).toList(),
      );
}
