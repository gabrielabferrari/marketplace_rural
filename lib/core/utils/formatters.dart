import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
  static final _decimal = NumberFormat.decimalPattern('pt_BR');
  static final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _dateTime = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');

  static String currency(num value) => _currency.format(value);

  static String quantity(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return _decimal.format(value);
  }

  static String date(DateTime? value) =>
      value == null ? '—' : _date.format(value.toLocal());

  static String dateTime(DateTime? value) =>
      value == null ? '—' : _dateTime.format(value.toLocal());

  static String decimalInput(num value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  static String greeting([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  static String firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

/// Máscara de telefone brasileiro: (19) 99999-9999 ou (19) 9999-9999.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final d = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      final splitAt = d.length > 10 ? 7 : 6;
      if (i == splitAt) buffer.write('-');
      buffer.write(d[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Permite apenas números e uma vírgula/ponto decimal.
final decimalInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
];
