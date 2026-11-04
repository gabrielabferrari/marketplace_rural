import 'json_utils.dart';

/// Propriedade rural do produtor. Os campos numéricos são opcionais:
/// o app nunca preenche valores de produção por conta própria.
class Farm {
  const Farm({
    this.id,
    required this.nome,
    this.cidade,
    this.estado,
    this.endereco,
    this.areaTotalHa,
    this.areaProducaoHa,
    this.culturas = const [],
    this.descricao,
    this.inscricaoEstadual,
  });

  final String? id;
  final String nome;
  final String? cidade;
  final String? estado;
  final String? endereco;
  final double? areaTotalHa;
  final double? areaProducaoHa;
  final List<String> culturas;
  final String? descricao;
  final String? inscricaoEstadual;

  String? get location {
    final parts = [cidade, estado].whereType<String>().where((e) => e.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' - ');
  }

  double? get productionShare {
    if (areaTotalHa == null || areaProducaoHa == null || areaTotalHa == 0) {
      return null;
    }
    return (areaProducaoHa! / areaTotalHa!).clamp(0, 1).toDouble();
  }

  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
        id: Json.stringOrNull(json['id']),
        nome: Json.string(json['nome']),
        cidade: Json.stringOrNull(json['cidade']),
        estado: Json.stringOrNull(json['estado']),
        endereco: Json.stringOrNull(json['endereco']),
        areaTotalHa: Json.numberOrNull(json['area_total_ha']),
        areaProducaoHa: Json.numberOrNull(json['area_producao_ha']),
        culturas: Json.strings(json['culturas']),
        descricao: Json.stringOrNull(json['descricao']),
        inscricaoEstadual: Json.stringOrNull(json['inscricao_estadual']),
      );

  Map<String, dynamic> toRequest() => {
        if (id != null) 'id': id,
        'nome': nome,
        'cidade': cidade,
        'estado': estado,
        'endereco': endereco,
        'area_total_ha': areaTotalHa,
        'area_producao_ha': areaProducaoHa,
        'culturas': culturas,
        'descricao': descricao,
        'inscricao_estadual': inscricaoEstadual,
      };
}
