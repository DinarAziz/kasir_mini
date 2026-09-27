import '../models/product.dart';
import 'format.dart';

/// Hasil validasi form produk. Bila [isValid], [product] siap disimpan.
class ProductFormResult {
  ProductFormResult({
    this.nameError,
    this.codeError,
    this.priceError,
    this.stockError,
    this.product,
  });

  final String? nameError;
  final String? codeError;
  final String? priceError;
  final String? stockError;
  final Product? product;

  bool get isValid => product != null;
}

class ProductValidator {
  /// [editingId] diisi saat mode ubah, supaya kode milik produk itu sendiri
  /// tidak dianggap ganda. [id] dipakai untuk produk baru.
  static ProductFormResult validate({
    required String name,
    required String code,
    required String price,
    required String stock,
    required List<Product> existing,
    required int id,
    int? editingId,
  }) {
    final cleanName = name.trim();
    final cleanCode = code.trim();

    final nameError = cleanName.isEmpty ? 'Nama produk wajib diisi.' : null;

    String? codeError;
    if (cleanCode.isNotEmpty) {
      final dupe = existing
          .where((p) => p.id != editingId && p.code == cleanCode)
          .firstOrNull;
      if (dupe != null) codeError = 'Kode sudah dipakai "${dupe.name}".';
    }

    final priceValue = parseAngka(price);
    final priceError = (priceValue == null || priceValue <= 0)
        ? 'Harga harus lebih dari 0.'
        : null;

    final stockValue = parseAngka(stock);
    final stockError = stockValue == null
        ? 'Stok wajib diisi (0 atau lebih).'
        : null;

    if (nameError != null ||
        codeError != null ||
        priceError != null ||
        stockError != null) {
      return ProductFormResult(
        nameError: nameError,
        codeError: codeError,
        priceError: priceError,
        stockError: stockError,
      );
    }
    return ProductFormResult(
      product: Product(
        id: id,
        name: cleanName,
        code: cleanCode.isEmpty ? null : cleanCode,
        price: priceValue!,
        stock: stockValue!,
      ),
    );
  }
}
