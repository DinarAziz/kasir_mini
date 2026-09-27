import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_mini/models/app_data.dart';
import 'package:kasir_mini/services/format.dart';
import 'package:kasir_mini/services/storage_service.dart';

import 'test_helpers.dart';

void main() {
  test('format rupiah', () {
    expect(formatRupiah(35500), 'Rp 35.500');
    expect(formatRupiah(0), 'Rp 0');
    expect(formatRupiah(1500), 'Rp 1.500');
    expect(formatRupiah(1234567), 'Rp 1.234.567');
    expect(formatAngka(999), '999');
  });

  test('parseAngka membaca angka bertitik', () {
    expect(parseAngka('3.500'), 3500);
    expect(parseAngka('Rp 35.500'), 35500);
    expect(parseAngka(''), isNull);
    expect(parseAngka('abc'), isNull);
  });

  test('format tanggal dan jam gaya Indonesia', () {
    expect(
      formatTanggalJam(DateTime(2026, 9, 21, 16, 5)),
      '21 Sep 2026, 16.05',
    );
    expect(formatJam(DateTime(2026, 1, 2, 9, 3)), '09.03');
  });

  test('data awal: 10 produk dan 3 transaksi dummy', () {
    final d = AppData.seed(testNow);
    expect(d.products.length, 10);
    expect(d.sales.length, 3);
    expect(d.sales.fold<int>(0, (a, s) => a + s.total), 115000);
    expect(d.nextNo, 44);
  });

  test('AppData toJson/fromJson roundtrip', () {
    final d = AppData.seed(testNow);
    final back = AppData.fromJson(d.toJson());
    expect(back.toJson(), d.toJson());
  });

  test('PrefsStorage memakai kunci tunggal', () {
    expect(PrefsStorage.key, 'kasir_mini_data');
  });
}
