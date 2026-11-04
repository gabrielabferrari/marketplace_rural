/// Validadores de formulário. Retornam `null` quando o valor é válido.
///
/// As mesmas regras são aplicadas novamente no servidor; a validação do
/// app serve apenas para dar feedback imediato.
abstract final class Validators {
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final _phone = RegExp(r'^\(\d{2}\) \d{4,5}-\d{4}$');

  static String? required(String? value, [String field = 'Este campo']) {
    if (value == null || value.trim().isEmpty) return '$field é obrigatório.';
    return null;
  }

  static String? name(String? value) {
    final base = required(value, 'O nome');
    if (base != null) return base;
    if (value!.trim().length < 3) return 'Informe o nome completo.';
    return null;
  }

  static String? email(String? value) {
    final base = required(value, 'O e-mail');
    if (base != null) return base;
    if (!_email.hasMatch(value!.trim())) return 'Digite um e-mail válido.';
    return null;
  }

  static String? phone(String? value) {
    final base = required(value, 'O telefone');
    if (base != null) return base;
    if (!_phone.hasMatch(value!.trim())) {
      return 'Use o formato (19) 99999-9999.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'A senha é obrigatória.';
    if (value.length < 6) return 'A senha precisa ter pelo menos 6 caracteres.';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() other) {
    return (value) {
      if (value == null || value.isEmpty) return 'Confirme a senha.';
      if (value != other()) return 'As senhas não são iguais.';
      return null;
    };
  }

  static String? price(String? value) {
    final base = required(value, 'O preço');
    if (base != null) return base;
    final parsed = parseDecimal(value!);
    if (parsed == null) return 'Valor inválido.';
    if (parsed <= 0) return 'O preço deve ser maior que zero.';
    return null;
  }

  static String? positiveDecimal(String? value, [String field = 'O valor']) {
    final base = required(value, field);
    if (base != null) return base;
    final parsed = parseDecimal(value!);
    if (parsed == null) return 'Valor inválido.';
    if (parsed < 0) return '$field não pode ser negativo.';
    return null;
  }

  static String? quantity(String? value, {bool allowZero = true}) {
    final base = required(value, 'A quantidade');
    if (base != null) return base;
    final parsed = parseDecimal(value!);
    if (parsed == null) return 'Quantidade inválida.';
    if (parsed < 0 || (!allowZero && parsed == 0)) {
      return allowZero
          ? 'A quantidade não pode ser negativa.'
          : 'A quantidade deve ser maior que zero.';
    }
    return null;
  }

  /// Aceita "1.234,56", "1234,56" e "1234.56".
  static double? parseDecimal(String value) {
    var text = value.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (text.isEmpty) return null;
    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(text);
  }
}
