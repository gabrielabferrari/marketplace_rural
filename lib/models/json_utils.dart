/// Leitura tolerante de JSON vindo do PHP (onde números às vezes chegam
/// como string e campos opcionais podem vir `null`).
abstract final class Json {
  static String string(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString();
  }

  static String? stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double number(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
    return fallback;
  }

  static double? numberOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  static int integer(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool boolean(dynamic value, [bool fallback = false]) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return const ['1', 'true', 'sim', 's'].contains(value.toLowerCase());
    }
    return fallback;
  }

  static DateTime? date(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    // MySQL DATETIME: "2026-11-04 10:30:00"
    return DateTime.tryParse(text.contains('T') ? text : text.replaceFirst(' ', 'T'));
  }

  static List<Map<String, dynamic>> list(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (value is Map && value['itens'] is List) return list(value['itens']);
    return const [];
  }

  static List<String> strings(dynamic value) {
    if (value is List) {
      return value.where((e) => e != null).map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  static Map<String, dynamic> map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
