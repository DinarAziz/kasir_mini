import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../models/app_data.dart';
import '../models/cart_line.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/backup_service.dart';
import '../services/barcode_validator.dart';
import '../services/format.dart';
import '../services/storage_service.dart';

enum AddStatus { added, outOfStock, limitReached, notFound }

/// Hasil menambah barang ke keranjang.
class AddResult {
  const AddResult(this.status, {this.product, this.qtyInCart = 0});

  final AddStatus status;
  final Product? product;
  final int qtyInCart;

  bool get added => status == AddStatus.added;

  /// Pesan untuk pengguna bila gagal, null bila berhasil.
  String? get message => switch (status) {
    AddStatus.outOfStock => 'Stok habis',
    AddStatus.limitReached => 'Stok tinggal ${product!.stock}',
    _ => null,
  };
}

class CheckoutException implements Exception {
  CheckoutException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sumber kebenaran data aplikasi: produk, keranjang, transaksi.
/// Setiap perubahan data langsung disimpan lewat [Storage].
class AppStore extends ChangeNotifier {
  AppStore({
    required Storage storage,
    required AppData data,
    DateTime Function()? clock,
  }) : _storage = storage, // ignore: prefer_initializing_formals

       _clock = clock ?? DateTime.now,
       _products = List.of(data.products),
       _sales = List.of(data.sales),
       _nextNo = data.nextNo,
       _lastBackupAt = data.lastBackupAt;

  /// Membuka data tersimpan, atau mengisi data contoh saat pertama jalan
  /// (juga bila data tersimpan rusak).
  static Future<AppStore> open(
    Storage storage, {
    DateTime Function()? clock,
  }) async {
    final now = (clock ?? DateTime.now)();
    AppData? data;
    try {
      data = await storage.load();
    } catch (e) {
      debugPrint('Data tersimpan tidak terbaca, memakai data contoh: $e');
    }
    final store = AppStore(
      storage: storage,
      data: data ?? AppData.seed(now),
      clock: clock,
    );
    if (data == null) store._persist();
    return store;
  }

  final Storage _storage;
  final DateTime Function() _clock;
  final List<CartLine> _cart = [];
  List<Product> _products;
  List<Sale> _sales;
  int _nextNo;
  DateTime? _lastBackupAt;
  Future<void> _pending = Future.value();

  /// Tab yang aktif di layar utama (0 Kasir, 1 Riwayat, 2 Stok, 3 Kelola).
  int tabIndex = 0;

  void selectTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  // ---------- baca data ----------

  List<Product> get products => List.unmodifiable(_products);
  List<Sale> get sales => List.unmodifiable(_sales);
  List<CartLine> get cart => List.unmodifiable(_cart);
  int get nextNo => _nextNo;
  DateTime? get lastBackupAt => _lastBackupAt;

  Product? productById(int id) =>
      _products.where((p) => p.id == id).firstOrNull;

  Product? productByCode(String code) {
    final c = code.trim();
    if (c.isEmpty) return null;
    final candidates = BarcodeValidator.variants(c);
    return _products.where((p) => candidates.contains(p.code)).firstOrNull;
  }

  List<Product> get lowStock =>
      _products.where((p) => p.stock <= kLowStockLimit).toList();

  /// Cari nama atau kode (huruf besar/kecil tidak dibedakan).
  List<Product> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return _products
        .where(
          (p) => p.name.toLowerCase().contains(q) || (p.code ?? '').contains(q),
        )
        .toList();
  }

  List<Sale> todaySales() {
    final now = _clock();
    return _sales.where((s) => sameDay(s.time, now)).toList();
  }

  int get todayTotal => todaySales().fold(0, (a, s) => a + s.total);

  Sale? saleByNo(String no) => _sales.where((s) => s.no == no).firstOrNull;

  /// Data lengkap saat ini (untuk disimpan atau di-backup).
  AppData get snapshot => AppData(
    products: List.of(_products),
    sales: List.of(_sales),
    nextNo: _nextNo,
    lastBackupAt: _lastBackupAt,
  );

  // ---------- keranjang ----------

  int get cartCount => _cart.fold(0, (a, l) => a + l.qty);

  int get cartTotal => _cart.fold(0, (a, l) {
    final p = productById(l.productId);
    return a + (p == null ? 0 : p.price * l.qty);
  });

  int qtyInCart(int productId) =>
      _cart.where((l) => l.productId == productId).firstOrNull?.qty ?? 0;

