import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  test('stok menipis: stok <= 10, urut dari terendah', () {
    final s = makeStore();
    final low = s.lowStock..sort((a, b) => a.stock.compareTo(b.stock));
    expect(low.map((p) => p.stock), [3, 6, 8, 9]);
    expect(low.map((p) => p.name).first, 'Sabun Mandi Batang');
  });

  test('stok tepat 10 masih dianggap menipis, 11 tidak', () {
    final s = makeStore();
    s.updateProduct(s.productById(1)!.copyWith(stock: 10));
    s.updateProduct(s.productById(3)!.copyWith(stock: 11));
    final ids = s.lowStock.map((p) => p.id).toSet();
    expect(ids.contains(1), isTrue);
    expect(ids.contains(3), isFalse);
  });
}
