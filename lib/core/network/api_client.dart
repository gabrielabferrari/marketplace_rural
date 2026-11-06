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
/// O backend do site autentica por sessão PHP: o login devolve o cookie
/// `PHPSESSID`, que o app guarda e reenvia em todas as requisições.
///
/// Formatos do backend (mesmos do site):
/// * entrada: campos de formulário (`application/x-www-form-urlencoded`) ou
///   multipart quando há arquivo;
/// * saída: JSON com `sucesso` e os dados no próprio objeto
///   (ex.: `{ "sucesso": true, "produtos": [...] }`); em erro,
///   `{ "sucesso": false, "mensagem": "..." }`.
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

  String? _sessionCookie;

  /// Chamado quando o servidor rejeita a sessão (HTTP 401).
  VoidCallback? onUnauthorized;

  /// Cookie de sessão no formato `PHPSESSID=valor`, ou `null` sem sessão.
  String? get sessionCookie => _sessionCookie;
  set sessionCookie(String? value) =>
      _sessionCookie = (value == null || value.isEmpty) ? null : value;
  bool get hasSession => _sessionCookie != null;

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

  Map<String, String> _headers() => {
        'Accept': 'application/json',
        'Cookie': ?_sessionCookie,
      };

  /// Converte o corpo em campos de formulário (`bool` vira 1/0; `null` é omitido).
  Map<String, String> _form(Map<String, Object?>? body) {
    final fields = <String, String>{};
    body?.forEach((key, value) {
      if (value == null) return;
      fields[key] = value is bool ? (value ? '1' : '0') : value.toString();
    });
    return fields;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(path, () => _http.get(_uri(path, query), headers: _headers()));

  Future<Map<String, dynamic>> post(String path, {Map<String, Object?>? body}) =>
      _send(path,
          () => _http.post(_uri(path), headers: _headers(), body: _form(body)));

  /// Envia campos e, opcionalmente, arquivos (multipart). Usado no cadastro e
  /// na edição de produto, com a foto.
  Future<Map<String, dynamic>> multipart(
    String path, {
    Map<String, String> fields = const {},
    List<UploadFile> files = const [],
  }) {
    return _send(path, () async {
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers())
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

  Future<Map<String, dynamic>> _send(
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
    _captureSession(response);
    return _handle(path, response);
  }

  /// Guarda o `PHPSESSID` quando o servidor o envia (login, logout ou expiração).
  void _captureSession(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null) return;
    final match = RegExp(r'PHPSESSID=([^;,\s]*)').firstMatch(raw);
    if (match == null) return;
    final value = match.group(1) ?? '';
    _sessionCookie = value.isEmpty ? null : 'PHPSESSID=$value';
  }

  Map<String, dynamic> _handle(String path, http.Response response) {
    final status = response.statusCode;
    final decoded = _tryDecode(response);
    final isJson = decoded != null;
    final serverMessage = decoded is Map ? decoded['mensagem'] as String? : null;

    if (status >= 200 && status < 300) {
      if (!isJson) {
        if (response.body.trim().isEmpty) return <String, dynamic>{};
        throw ApiException(
          ApiErrorType.invalidResponse,
          'Resposta inválida do servidor.',
          statusCode: status,
          endpoint: path,
        );
      }
      if (decoded is Map<String, dynamic>) {
        if (decoded['sucesso'] == false) {
          throw ApiException(
            ApiErrorType.validation,
            serverMessage ?? 'Não foi possível concluir a operação.',
            statusCode: status,
            endpoint: path,
          );
        }
        return decoded;
      }
      throw ApiException(
        ApiErrorType.invalidResponse,
        'Resposta inválida do servidor.',
        statusCode: status,
        endpoint: path,
      );
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
