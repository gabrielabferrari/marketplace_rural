import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import 'json_utils.dart';

/// Categorias de produto: as mesmas do banco (`anuncios.categoria`) e do site.
/// O `name` de cada item é o valor enviado e recebido do backend.
enum ProductCategory {
  graos('Grãos', Icons.grass_rounded),
  hortalicas('Hortaliças', Icons.eco_rounded),
  frutas('Frutas', Icons.apple_rounded),
  carnes('Carnes', Icons.set_meal_rounded),
  laticinios('Laticínios', Icons.water_drop_rounded),
  flores('Flores', Icons.local_florist_rounded);

  const ProductCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Valor usado quando o servidor envia uma categoria desconhecida.
  static const fallback = graos;

  static ProductCategory fromLabel(String? value) {
    final normalized = value?.toLowerCase().trim();
    for (final c in values) {
      if (c.label.toLowerCase() == normalized || c.name == normalized) return c;
    }
    return fallback;
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
    this.categoria = ProductCategory.fallback,
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

  /// Formato do backend do site (`produtos/listar.php`): `id, nome, categoria,
  /// preco, estoque, descricao, status, imagem, vendedor_id, vendedor_nome`.
  /// `disponivel` vem em favoritos; sem ele, usa-se `status == 'ativo'`.
  factory Product.fromJson(Map<String, dynamic> json) {
    final status = Json.stringOrNull(json['status']) ?? 'ativo';
    final imagem = Json.stringOrNull(json['imagem']);
    return Product(
      id: Json.string(json['id']),
      produtorId: Json.string(json['vendedor_id']),
      produtorNome: Json.stringOrNull(json['vendedor_nome']),
      nome: Json.string(json['nome']),
      descricao: Json.string(json['descricao']),
      categoria: ProductCategory.fromLabel(Json.stringOrNull(json['categoria'])),
      preco: Json.number(json['preco']),
      unidade: Json.string(json['unidade'], 'un.'),
      quantidade: Json.number(json['estoque']),
      disponivel: Json.boolean(json['disponivel'], status == 'ativo'),
      imagens: imagem == null ? const [] : [AppConfig.absoluteUrl(imagem)],
    );
  }

  /// Campos do formulário de `produtos/cadastrar.php` e `produtos/editar.php`.
  /// A foto é enviada à parte, como arquivo multipart.
  Map<String, String> toRequest() => {
        if (id.isNotEmpty) 'id': id,
        'nome': nome,
        'descricao': descricao,
        'categoria': categoria.name,
        'preco': preco.toStringAsFixed(2),
        'estoque': quantidade.round().toString(),
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