  /// Menambah 1 barang. Jumlah tidak boleh melebihi stok.
  AddResult addToCart(int productId) {
    final p = productById(productId);
    if (p == null) return const AddResult(AddStatus.notFound);
    final qty = qtyInCart(productId);
    if (p.stock <= 0) {
      return AddResult(AddStatus.outOfStock, product: p, qtyInCart: qty);
    }
    if (qty + 1 > p.stock) {
      return AddResult(AddStatus.limitReached, product: p, qtyInCart: qty);
    }
    final line = _cart.where((l) => l.productId == productId).firstOrNull;
    if (line == null) {
      _cart.add(CartLine(productId, 1));
    } else {
      line.qty++;
    }
    notifyListeners();
    return AddResult(AddStatus.added, product: p, qtyInCart: qty + 1);
  }

  /// Menambah barang berdasarkan kode barcode (scan kamera atau keyboard).
  AddResult addByCode(String code) {
    final p = productByCode(code);
    if (p == null) return const AddResult(AddStatus.notFound);
    return addToCart(p.id);
  }

  void decrementCart(int productId) {
    final line = _cart.where((l) => l.productId == productId).firstOrNull;
    if (line == null) return;
    line.qty--;
    if (line.qty <= 0) _cart.remove(line);
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cart.removeWhere((l) => l.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // ---------- transaksi ----------

  /// Menyelesaikan pembayaran: mengurangi stok, menyimpan snapshot transaksi,
  /// mengosongkan keranjang. Untuk tunai, [tendered] wajib >= total.
  Sale checkout(PaymentMethod method, {int? tendered}) {
    if (_cart.isEmpty) throw CheckoutException('Keranjang kosong.');
    final total = cartTotal;
    if (method == PaymentMethod.tunai &&
        (tendered == null || tendered < total)) {
      throw CheckoutException('Uang diterima kurang dari total.');
    }
    final items = <SaleItem>[];
    for (final line in _cart) {
      final p = productById(line.productId);
      if (p == null) throw CheckoutException('Produk sudah dihapus.');
      if (line.qty > p.stock) {
        throw CheckoutException('${p.name}: stok tinggal ${p.stock}');
      }
      items.add(
        SaleItem(productId: p.id, name: p.name, qty: line.qty, price: p.price),
      );
    }
    final sale = Sale(
      no: 'TRX-${_nextNo.toString().padLeft(4, '0')}',
      time: _clock(),
      items: items,
      total: total,
      method: method,
      tendered: method == PaymentMethod.tunai ? tendered : null,
      change: method == PaymentMethod.tunai ? tendered! - total : null,
    );
    _products = [
      for (final p in _products)
        qtyInCart(p.id) > 0 ? p.copyWith(stock: p.stock - qtyInCart(p.id)) : p,
    ];
    _sales = [sale, ..._sales];
    _nextNo++;
    _cart.clear();
    _commit();
    return sale;
  }

  // ---------- kelola produk ----------

  int get nextProductId => _products.fold(0, (m, p) => p.id > m ? p.id : m) + 1;

  void addProduct(Product product) {
    _products = [..._products, product];
    _commit();
  }

  void updateProduct(Product product) {
    _products = [for (final p in _products) p.id == product.id ? product : p];
    // Jumlah di keranjang tidak boleh melebihi stok baru.
    for (final line in List.of(_cart)) {
      if (line.productId != product.id) continue;
      if (line.qty > product.stock) line.qty = product.stock;
      if (line.qty <= 0) _cart.remove(line);
    }
    _commit();
  }

  /// Menghapus produk. Riwayat transaksi tidak berubah karena menyimpan snapshot.
  void deleteProduct(int id) {
    _products = _products.where((p) => p.id != id).toList();
    _cart.removeWhere((l) => l.productId == id);
    _commit();
  }

  // ---------- backup ----------

  /// Membuat teks backup dan mencatat waktunya.
  String exportBackup() {
    final now = _clock();
    final text = BackupService.export(snapshot, now);
    _lastBackupAt = now;
    _commit();
    return text;
  }

  /// Mengganti seluruh data dengan isi [preview] yang sudah divalidasi.
  void restore(BackupPreview preview) {
    _products = List.of(preview.data.products);
    _sales = List.of(preview.data.sales);
    _nextNo = preview.data.nextNo;
    _cart.clear();
    _commit();
  }

  // ---------- simpan ----------

  /// Menunggu penyimpanan terakhir selesai (dipakai tes).
  Future<void> flush() => _pending;

  void _commit() {
    notifyListeners();
    _persist();
  }

  void _persist() {
    final data = snapshot;
    _pending = _pending.then((_) => _storage.save(data)).catchError((Object e) {
      debugPrint('Gagal menyimpan data: $e');
    });
  }
}
