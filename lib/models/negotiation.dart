import 'json_utils.dart';

enum NegotiationStatus {
  aberta('aberta', 'Em andamento'),
  aceita('aceita', 'Aceita'),
  recusada('recusada', 'Recusada'),
  cancelada('cancelada', 'Cancelada');

  const NegotiationStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static NegotiationStatus parse(String? value) {
    for (final s in values) {
      if (s.apiValue == value?.toLowerCase().trim()) return s;
    }
    return aberta;
  }
}

enum NegotiationAction { aceitar, recusar, contraproposta, cancelar }

class NegotiationProposal {
  const NegotiationProposal({
    required this.autorId,
    required this.preco,
    required this.quantidade,
    this.mensagem,
    this.data,
  });

  final String autorId;
  final double preco;
  final double quantidade;
  final String? mensagem;
  final DateTime? data;

  factory NegotiationProposal.fromJson(Map<String, dynamic> json) =>
      NegotiationProposal(
        autorId: Json.string(json['autor_id']),
        preco: Json.number(json['preco']),
        quantidade: Json.number(json['quantidade']),
        mensagem: Json.stringOrNull(json['mensagem']),
        data: Json.date(json['data']),
      );
}

class Negotiation {
  const Negotiation({
    required this.id,
    required this.produtoId,
    required this.produtoNome,
    required this.compradorId,
    required this.produtorId,
    required this.status,
    required this.precoOriginal,
    required this.precoProposto,
    required this.quantidade,
    this.unidade = 'un.',
    this.compradorNome,
    this.produtorNome,
    this.produtoImagem,
    this.ultimaPropostaPor,
    this.criadoEm,
    this.atualizadoEm,
    this.propostas = const [],
  });

  final String id;
  final String produtoId;
  final String produtoNome;
  final String? produtoImagem;
  final String compradorId;
  final String? compradorNome;
  final String produtorId;
  final String? produtorNome;
  final NegotiationStatus status;
  final double precoOriginal;
  final double precoProposto;
  final double quantidade;
  final String unidade;
  final String? ultimaPropostaPor;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  final List<NegotiationProposal> propostas;

  double get totalProposto => precoProposto * quantidade;

  double get discountPercent => precoOriginal <= 0
      ? 0
      : ((precoOriginal - precoProposto) / precoOriginal) * 100;

  /// O usuário pode responder quando a última proposta não é dele.
  bool canRespond(String userId) =>
      status == NegotiationStatus.aberta && ultimaPropostaPor != userId;

  bool canCancel(String userId) =>
      status == NegotiationStatus.aberta && ultimaPropostaPor == userId;

  String counterpartName(String userId) => userId == compradorId
      ? (produtorNome ?? 'Produtor')
      : (compradorNome ?? 'Comprador');

  factory Negotiation.fromJson(Map<String, dynamic> json) => Negotiation(
        id: Json.string(json['id']),
        produtoId: Json.string(json['produto_id']),
        produtoNome: Json.string(json['produto_nome']),
        produtoImagem: Json.stringOrNull(json['produto_imagem']),
        compradorId: Json.string(json['comprador_id']),
        compradorNome: Json.stringOrNull(json['comprador_nome']),
        produtorId: Json.string(json['produtor_id']),
        produtorNome: Json.stringOrNull(json['produtor_nome']),
        status: NegotiationStatus.parse(Json.stringOrNull(json['status'])),
        precoOriginal: Json.number(json['preco_original']),
        precoProposto: Json.number(json['preco_proposto']),
        quantidade: Json.number(json['quantidade']),
        unidade: Json.string(json['unidade'], 'un.'),
        ultimaPropostaPor: Json.stringOrNull(json['ultima_proposta_por']),
        criadoEm: Json.date(json['criado_em']),
        atualizadoEm: Json.date(json['atualizado_em']),
        propostas:
            Json.list(json['propostas']).map(NegotiationProposal.fromJson).toList(),
      );
}
