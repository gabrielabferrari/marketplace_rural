import 'dart:convert';
import 'package:http/http.dart' as http;

/// Camada preparada para o backend.
/// Quando o grupo criar a API PHP, basta configurar [baseUrl]
/// e implementar os endpoints sem alterar as telas.
class ApiService {
  static const String baseUrl = '';

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    if (baseUrl.isEmpty) {
      throw Exception('API ainda não configurada.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro HTTP ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    if (baseUrl.isEmpty) {
      throw Exception('API ainda não configurada.');
    }

    final response = await http.get(Uri.parse('$baseUrl$endpoint'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro HTTP ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}