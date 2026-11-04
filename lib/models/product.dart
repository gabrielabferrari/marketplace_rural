import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import 'json_utils.dart';

/// Categorias de produto exibidas no app (taxonomia de interface).
enum ProductCategory {
  graos('Grãos', Icons.grass_rounded),
  hortalicas('Hortaliças', Icons.eco_rounded),
  frutas('Frutas', Icons.apple_rounded),
  carnes('Carnes', Icons.set_meal_rounded),
  laticinios('Laticínios', Icons.water_drop_rounded),
  bebidas('Bebidas', Icons.local_drink_rounded),
  organicos('Orgânicos', Icons.spa_rounded),
  outros('Outros', Icons.more_horiz_rounded);

  const ProductCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static ProductCategory fromLabel(String? value) {
    final normalized = value?.toLowerCase().trim();
    for (final c in values) {
      if (c.label.toLowerCase() == normalized || c.name == normalized) return c;
    }
    return outros;
  }
}

/// Unidades de venda mais comuns.
const productUnits = ['kg', 'g', 'un.', 'dúzia', 'maço', 'caixa', 'saca', 'litro', 'bandeja'];

enum StockLevel { ok, low, out }

class Product {
  const Product({
    required this.id,
    required this.produtorId,
    required this.nome,
    required this.preco,
    required this.quantidade,
    this.produtorNome,
    this.descricao = '',
    this.categoria = ProductCategory.outros,
    this.unidade = 'un.',
    this.localizacao,
    this.disponivel = true,
    this.imagens = const [],
    this.estoqueMinimo,
    this.criadoEm,
    this.atualizadoEm,
  });

  final String id;
  final String produtorId;
  final String? produtorNome;
  final String nome;
  final String descricao;
  final ProductCategory categoria;
  final double preco;
  final String unidade;
  final double quantidade;
  final String? localizacao;
  final bool disponivel;
  final List<String> imagens;
  final double? estoqueMinimo;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  String? get coverImage => imagens.isEmpty ? null : imagens.first;

  double get lowStockThreshold =>
      estoqueMinimo ?? AppConfig.defaultLowStockThreshold.toDouble();

  StockLevel get stockLevel {
    if (quantidade <= 0) return StockLevel.out;
    if (quantidade <= lowStockThreshold) return StockLevel.low;
    return StockLevel.ok;
  }

  bool get canBePurchased => disponivel && quantidade > 0;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: Json.string(json['id']),
        produtorId: Json.string(json['produtor_id'] ?? json['usuario_id']),
        produtorNome: Json.stringOrNull(json['produtor_nome']),
        nome: Json.string(json['nome']),
        descricao: Json.string(json['descricao']),
        categoria: ProductCategory.fromLabel(Json.stringOrNull(json['categoria'])),
        preco: Json.number(json['preco']),
        unidade: Json.string(json['unidade'], 'un.'),
        quantidade: Json.number(json['quantidade']),
        localizacao: Json.stringOrNull(json['localizacao']),
        disponivel: Json.boolean(json['disponivel'], true),
        imagens: Json.strings(json['imagens']),
        estoqueMinimo: Json.numberOrNull(json['estoque_minimo']),
        criadoEm: Json.date(json['criado_em']),
        atualizadoEm: Json.date(json['atualizado_em']),
      );

  /// Corpo enviado para cadastro/edição.
  Map<String, dynamic> toRequest() => {
        if (id.isNotEmpty) 'id': id,
        'nome': nome,
        'descricao': descricao,
        'categoria': categoria.label,
        'preco': preco,
        'unidade': unidade,
        'quantidade': quantidade,
        'localizacao': localizacao,
        'disponivel': disponivel,
        'imagens': imagens,
      };

  Product copyWith({
    String? nome,
    String? descricao,
    ProductCategory? categoria,
    double? preco,
    String? unidade,
    double? quantidade,
    String? localizacao,
    bool? disponivel,
    List<String>? imagens,
  }) =>
      Product(
        id: id,
        produtorId: produtorId,
        produtorNome: produtorNome,
        nome: nome ?? this.nome,
        descricao: descricao ?? this.descricao,
        categoria: categoria ?? this.categoria,
        preco: preco ?? this.preco,
        unidade: unidade ?? this.unidade,
        quantidade: quantidade ?? this.quantidade,
        localizacao: localizacao ?? this.localizacao,
        disponivel: disponivel ?? this.disponivel,
        imagens: imagens ?? this.imagens,
        estoqueMinimo: estoqueMinimo,
        criadoEm: criadoEm,
        atualizadoEm: atualizadoEm,
      );
}

/// Registro do histórico de estoque (quando suportado pelo servidor).
class StockMovement {
  const StockMovement({
    required this.quantidadeAnterior,
    required this.quantidadeNova,
    this.motivo,
    this.data,
  });

  final double quantidadeAnterior;
  final double quantidadeNova;
  final String? motivo;
  final DateTime? data;

  double get delta => quantidadeNova - quantidadeAnterior;

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
        quantidadeAnterior: Json.number(json['quantidade_anterior']),
        quantidadeNova: Json.number(json['quantidade_nova']),
        motivo: Json.stringOrNull(json['motivo']),
        data: Json.date(json['data']),
      );
}
