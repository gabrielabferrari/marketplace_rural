import 'json_utils.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.titulo,
    required this.mensagem,
    this.lida = false,
    this.data,
    this.tipo,
    this.referenciaId,
  });

  final String id;
  final String titulo;
  final String mensagem;
  final bool lida;
  final DateTime? data;

  /// pedido | negociacao | produto | sistema
  final String? tipo;
  final String? referenciaId;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: Json.string(json['id']),
        titulo: Json.string(json['titulo']),
        mensagem: Json.string(json['mensagem']),
        lida: Json.boolean(json['lida']),
        data: Json.date(json['data']),
        tipo: Json.stringOrNull(json['tipo']),
        referenciaId: Json.stringOrNull(json['referencia_id']),
      );
}
