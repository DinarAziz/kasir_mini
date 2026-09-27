/// Jenis barcode yang diterima scanner kamera.
enum ScanKind { ean13, ean8, upcA, upcE, code128, code39 }

/// Memeriksa hasil baca kamera supaya salah baca tidak masuk keranjang.
///
/// EAN/UPC punya digit periksa: satu digit yang salah baca hampir pasti
/// membuat digit periksa tidak cocok, sehingga bacaan ditolak. Kelas ini
/// murni Dart agar mudah dites.
class BarcodeValidator {
  static const int maxLength = 48;

  /// True bila [code] adalah bacaan sah untuk jenis [kind].
  static bool isValid(String code, ScanKind kind) {
    switch (kind) {
      case ScanKind.ean13:
        return _digits(code, 13) && _checkDigitOk(code);
      case ScanKind.upcA:
        return _digits(code, 12) && _checkDigitOk(code);
      case ScanKind.ean8:
        return _digits(code, 8) && _checkDigitOk(code);
      case ScanKind.upcE:
        return _isValidUpcE(code);
      case ScanKind.code128:
      case ScanKind.code39:
        return _isPrintable(code);
    }
  }

  /// Kode lain yang menunjuk barang sama. Sebagian pemindai melaporkan UPC-A
  /// (12 digit) sebagai EAN-13 dengan awalan 0, dan sebaliknya.
  static List<String> variants(String code) {
    final c = code.trim();
    final result = <String>[c];
    if (RegExp(r'^\d{12}$').hasMatch(c)) result.add('0$c');
    if (RegExp(r'^0\d{12}$').hasMatch(c)) result.add(c.substring(1));
    return result;
  }

  static bool _digits(String code, int length) =>
      code.length == length && RegExp(r'^\d+$').hasMatch(code);

  static bool _isPrintable(String code) =>
      code.isNotEmpty &&
      code.length <= maxLength &&
      code.codeUnits.every((u) => u >= 0x21 && u <= 0x7E);

  /// Digit terakhir harus sama dengan hitungan bobot 3/1 dari kanan.
  static bool _checkDigitOk(String code) {
    var sum = 0;
    final body = code.length - 1;
    for (var i = 0; i < body; i++) {
      final digit = code.codeUnitAt(i) - 0x30;
      // Digit paling kanan sebelum digit periksa berbobot 3.
      final weight = (body - i).isOdd ? 3 : 1;
      sum += digit * weight;
    }
    final expected = (10 - sum % 10) % 10;
    return expected == code.codeUnitAt(body) - 0x30;
  }

  /// UPC-E 8 digit (sistem angka 0/1 + 6 digit + digit periksa) diperluas ke
  /// UPC-A 12 digit lalu diperiksa. Bentuk 6/7 digit tidak punya digit
  /// periksa sehingga ditolak.
  static bool _isValidUpcE(String code) {
    if (!_digits(code, 8)) return false;
    final system = code[0];
    if (system != '0' && system != '1') return false;
    final d = code.substring(1, 7);
    final String body;
    switch (d[5]) {
      case '0':
      case '1':
      case '2':
        body = '${d.substring(0, 2)}${d[5]}0000${d.substring(2, 5)}';
      case '3':
        body = '${d.substring(0, 3)}00000${d.substring(3, 5)}';
      case '4':
        body = '${d.substring(0, 4)}00000${d[4]}';
      default:
        body = '${d.substring(0, 5)}0000${d[5]}';
    }
    return _checkDigitOk('$system$body${code[7]}');
  }
}
