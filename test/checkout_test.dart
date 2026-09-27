import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_mini/models/sale.dart';
import 'package:kasir_mini/store/app_store.dart';

import 'test_helpers.dart';

void main() {
  test('kembalian tunai dihitung dari uang diterima dikurangi total', () {
    final s = makeStore();
    s.addToCart(3); // Aqua 3.500
    s.addToCart(4); // Roti 16.500  -> total 20.000
    final sale = s.checkout(PaymentMethod.tunai, tendered: 50000);
    expect(sale.total, 20000);
    expect(sale.tendered, 50000);
    expect(sale.change, 30000);
  });

  test('checkout mengurangi stok, mengosongkan keranjang, menaikkan nomor', () {
    final s = makeStore();
    s.addToCart(1);
    s.addToCart(1);
    s.addToCart(4);
    final sale = s.checkout(PaymentMethod.qris);
    expect(s.productById(1)!.stock, 82);
    expect(s.productById(4)!.stock, 5);
    expect(s.cart, isEmpty);
    expect(sale.no, 'TRX-0044');
    expect(s.nextNo, 45);
    expect(s.sales.first.no, 'TRX-0044'); // terbaru di atas
    expect(sale.tendered, isNull);
    expect(sale.change, isNull);
  });

  test('struk menyimpan snapshot nama dan harga saat transaksi', () {
    final s = makeStore();
    s.addToCart(1);
    final sale = s.checkout(PaymentMethod.debit);
    // Ubah harga dan nama, lalu hapus produk.
    s.updateProduct(s.productById(1)!.copyWith(name: 'Nama Baru', price: 9999));
    expect(s.saleByNo(sale.no)!.items.first.name, 'Indomie Goreng');
    expect(s.saleByNo(sale.no)!.items.first.price, 3500);
    s.deleteProduct(1);
    expect(s.saleByNo(sale.no)!.items.first.name, 'Indomie Goreng');
    expect(s.saleByNo(sale.no)!.total, 3500);
  });

  test('tunai kurang dari total ditolak dan data tidak berubah', () {
    final s = makeStore();
    s.addToCart(4);
    expect(
      () => s.checkout(PaymentMethod.tunai, tendered: 10000),
      throwsA(isA<CheckoutException>()),
    );
    expect(s.productById(4)!.stock, 6);
    expect(s.cart.length, 1);
    expect(s.sales.length, 3);
  });

  test('keranjang kosong tidak bisa checkout', () {
    final s = makeStore();
    expect(
      () => s.checkout(PaymentMethod.qris),
      throwsA(isA<CheckoutException>()),
    );
  });

  test('penjualan hari ini hanya menghitung transaksi tanggal hari ini', () {
    final s = makeStore();
    expect(s.todaySales().length, 3);
    expect(s.todayTotal, 115000);
    s.addToCart(3);
    s.checkout(PaymentMethod.qris);
    expect(s.todayTotal, 118500);
  });

  test('setiap perubahan tersimpan ke storage', () async {
    final storage = MemoryStorage();
    final s = makeStore(storage: storage);
    s.addToCart(3);
    s.checkout(PaymentMethod.qris);
    await s.flush();
    expect(storage.saveCount, 1);
    expect(storage.data!.nextNo, 45);
    expect(storage.data!.sales.length, 4);
    expect(storage.data!.products.firstWhere((p) => p.id == 3).stock, 119);
  });
}
