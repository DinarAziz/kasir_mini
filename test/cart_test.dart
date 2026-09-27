import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_mini/store/app_store.dart';

import 'test_helpers.dart';

void main() {
  test('total dan jumlah item keranjang', () {
    final s = makeStore();
    s.addToCart(1); // Indomie 3.500
    s.addToCart(1);
    s.addToCart(1);
    s.addToCart(2); // Teh Botol 5.500
    s.addToCart(5); // Susu 19.500
    expect(s.cartCount, 5);
    expect(s.cartTotal, 35500);
  });

  test('kurang dan hapus baris', () {
    final s = makeStore();
    s.addToCart(1);
    s.addToCart(1);
    s.decrementCart(1);
    expect(s.qtyInCart(1), 1);
    s.decrementCart(1);
    expect(s.cart, isEmpty);
    s.addToCart(3);
    s.removeFromCart(3);
    expect(s.cart, isEmpty);
  });

  test('jumlah tidak boleh melebihi stok', () {
    final s = makeStore();
    // Sabun Mandi (id 9) stok 3
    for (var i = 0; i < 3; i++) {
      expect(s.addToCart(9).added, isTrue);
    }
    final r = s.addToCart(9);
    expect(r.status, AddStatus.limitReached);
    expect(r.message, 'Stok tinggal 3');
    expect(s.qtyInCart(9), 3);
  });

  test('stok 0 menampilkan Stok habis', () {
    final s = makeStore();
    final p = s.productById(9)!;
    s.updateProduct(p.copyWith(stock: 0));
    final r = s.addToCart(9);
    expect(r.status, AddStatus.outOfStock);
    expect(r.message, 'Stok habis');
    expect(s.cart, isEmpty);
  });

  test('addByCode: kode dikenal, tidak dikenal, dan kosong', () {
    final s = makeStore();
    expect(s.addByCode('8998866200318').added, isTrue);
    expect(s.addByCode('0000000000000').status, AddStatus.notFound);
    expect(s.addByCode('  ').status, AddStatus.notFound);
  });

  test('cari nama atau kode', () {
    final s = makeStore();
    expect(s.search('aqua').map((p) => p.id), [3]);
    expect(s.search('8990000000').length, 3);
    expect(s.search('').length, 10);
    expect(s.search('zzz'), isEmpty);
  });

  test('ubah stok produk memotong jumlah di keranjang', () {
    final s = makeStore();
    for (var i = 0; i < 3; i++) {
      s.addToCart(9);
    }
    s.updateProduct(s.productById(9)!.copyWith(stock: 1));
    expect(s.qtyInCart(9), 1);
  });
}
