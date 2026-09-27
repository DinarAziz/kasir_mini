import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_mini/main.dart';
import 'package:kasir_mini/store/app_scope.dart';

import 'test_helpers.dart';

/// Uji alur layar utama pada ukuran desain 390x844.
Future<void> pumpApp(WidgetTester tester, {MemoryStorage? storage}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = makeStore(storage: storage);
  await tester.pumpWidget(KasirMiniApp(store: store));
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester, [String pin = '1234']) async {
  for (final d in pin.split('')) {
    await tester.tap(find.text(d));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('PIN salah menampilkan pesan dan mengosongkan input', (
    tester,
  ) async {
    await pumpApp(tester);
    await login(tester, '1111');
    expect(find.text('PIN salah. Coba lagi.'), findsOneWidget);
    expect(find.text('Kasir Mini'), findsOneWidget);
    // Input kosong lagi: pesan hilang setelah mengetik satu digit.
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(find.text('PIN salah. Coba lagi.'), findsNothing);
  });

  testWidgets('PIN benar membuka Kasir dengan keranjang kosong', (
    tester,
  ) async {
    await pumpApp(tester);
    await login(tester);
    expect(find.text('PRODUK CEPAT'), findsOneWidget);
    expect(find.textContaining('Keranjang kosong'), findsOneWidget);
    final bayar = tester.widget<InkWell>(
      find.ancestor(of: find.text('Bayar'), matching: find.byType(InkWell)),
    );
    expect(bayar.onTap, isNull); // nonaktif bila keranjang kosong
  });

  testWidgets(
    'tambah lewat chip, batas stok, bayar tunai, struk, transaksi baru',
    (tester) async {
      final storage = MemoryStorage();
      await pumpApp(tester, storage: storage);
      await login(tester);

      await tester.tap(find.text('Indomie Goreng'));
      await tester.pump();
      await tester.tap(find.text('Aqua 600'));
      await tester.pump();
      expect(find.text('KERANJANG (2 ITEM)'), findsOneWidget);
      expect(find.text('Rp 7.000'), findsWidgets);

      // Ke pembayaran, uang pas.
      await tester.tap(find.text('Bayar'));
      await tester.pumpAndSettle();
      expect(find.text('Total tagihan (2 item)'), findsOneWidget);
      expect(find.text('Masukkan uang yang diterima'), findsOneWidget);
      await tester.tap(find.text('20.000'));
      await tester.pump();
      expect(find.text('Kembalian Rp 13.000'), findsOneWidget);
      await tester.tap(find.text('Uang pas'));
      await tester.pump();
      expect(find.text('Kembalian Rp 0'), findsOneWidget);
      await tester.tap(find.text('Konfirmasi pembayaran'));
      await tester.pumpAndSettle();

      expect(find.text('Pembayaran berhasil'), findsOneWidget);
      expect(find.text('TRX-0044'), findsOneWidget);
      expect(find.text('1 x Indomie Goreng'), findsOneWidget);

      await tester.tap(find.text('Transaksi baru'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Keranjang kosong'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1)); // beri waktu simpan
    },
  );

  testWidgets('uang kurang: tombol konfirmasi nonaktif dan tampil Kurang', (
    tester,
  ) async {
    await pumpApp(tester);
    await login(tester);
    await tester.tap(find.text('Teh Botol'));
    await tester.pump();
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(find.text('Kurang Rp 5.499'), findsOneWidget);
    final confirm = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('Konfirmasi pembayaran'),
        matching: find.byType(InkWell),
      ),
    );
    expect(confirm.onTap, isNull);
  });

  testWidgets('QRIS dan Debit ditandai simulasi', (tester) async {
    await pumpApp(tester);
    await login(tester);
    await tester.tap(find.text('Aqua 600'));
    await tester.pump();
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('QRIS'));
    await tester.pump();
    expect(find.textContaining('SIMULASI'), findsOneWidget);
    await tester.tap(find.text('Debit'));
    await tester.pump();
    expect(find.textContaining('SIMULASI'), findsOneWidget);
    expect(find.text('Simulasikan kartu disetujui'), findsOneWidget);
  });

  testWidgets('cari: Enter dengan kode persis menambah produk', (tester) async {
    await pumpApp(tester);
    await login(tester);
    await tester.tap(find.text('Cari nama atau kode produk'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '8886008101053');
    await tester.pump();
    expect(find.text('Aqua 600 ml'), findsOneWidget);
    expect(find.text('Indomie Goreng'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.text('Ditambahkan: Aqua 600 ml'), findsOneWidget);
    expect(find.text('Lihat keranjang (1 item)'), findsOneWidget);
  });

  testWidgets('tab Riwayat, Stok (Menipis), dan Kelola tampil', (tester) async {
    await pumpApp(tester);
    await login(tester);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Rp 115.000'), findsOneWidget);
    expect(find.text('TRX-0043'), findsOneWidget);

    await tester.tap(find.text('Stok'));
    await tester.pumpAndSettle();
    expect(find.text('Semua (10)'), findsOneWidget);
    await tester.tap(find.text('Menipis (4)'));
    await tester.pump();
    expect(find.text('Beras 5 kg'), findsNothing);
    expect(find.text('Sabun Mandi Batang'), findsOneWidget);

    await tester.tap(find.text('Kelola'));
    await tester.pumpAndSettle();
    expect(find.text('10 PRODUK · 4 STOK MENIPIS'), findsOneWidget);
    expect(find.text('Backup & Transfer'), findsOneWidget);
  });

  testWidgets('form produk: validasi kode unik lalu simpan', (tester) async {
    await pumpApp(tester);
    await login(tester);
    await tester.tap(find.text('Kelola'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah produk'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Indomie Soto');
    await tester.enterText(
      fields.at(1),
      '8998866200318',
    ); // milik Indomie Goreng
    await tester.enterText(fields.at(2), '3500');
    await tester.enterText(fields.at(3), '48');
    await tester.tap(find.text('Simpan produk'));
    await tester.pump();
    expect(find.textContaining('Kode sudah dipakai'), findsOneWidget);

    await tester.enterText(fields.at(1), '8998866200457');
    await tester.tap(find.text('Simpan produk'));
    await tester.pumpAndSettle();
    expect(find.text('11 PRODUK · 4 STOK MENIPIS'), findsOneWidget);
  });

  testWidgets('backup: clipboard rusak menampilkan error, data tidak berubah', (
    tester,
  ) async {
    FakeClipboard().install(tester);
    await pumpApp(tester);
    await login(tester);
    await tester.tap(find.text('Kelola'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup & Transfer'));
    await tester.pumpAndSettle();
    expect(find.text('Backup terakhir: belum pernah'), findsOneWidget);

    // Clipboard pengujian kosong -> pesan dan kolom tempel muncul.
    await tester.ensureVisible(find.text('Tempel & pulihkan data'));
    await tester.tap(find.text('Tempel & pulihkan data'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Clipboard kosong'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      '{"app":"kasir-mini","version":9}',
    );
    await tester.ensureVisible(find.text('Pulihkan dari teks di atas'));
    await tester.tap(find.text('Pulihkan dari teks di atas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Versi backup 9 tidak dikenal'), findsOneWidget);
    expect(find.text('Pulihkan data?'), findsNothing);
  });

  testWidgets('backup: salin lalu pulihkan lewat dialog konfirmasi', (
    tester,
  ) async {
    final clip = FakeClipboard()..install(tester);
    await pumpApp(tester);
    await login(tester);

    // Ubah data dulu: jual 1 Aqua, jadi ada 4 transaksi.
    await tester.tap(find.text('Aqua 600'));
    await tester.pump();
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('QRIS'));
    await tester.pump();
    await tester.tap(find.text('Simulasikan pembayaran diterima'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transaksi baru'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kelola'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup & Transfer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salin data backup'));
    await tester.pumpAndSettle();
    expect(clip.text, contains('"app":"kasir-mini"'));
    expect(
      find.textContaining('Backup terakhir: 21 Sep 2026, 16.05'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Tempel & pulihkan data'));
    await tester.tap(find.text('Tempel & pulihkan data'));
    await tester.pumpAndSettle();
    expect(find.text('Pulihkan data?'), findsOneWidget);
    expect(
      find.textContaining('Ditemukan 10 produk dan 4 transaksi'),
      findsOneWidget,
    );
    expect(find.textContaining('21 Sep 2026, 16.05'), findsWidgets);
    expect(find.text('Data di HP ini akan diganti.'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Pulihkan data?'), findsNothing);

    await tester.tap(find.text('Tempel & pulihkan data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pulihkan'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Data dipulihkan: 10 produk, 4 transaksi'),
      findsOneWidget,
    );
  });

  Future<void> scanWithKeyboard(WidgetTester tester, String code) async {
    for (final ch in code.split('')) {
      final key = LogicalKeyboardKey(ch.codeUnitAt(0));
      await simulateKeyDownEvent(key, character: ch);
      await simulateKeyUpEvent(key);
    }
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    await simulateKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
  }

  testWidgets('scanner keyboard di layar Kasir menambah produk', (
    tester,
  ) async {
    await pumpApp(tester);
    await login(tester);
    await scanWithKeyboard(tester, '8886008101053');
    expect(find.text('KERANJANG (1 ITEM)'), findsOneWidget);
    expect(find.text('Terpindai: Aqua 600 ml'), findsOneWidget);
  });

  testWidgets(
    'scanner keyboard: kode tak dikenal membuka sheet lalu form berkode',
    (tester) async {
      await pumpApp(tester);
      await login(tester);
      await scanWithKeyboard(tester, '8991234567890');
      expect(find.text('Kode belum terdaftar'), findsOneWidget);
      await tester.tap(find.text('Tambah produk dengan kode ini'));
      await tester.pumpAndSettle();
      expect(find.text('Tambah produk'), findsWidgets);
      expect(find.widgetWithText(TextField, '8991234567890'), findsOneWidget);
    },
  );

  testWidgets('scanner keyboard diabaikan saat layar lain menutupi Kasir', (
    tester,
  ) async {
    await pumpApp(tester);
    await login(tester);
    await tester.tap(find.text('Cari nama atau kode produk'));
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await scanWithKeyboard(tester, '8886008101053');
    expect(AppScopeReader.cartCount(tester), 0);
  });
}

class AppScopeReader {
  static int cartCount(WidgetTester tester) {
    final ctx = tester.element(find.byType(Scaffold).first);
    return AppScope.read(ctx).cartCount;
  }
}
