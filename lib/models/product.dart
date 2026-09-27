/// Produk yang dijual. [code] kosong (null) untuk produk tanpa barcode.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.code,
  });

  final int id;
  final String name;
  final String? code;
  final int price;
  final int stock;

  Product copyWith({String? name, String? code, int? price, int? stock}) =>
      Product(
        id: id,
        name: name ?? this.name,
        code: code ?? this.code,
        price: price ?? this.price,
        stock: stock ?? this.stock,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'price': price,
    'stock': stock,
  };

  /// Melempar [FormatException] bila data tidak valid.
  factory Product.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Produk bukan objek.');
    final id = json['id'];
    final name = json['name'];
    final code = json['code'];
    final price = json['price'];
    final stock = json['stock'];
    if (id is! int || name is! String || name.trim().isEmpty) {
      throw const FormatException('Data produk tidak lengkap.');
    }
    if (code != null && code is! String) {
      throw FormatException('Kode produk "$name" tidak valid.');
    }
    if (price is! int || price <= 0) {
      throw FormatException('Harga produk "$name" tidak valid.');
    }
    if (stock is! int || stock < 0) {
      throw FormatException('Stok produk "$name" tidak valid.');
    }
    final kode = (code as String?)?.trim();
    return Product(
      id: id,
      name: name,
      code: (kode == null || kode.isEmpty) ? null : kode,
      price: price,
      stock: stock,
    );
  }
}
