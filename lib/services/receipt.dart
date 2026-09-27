import '../constants.dart';
import '../models/sale.dart';
import 'format.dart';

/// Teks struk polos (untuk disalin ke WhatsApp), lebar 32 karakter.
String receiptText(Sale sale) {
  const width = 32;
  String kiriKanan(String l, String r) {
    final gap = width - l.length - r.length;
    return gap > 0 ? '$l${' ' * gap}$r' : '$l $r';
  }

  String tengah(String s) =>
      s.length >= width ? s : '${' ' * ((width - s.length) ~/ 2)}$s';

  final garis = '-' * width;
  final b = StringBuffer()
    ..writeln(tengah(kStoreName))
    ..writeln(tengah(kStoreAddress))
    ..writeln(garis)
    ..writeln(kiriKanan(sale.no, formatTanggalJam(sale.time)))
    ..writeln(kiriKanan('Kasir', kCashierName))
    ..writeln(garis);
  for (final i in sale.items) {
    b.writeln(kiriKanan('${i.qty} x ${i.name}', formatAngka(i.subtotal)));
  }
  b
    ..writeln(garis)
    ..writeln(kiriKanan('TOTAL', formatAngka(sale.total)))
    ..writeln(kiriKanan('Metode', sale.method.label));
  if (sale.method == PaymentMethod.tunai) {
    b
      ..writeln(kiriKanan('Tunai', formatAngka(sale.tendered ?? sale.total)))
      ..writeln(kiriKanan('Kembali', formatAngka(sale.change ?? 0)));
  }
  b
    ..writeln(garis)
    ..write(tengah('Terima kasih'));
  return b.toString();
}
