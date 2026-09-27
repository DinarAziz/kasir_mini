import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_mini/models/sale.dart';
import 'package:kasir_mini/services/backup_service.dart';

import 'test_helpers.dart';

void main() {
  BackupException fail(String text) {
    try {
      BackupService.parse(text);
    } on BackupException catch (e) {
      return e;
    }
    throw TestFailure('parse seharusnya menolak teks ini');
  }

  test(
    'format backup: app, version, exportedAt, products, transactions, nextNo',
    () {
      final s = makeStore();
      final json = jsonDecode(s.exportBackup()) as Map;
      expect(json['app'], 'kasir-mini');
      expect(json['version'], 1);
      expect(json['exportedAt'], testNow.toIso8601String());
      expect((json['products'] as List).length, 10);
      expect((json['transactions'] as List).length, 3);
      expect(json['nextNo'], 44);
      expect(json.containsKey('pin'), isFalse);
      expect(s.lastBackupAt, testNow);
    },
  );

  test('roundtrip: ekspor lalu impor menghasilkan data sama', () {
    final a = makeStore();
    a.addToCart(3);
    a.checkout(PaymentMethod.tunai, tendered: 5000);
    final text = a.exportBackup();

    final preview = BackupService.parse(text);
    expect(preview.productCount, 10);
    expect(preview.transactionCount, 4);
    expect(preview.exportedAt, testNow);

    final b = makeStore();
    b.restore(preview);
    expect(
      b.products.map((p) => p.toJson()),
      a.products.map((p) => p.toJson()),
    );
    expect(b.sales.map((s) => s.toJson()), a.sales.map((s) => s.toJson()));
    expect(b.nextNo, a.nextNo);
    expect(b.sales.first.change, 1500);
  });

  test('restore mengganti seluruh data dan mengosongkan keranjang', () {
    final src = makeStore();
    src.deleteProduct(1);
    final preview = BackupService.parse(src.exportBackup());
    final dst = makeStore();
    dst.addToCart(2);
    dst.restore(preview);
    expect(dst.products.length, 9);
    expect(dst.cart, isEmpty);
  });

  test('teks bukan JSON ditolak', () {
    expect(fail('halo dunia').message, contains('bukan data backup yang utuh'));
    expect(fail('').message, contains('Tidak ada teks'));
  });

  test('JSON terpotong (rusak) ditolak', () {
    final text = makeStore().exportBackup();
    fail(text.substring(0, text.length ~/ 2));
  });

  test('JSON dari aplikasi lain ditolak', () {
    expect(fail('{"foo":1}').message, contains('bukan data backup Kasir Mini'));
    expect(fail('[1,2,3]').message, contains('bukan data backup Kasir Mini'));
  });

  test('versi tidak dikenal ditolak dengan pesan jelas', () {
    final map = jsonDecode(makeStore().exportBackup()) as Map<String, dynamic>;
    map['version'] = 2;
    expect(
      fail(jsonEncode(map)).message,
      contains('Versi backup 2 tidak dikenal'),
    );
    map.remove('version');
    expect(fail(jsonEncode(map)).message, contains('tidak dikenal'));
  });

  test(
    'isi rusak ditolak: harga negatif, ID ganda, kode ganda, nextNo salah',
    () {
      Map<String, dynamic> base() =>
          jsonDecode(makeStore().exportBackup()) as Map<String, dynamic>;

      var m = base();
      (m['products'] as List)[0]['price'] = -5;
      expect(fail(jsonEncode(m)).message, contains('rusak'));

      m = base();
      (m['products'] as List)[1]['id'] = 1;
      expect(fail(jsonEncode(m)).message, contains('ID produk ganda'));

      m = base();
      (m['products'] as List)[1]['code'] = (m['products'] as List)[0]['code'];
      expect(fail(jsonEncode(m)).message, contains('Kode barcode ganda'));

      m = base();
      m['nextNo'] = 'abc';
      expect(fail(jsonEncode(m)).message, contains('rusak'));

      m = base();
      m['products'] = 'bukan list';
      expect(fail(jsonEncode(m)).message, contains('rusak'));

      m = base();
      (m['transactions'] as List)[0]['method'] = 'kripto';
      expect(fail(jsonEncode(m)).message, contains('rusak'));
    },
  );

  test(
    'teks backup dengan spasi/baris kosong di ujung tetap terbaca (hasil salin WA)',
    () {
      final text = makeStore().exportBackup();
      expect(BackupService.parse('\n  $text \n\n').productCount, 10);
    },
  );

  test('penolakan tidak mengubah data yang ada', () {
    final s = makeStore();
    s.addToCart(3);
    final before = s.snapshot.toJson();
    try {
      BackupService.parse('{"app":"kasir-mini","version":1}');
    } on BackupException {
      // diharapkan
    }
    expect(s.snapshot.toJson(), before);
    expect(s.cart.length, 1);
  });
}
