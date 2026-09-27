import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_mini/services/product_validator.dart';

import 'test_helpers.dart';

ProductFormResult check(
  String name,
  String code,
  String price,
  String stock, {
  int? editingId,
}) {
  final s = makeStore();
  return ProductValidator.validate(
    name: name,
    code: code,
    price: price,
    stock: stock,
    existing: s.products,
    id: s.nextProductId,
    editingId: editingId,
  );
}

void main() {
  test('produk valid: kode boleh kosong', () {
    final r = check('Indomie Soto', '', '3.500', '48');
    expect(r.isValid, isTrue);
    expect(r.product!.code, isNull);
    expect(r.product!.price, 3500);
    expect(r.product!.stock, 48);
    expect(r.product!.id, 11);
  });

  test('nama wajib', () {
    final r = check('   ', '', '3500', '1');
    expect(r.isValid, isFalse);
    expect(r.nameError, isNotNull);
  });

  test('kode harus unik', () {
    final r = check('Produk Baru', '8998866200318', '3500', '1');
    expect(r.isValid, isFalse);
    expect(r.codeError, contains('Indomie Goreng'));
  });

  test('mode ubah: kode milik produk sendiri tidak dianggap ganda', () {
    final sendiri = check(
      'Indomie Goreng',
      '8998866200318',
      '3500',
      '84',
      editingId: 1,
    );
    expect(sendiri.isValid, isTrue);
    // Tapi kode milik produk lain tetap ditolak.
    final lain = check(
      'Indomie Goreng',
      '8996001600146',
      '3500',
      '84',
      editingId: 1,
    );
    expect(lain.codeError, isNotNull);
  });

  test('harga harus lebih dari 0', () {
    expect(check('A', '', '0', '1').priceError, isNotNull);
    expect(check('A', '', '', '1').priceError, isNotNull);
    expect(check('A', '', '1', '1').isValid, isTrue);
  });

  test('stok 0 boleh, kosong tidak', () {
    expect(check('A', '', '100', '0').isValid, isTrue);
    expect(check('A', '', '100', '').stockError, isNotNull);
  });

  test('semua error dilaporkan sekaligus', () {
    final r = check('', '8998866200318', '0', '');
    expect(r.nameError, isNotNull);
    expect(r.codeError, isNotNull);
    expect(r.priceError, isNotNull);
    expect(r.stockError, isNotNull);
  });
}
