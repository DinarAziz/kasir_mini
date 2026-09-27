/// Mengumpulkan ketikan dari scanner barcode USB/Bluetooth (mode keyboard).
///
/// Scanner "mengetik" seluruh kode dengan sangat cepat lalu menekan Enter.
/// Bila jeda antar karakter lebih dari [maxGap], buffer dianggap ketikan
/// manusia dan dibuang. Kelas ini murni Dart (tanpa Flutter) agar mudah dites.
class BarcodeBuffer {
  BarcodeBuffer({this.maxGap = const Duration(milliseconds: 100)});

  final Duration maxGap;
  final StringBuffer _buffer = StringBuffer();
  DateTime? _lastChar;

  String get current => _buffer.toString();

  /// Menambah satu karakter yang diterima pada waktu [now].
  void addChar(String char, DateTime now) {
    _resetIfStale(now);
    _buffer.write(char);
    _lastChar = now;
  }

  /// Dipanggil saat Enter. Mengembalikan kode yang terkumpul, atau null bila
  /// kosong atau jeda terlalu lama. Buffer selalu kosong setelahnya.
  String? submit(DateTime now) {
    _resetIfStale(now);
    final code = _buffer.toString();
    clear();
    return code.isEmpty ? null : code;
  }

  void clear() {
    _buffer.clear();
    _lastChar = null;
  }

  void _resetIfStale(DateTime now) {
    final last = _lastChar;
    if (last != null && now.difference(last) > maxGap) {
      _buffer.clear();
    }
  }
}
