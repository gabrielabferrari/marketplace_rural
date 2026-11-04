import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

/// Arquivo a ser enviado em uma requisição multipart.
class UploadFile {
  const UploadFile({
    required this.field,
    required this.bytes,
    required this.filename,
  });

  final String field;
  final Uint8List bytes;
  final String filename;
}

/// Cliente HTTP único do aplicativo.
///
/// Responsabilidades:
/// * montar URLs a partir de [AppConfig.apiBaseUrl];
/// * enviar o token Bearer da sessão;
/// * aplicar timeout;
/// * converter respostas em JSON e erros em [ApiException].
///
/// Contrato de resposta esperado da API PHP:
/// `{ "sucesso": true, "dados": ... }` ou
/// `{ "sucesso": false, "mensagem": "..." }`.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    this.timeout = AppConfig.requestTimeout,
  })  : _http = httpClient ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceAll(
          RegExp(r'/+$'),
          '',
        );

  final http.Client _http;
  final String _baseUrl;
  final Duration timeout;

  String? _token;

  /// Chamado quando o servidor rejeita o token (HTTP 401).
  VoidCallback? onUnauthorized;

  set token(String? value) => _token = value;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanQuery = <String, String>{};
    query?.forEach((key, value) {
      if (value == null) return;
      final text = value.toString();
      if (text.isNotEmpty) cleanQuery[key] = text;
    });
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_baseUrl/$normalized')
        .replace(queryParameters: cleanQuery.isEmpty ? null : cleanQuery);
  }

  Map<String, String> _headers({bool json = true}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json; charset=utf-8',
        if (hasToken) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(path, () => _http.get(_uri(path, query), headers: _headers()));

  Future<dynamic> post(String path, {Object? body}) => _send(
        path,
        () => _http.post(_uri(path),
            headers: _headers(), body: jsonEncode(body ?? const {})),
      );

  Future<dynamic> put(String path, {Object? body}) => _send(
        path,
        () => _http.put(_uri(path),
            headers: _headers(), body: jsonEncode(body ?? const {})),
      );

  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) =>
      _send(path, () => _http.delete(_uri(path, query), headers: _headers()));

  Future<dynamic> multipart(
    String path, {
    Map<String, String> fields = const {},
    List<UploadFile> files = const [],
  }) {
    return _send(path, () async {
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers(json: false))
        ..fields.addAll(fields);
      for (final file in files) {
        request.files.add(http.MultipartFile.fromBytes(
          file.field,
          file.bytes,
          filename: file.filename,
        ));
      }
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }, customTimeout: AppConfig.uploadTimeout);
  }

  Future<dynamic> _send(
    String path,
    Future<http.Response> Function() request, {
    Duration? customTimeout,
  }) async {
    http.Response response;
    try {
      response = await request().timeout(customTimeout ?? timeout);
    } on TimeoutException {
      throw ApiException(
        ApiErrorType.timeout,
        'O servidor demorou para responder. Verifique sua conexão e tente novamente.',
        endpoint: path,
      );
    } on http.ClientException {
      throw ApiException(
        ApiErrorType.network,
        'Não foi possível conectar ao servidor. Verifique sua internet.',
        endpoint: path,
      );
    } catch (error) {
      if (kDebugMode) debugPrint('[ApiClient] $path: $error');
      throw ApiException(
        ApiErrorType.network,
        'Não foi possível conectar ao servidor. Verifique sua internet.',
        endpoint: path,
      );
    }
    return _handle(path, response);
  }

  dynamic _handle(String path, http.Response response) {
    final status = response.statusCode;
    final decoded = _tryDecode(response);
    final isJson = decoded != null;
    final serverMessage = decoded is Map ? decoded['mensagem'] as String? : null;

    if (status >= 200 && status < 300) {
      if (!isJson) {
        if (response.body.trim().isEmpty) return null;
        throw ApiException(
          ApiErrorType.invalidResponse,
          'Resposta inválida do servidor.',
          statusCode: status,
          endpoint: path,
        );
      }
      if (decoded is Map && decoded['sucesso'] == false) {
        throw ApiException(
          ApiErrorType.validation,
          serverMessage ?? 'Não foi possível concluir a operação.',
          statusCode: status,
          endpoint: path,
        );
      }
      if (decoded is Map && decoded.containsKey('dados')) {
        return decoded['dados'];
      }
      return decoded;
    }

    switch (status) {
      case 400:
      case 422:
        throw ApiException(ApiErrorType.validation,
            serverMessage ?? 'Verifique os dados informados.',
            statusCode: status, endpoint: path);
      case 401:
        onUnauthorized?.call();
        throw ApiException(ApiErrorType.unauthorized,
            serverMessage ?? 'Sua sessão expirou. Entre novamente.',
            statusCode: status, endpoint: path);
      case 403:
        throw ApiException(ApiErrorType.forbidden,
            serverMessage ?? 'Você não tem permissão para esta ação.',
            statusCode: status, endpoint: path);
      case 404:
        // 404 sem corpo JSON = arquivo/endpoint inexistente no servidor.
        if (!isJson) {
          throw ApiException(ApiErrorType.notImplemented,
              'Este recurso ainda não está disponível no servidor.',
              statusCode: status, endpoint: path);
        }
        throw ApiException(ApiErrorType.notFound,
            serverMessage ?? 'Registro não encontrado.',
            statusCode: status, endpoint: path);
      case 405:
      case 501:
        throw ApiException(ApiErrorType.notImplemented,
            'Este recurso ainda não está disponível no servidor.',
            statusCode: status, endpoint: path);
      case 409:
        throw ApiException(ApiErrorType.conflict,
            serverMessage ?? 'Conflito com dados existentes.',
            statusCode: status, endpoint: path);
      default:
        // Mensagens de erro 5xx nunca são repassadas ao usuário.
        throw ApiException(ApiErrorType.server,
            'O servidor está indisponível no momento. Tente novamente em instantes.',
            statusCode: status, endpoint: path);
    }
  }

  dynamic _tryDecode(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    final body = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    if (body.isEmpty) return null;
    final looksJson = contentType.contains('json') ||
        body.startsWith('{') ||
        body.startsWith('[');
    if (!looksJson) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  void close() => _http.close();
}
