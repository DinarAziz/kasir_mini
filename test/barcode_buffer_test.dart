import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_mini/services/barcode_buffer.dart';
import 'package:kasir_mini/services/scan_debouncer.dart';

final t0 = DateTime(2026, 9, 21, 10);
DateTime ms(int n) => t0.add(Duration(milliseconds: n));

/// Mengetik [text] dengan jeda [gapMs] antar karakter, mulai dari [startMs].
/// Mengembalikan waktu karakter terakhir.
int typeText(BarcodeBuffer b, String text, {int gapMs = 20, int startMs = 0}) {
  var t = startMs;
  for (final c in text.split('')) {
    b.addChar(c, ms(t));
    t += gapMs;
  }
  return t - gapMs;
}

void main() {
  group('BarcodeBuffer', () {
    test('scanner cepat: karakter terkumpul, Enter mengeluarkan kode', () {
      final b = BarcodeBuffer();
      final last = typeText(b, '8998866200318', gapMs: 15);
      expect(b.current, '8998866200318');
      expect(b.submit(ms(last + 20)), '8998866200318');
      expect(b.current, isEmpty);
    });

    test('jeda lebih dari 100 ms mereset buffer (ketikan manusia)', () {
      final b = BarcodeBuffer();
      b.addChar('1', ms(0));
      b.addChar('2', ms(50));
      b.addChar('3', ms(300)); // jeda 250 ms -> mulai dari awal
      expect(b.current, '3');
    });

    test('jeda tepat 100 ms masih dianggap satu rangkaian', () {
      final b = BarcodeBuffer();
      b.addChar('1', ms(0));
      b.addChar('2', ms(100));
      expect(b.current, '12');
    });

    test('Enter setelah jeda lama tidak mengeluarkan kode lama', () {
      final b = BarcodeBuffer();
      typeText(b, '12345');
      expect(b.submit(ms(5000)), isNull);
      expect(b.current, isEmpty);
    });

    test('Enter tanpa karakter menghasilkan null', () {
      expect(BarcodeBuffer().submit(ms(0)), isNull);
    });

    test('dua scan berturut-turut tidak bercampur', () {
      final b = BarcodeBuffer();
      var last = typeText(b, 'AAA111');
      expect(b.submit(ms(last + 10)), 'AAA111');
      last = typeText(b, 'BBB222', startMs: 1000);
      expect(b.submit(ms(last + 10)), 'BBB222');
    });

    test('clear membuang isi buffer', () {
      final b = BarcodeBuffer();
      typeText(b, '999');
      b.clear();
      expect(b.submit(ms(50)), isNull);
    });

    test('batas jeda bisa diatur', () {
      final b = BarcodeBuffer(maxGap: const Duration(milliseconds: 30));
      b.addChar('1', ms(0));
      b.addChar('2', ms(50));
      expect(b.current, '2');
    });
  });

  group('ScanDebouncer', () {
    test('kode sama dalam 1,5 detik diabaikan', () {
      final d = ScanDebouncer();
      expect(d.accept('A', ms(0)), isTrue);
      expect(d.accept('A', ms(500)), isFalse);
      expect(d.accept('A', ms(1400)), isFalse);
    });

    test('kode berbeda langsung diterima', () {
      final d = ScanDebouncer();
      expect(d.accept('A', ms(0)), isTrue);
      expect(d.accept('B', ms(100)), isTrue);
    });

    test('kode sama diterima lagi setelah 1,5 detik tidak terlihat', () {
      final d = ScanDebouncer();
      expect(d.accept('A', ms(0)), isTrue);
      expect(d.accept('A', ms(1500)), isTrue);
    });

    test('kamera yang terus mengarah ke kode sama tidak menambah berulang', () {
      final d = ScanDebouncer();
      expect(d.accept('A', ms(0)), isTrue);
      for (var t = 250; t <= 5000; t += 250) {
        expect(d.accept('A', ms(t)), isFalse, reason: 't=$t');
      }
    });
  });
}
