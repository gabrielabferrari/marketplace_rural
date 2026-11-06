import 'json_utils.dart';

enum UserRole {
  produtor('produtor', 'Produtor'),
  comprador('comprador', 'Comprador');

  const UserRole(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static UserRole? tryParse(String? value) {
    for (final role in values) {
      if (role.apiValue == value?.toLowerCase().trim()) return role;
    }
    return null;
  }
}

/// Usuário autenticado.
///
/// Campos confirmados na tabela `usuarios`: id, nome, email, telefone, tipo.
/// [cidade] e [fotoUrl] só são exibidos quando a API os fornecer.
class AppUser {
  const AppUser({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    this.telefone = '',
    this.cidade,
    this.fotoUrl,
  });

  final String id;
  final String nome;
  final String email;
  final String telefone;
  final UserRole tipo;
  final String? cidade;
  final String? fotoUrl;

  bool get isProducer => tipo == UserRole.produtor;
  bool get isBuyer => tipo == UserRole.comprador;

  /// Aceita `tipo_acesso` (backend do site) e `tipo` (cache local).
  /// Contas `admin` não entram pelo app.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final role = UserRole.tryParse(
      Json.stringOrNull(json['tipo_acesso']) ?? Json.stringOrNull(json['tipo']),
    );
    if (role == null) {
      throw const FormatException('Tipo de conta inválido.');
    }
    return AppUser(
      id: Json.string(json['id']),
      nome: Json.string(json['nome']),
      email: Json.string(json['email']),
      telefone: Json.string(json['telefone']),
      tipo: role,
      cidade: Json.stringOrNull(json['cidade']),
      fotoUrl: Json.stringOrNull(json['foto']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'tipo': tipo.apiValue,
        if (cidade != null) 'cidade': cidade,
        if (fotoUrl != null) 'foto': fotoUrl,
      };

  AppUser copyWith({String? nome, String? telefone}) => AppUser(
        id: id,
        nome: nome ?? this.nome,
        email: email,
        tipo: tipo,
        telefone: telefone ?? this.telefone,
        cidade: cidade,
        fotoUrl: fotoUrl,
      );
}
