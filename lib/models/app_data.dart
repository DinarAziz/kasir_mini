import 'product.dart';
import 'sale.dart';

/// Seluruh data toko yang disimpan ke perangkat.
class AppData {
  AppData({
    required this.products,
    required this.sales,
    required this.nextNo,
    this.lastBackupAt,
  });

  final List<Product> products;

  /// Transaksi terbaru di urutan pertama.
  final List<Sale> sales;
  final int nextNo;
  final DateTime? lastBackupAt;

  /// Data awal saat aplikasi pertama kali dijalankan: 10 produk contoh dan
  /// 3 transaksi dummy hari ini.
  factory AppData.seed(DateTime now) {
    DateTime at(int h, int m) => DateTime(now.year, now.month, now.day, h, m);
    return AppData(
      products: const [
        Product(
          id: 1,
          name: 'Indomie Goreng',
          price: 3500,
          stock: 84,
          code: '8998866200318',
        ),
        Product(
          id: 2,
          name: 'Teh Botol Sosro 450 ml',
          price: 5500,
          stock: 8,
          code: '8996001600146',
        ),
        Product(
          id: 3,
          name: 'Aqua 600 ml',
          price: 3500,
          stock: 120,
          code: '8886008101053',
        ),
        Product(
          id: 4,
          name: 'Roti Tawar Sari Roti',
          price: 16500,
          stock: 6,
          code: '8993003010010',
        ),
        Product(
          id: 5,
          name: 'Susu UHT Ultra 1 L',
          price: 19500,
          stock: 24,
          code: '8993200510016',
        ),
        Product(
          id: 6,
          name: 'Gula Pasir 1 kg',
          price: 17500,
          stock: 15,
          code: '8990000000068',
        ),
        Product(
          id: 7,
          name: 'Minyak Goreng 1 L',
          price: 18500,
          stock: 9,
          code: '8990000000075',
        ),
        Product(
          id: 8,
          name: 'Kopi Kapal Api Sachet',
          price: 1500,
          stock: 200,
          code: '8991002101050',
        ),
        Product(
          id: 9,
          name: 'Sabun Mandi Batang',
          price: 3500,
          stock: 3,
          code: '8999999000080',
        ),
        Product(
          id: 10,
          name: 'Beras 5 kg',
          price: 68000,
          stock: 12,
          code: '8990000000105',
        ),
      ],
      sales: [
        Sale(
          no: 'TRX-0043',
          time: at(10, 5),
          items: const [
            SaleItem(productId: 1, name: 'Indomie Goreng', qty: 5, price: 3500),
            SaleItem(
              productId: 8,
              name: 'Kopi Kapal Api Sachet',
              qty: 4,
              price: 1500,
            ),
          ],
          total: 23500,
          method: PaymentMethod.debit,
        ),
        Sale(
          no: 'TRX-0042',
          time: at(9, 47),
          items: const [
            SaleItem(productId: 10, name: 'Beras 5 kg', qty: 1, price: 68000),
          ],
          total: 68000,
          method: PaymentMethod.qris,
        ),
        Sale(
          no: 'TRX-0041',
          time: at(9, 12),
          items: const [
            SaleItem(productId: 3, name: 'Aqua 600 ml', qty: 2, price: 3500),
            SaleItem(
              productId: 4,
              name: 'Roti Tawar Sari Roti',
              qty: 1,
              price: 16500,
            ),
          ],
          total: 23500,
          method: PaymentMethod.tunai,
          tendered: 25000,
          change: 1500,
        ),
      ],
      nextNo: 44,
    );
  }

  /// Bagian yang dipakai bersama oleh penyimpanan dan backup.
  Map<String, dynamic> toJson() => {
    'products': products.map((p) => p.toJson()).toList(),
    'transactions': sales.map((s) => s.toJson()).toList(),
    'nextNo': nextNo,
  };

  /// Membaca [products], [transactions], dan [nextNo] dari [json].
  /// Melempar [FormatException] bila ada data yang salah.
  factory AppData.fromJson(
    Map<dynamic, dynamic> json, {
    DateTime? lastBackupAt,
  }) {
    final products = json['products'];
    final transactions = json['transactions'];
    final nextNo = json['nextNo'];
    if (products is! List || transactions is! List) {
      throw const FormatException('Daftar produk atau transaksi tidak ada.');
    }
    if (nextNo is! int || nextNo < 1) {
      throw const FormatException('Nomor transaksi berikutnya tidak valid.');
    }
    final parsedProducts = products.map(Product.fromJson).toList();
    final ids = <int>{};
    final codes = <String>{};
    for (final p in parsedProducts) {
      if (!ids.add(p.id)) {
        throw FormatException('ID produk ganda: ${p.id}.');
      }
      if (p.code != null && !codes.add(p.code!)) {
        throw FormatException('Kode barcode ganda: ${p.code}.');
      }
    }
    return AppData(
      products: parsedProducts,
      sales: transactions.map(Sale.fromJson).toList(),
      nextNo: nextNo,
      lastBackupAt: lastBackupAt,
    );
  }
}
