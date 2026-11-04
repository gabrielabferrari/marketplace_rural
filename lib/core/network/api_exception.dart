enum ApiErrorType {
  /// Sem conexão ou servidor inalcançável.
  network,
  timeout,
  unauthorized,
  forbidden,

  /// O recurso solicitado não existe (ex.: produto removido).
  notFound,

  /// O endpoint ainda não foi implementado no servidor (501 ou 404 sem JSON).
  notImplemented,
  validation,
  conflict,
  server,
  invalidResponse,
}

/// Erro padronizado da camada de rede. A [message] é sempre segura para
/// exibição: nunca contém stack trace, SQL ou detalhes internos.
class ApiException implements Exception {
  const ApiException(
    this.type,
    this.message, {
    this.statusCode,
    this.endpoint,
  });

  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final String? endpoint;

  /// Funcionalidade aguardando implementação no servidor.
  bool get isPendingBackend => type == ApiErrorType.notImplemented;

  bool get isConnectivity =>
      type == ApiErrorType.network || type == ApiErrorType.timeout;

  static ApiException from(Object error) {
    if (error is ApiException) return error;
    return const ApiException(
      ApiErrorType.invalidResponse,
      'Ocorreu um erro inesperado. Tente novamente.',
    );
  }

  @override
  String toString() => message;
}
