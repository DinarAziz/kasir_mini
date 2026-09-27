/// Menerima kode hanya bila terbaca sama pada [required] frame berturut-turut.
///
/// Satu frame yang buram bisa menghasilkan kode salah yang lolos digit
/// periksa. Frame berikutnya hampir tidak mungkin menghasilkan kesalahan yang
/// sama, jadi kode baru diterima setelah terbaca konsisten. Bila jeda antar
/// bacaan lebih dari [maxGap] atau kode berganti, hitungan mulai dari awal.
class ScanConfirmer {
  ScanConfirmer({
    this.required = 3,
    this.maxGap = const Duration(milliseconds: 600),
  }) : assert(required >= 1);

  final int required;
  final Duration maxGap;
  String? _code;
  DateTime? _last;
  int _count = 0;

  /// Jumlah bacaan beruntun untuk kode yang sedang dikonfirmasi.
  int get count => _count;

  /// True bila [code] sudah terbaca konsisten pada waktu [now].
  bool confirm(String code, DateTime now) {
    final last = _last;
    final continuing =
        code == _code && last != null && now.difference(last) <= maxGap;
    _count = continuing ? _count + 1 : 1;
    _code = code;
    _last = now;
    return _count >= required;
  }

  void reset() {
    _code = null;
    _last = null;
    _count = 0;
  }
}
