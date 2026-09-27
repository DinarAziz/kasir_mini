import 'package:flutter/services.dart';

import '../services/format.dart';

/// Input angka saja, ditampilkan dengan titik ribuan (3500 -> 3.500).
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final capped = digits.length > 9 ? digits.substring(0, 9) : digits;
    final text = formatAngka(int.parse(capped));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
