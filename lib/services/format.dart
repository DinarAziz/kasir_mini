// Format angka dan tanggal (tanpa paket intl).

/// 35500 -> "35.500"
String formatAngka(int n) {
  final negatif = n < 0;
  final digits = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return negatif ? '-$buf' : buf.toString();
}

/// 35500 -> "Rp 35.500"
String formatRupiah(int n) => 'Rp ${formatAngka(n)}';

/// "35.500" atau "Rp 35.500" -> 35500. Kosong atau bukan angka -> null.
int? parseAngka(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty || digits.length > 12) return null;
  return int.parse(digits);
}

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', //
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _dua(int n) => n.toString().padLeft(2, '0');

/// "09.12" (titik sebagai pemisah, gaya Indonesia)
String formatJam(DateTime t) => '${_dua(t.hour)}.${_dua(t.minute)}';

/// "21 Sep 2026"
String formatTanggal(DateTime t) => '${t.day} ${_bulan[t.month - 1]} ${t.year}';

/// "21 Sep 2026, 16.05"
String formatTanggalJam(DateTime t) => '${formatTanggal(t)}, ${formatJam(t)}';

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
