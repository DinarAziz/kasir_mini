/// Mengabaikan kode yang sama bila terbaca lagi dalam [window].
///
/// Jeda dihitung dari terakhir kali kode itu terlihat, jadi kamera yang terus
/// mengarah ke barcode yang sama tidak menambah barang berulang kali.
class ScanDebouncer {
  ScanDebouncer({this.window = const Duration(milliseconds: 1500)});

  final Duration window;
  String? _lastCode;
  DateTime? _lastSeen;

  /// True bila [code] harus diproses.
  bool accept(String code, DateTime now) {
    final repeated =
        code == _lastCode &&
        _lastSeen != null &&
        now.difference(_lastSeen!) < window;
    _lastCode = code;
    _lastSeen = now;
    return !repeated;
  }
}
