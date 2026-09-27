enum PaymentMethod {
  tunai('Tunai'),
  qris('QRIS'),
  debit('Debit');

  const PaymentMethod(this.label);
  final String label;
}

/// Baris struk. Nama dan harga adalah snapshot saat transaksi, jadi ubah atau
/// hapus produk tidak mengubah riwayat.
class SaleItem {
  const SaleItem({
    required this.name,
    required this.qty,
    required this.price,
    this.productId,
  });

  final int? productId;
  final String name;
  final int qty;
  final int price;

  int get subtotal => qty * price;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'qty': qty,
    'price': price,
  };

  factory SaleItem.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Item transaksi rusak.');
    final name = json['name'];
    final qty = json['qty'];
    final price = json['price'];
    final productId = json['productId'];
    if (name is! String || qty is! int || qty <= 0 || price is! int) {
      throw const FormatException('Item transaksi tidak valid.');
    }
    if (productId != null && productId is! int) {
      throw const FormatException('Item transaksi tidak valid.');
    }
    return SaleItem(
      productId: productId as int?,
      name: name,
      qty: qty,
      price: price,
    );
  }
}

/// Satu transaksi yang sudah selesai.
class Sale {
  const Sale({
    required this.no,
    required this.time,
    required this.items,
    required this.total,
    required this.method,
    this.tendered,
    this.change,
  });

  final String no;
  final DateTime time;
  final List<SaleItem> items;
  final int total;
  final PaymentMethod method;

  /// Uang diterima dan kembalian, hanya untuk pembayaran tunai.
  final int? tendered;
  final int? change;

  int get itemCount => items.fold(0, (a, i) => a + i.qty);

  Map<String, dynamic> toJson() => {
    'no': no,
    'time': time.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'total': total,
    'method': method.name,
    'tendered': tendered,
    'change': change,
  };

  factory Sale.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Transaksi rusak.');
    final no = json['no'];
    final time = json['time'];
    final items = json['items'];
    final total = json['total'];
    final method = json['method'];
    final tendered = json['tendered'];
    final change = json['change'];
    if (no is! String || time is! String || items is! List || total is! int) {
      throw const FormatException('Data transaksi tidak lengkap.');
    }
    final parsedTime = DateTime.tryParse(time);
    final parsedMethod = PaymentMethod.values
        .where((m) => m.name == method)
        .firstOrNull;
    if (parsedTime == null || parsedMethod == null) {
      throw FormatException('Transaksi $no memiliki waktu atau metode salah.');
    }
    if ((tendered != null && tendered is! int) ||
        (change != null && change is! int)) {
      throw FormatException('Transaksi $no memiliki nilai tunai salah.');
    }
    return Sale(
      no: no,
      time: parsedTime,
      items: items.map(SaleItem.fromJson).toList(),
      total: total,
      method: parsedMethod,
      tendered: tendered as int?,
      change: change as int?,
    );
  }
}
