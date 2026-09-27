import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_mini/services/barcode_validator.dart';
import 'package:kasir_mini/services/scan_confirmer.dart';

final t0 = DateTime(2026, 9, 21, 10);
DateTime ms(int n) => t0.add(Duration(milliseconds: n));

void main() {
  group('BarcodeValidator', () {
    test('EAN-13 sah diterima, satu digit salah ditolak', () {
      expect(BarcodeValidator.isValid('8998866200318', ScanKind.ean13), isTrue);
      expect(BarcodeValidator.isValid('8996001600146', ScanKind.ean13), isTrue);
      expect(BarcodeValidator.isValid('8998866200319', ScanKind.ean13), isFalse);
      expect(BarcodeValidator.isValid('8998866200418', ScanKind.ean13), isFalse);
    });

    test('setiap salah baca satu digit pada EAN-13 selalu ditolak', () {
      const good = '8998866200318';
      for (var i = 0; i < good.length; i++) {
        for (var d = 0; d < 10; d++) {
          if (good[i] == '$d') continue;
          final bad = good.replaceRange(i, i + 1, '$d');
          expect(
            BarcodeValidator.isValid(bad, ScanKind.ean13),
            isFalse,
            reason: bad,
          );
        }
      }
    });

    test('panjang salah atau bukan angka ditolak', () {
      expect(BarcodeValidator.isValid('899886620031', ScanKind.ean13), isFalse);
      expect(BarcodeValidator.isValid('89988662003A8', ScanKind.ean13), isFalse);
      expect(BarcodeValidator.isValid('', ScanKind.ean13), isFalse);
    });

    test('EAN-8, UPC-A, UPC-E', () {
      expect(BarcodeValidator.isValid('96385074', ScanKind.ean8), isTrue);
      expect(BarcodeValidator.isValid('96385075', ScanKind.ean8), isFalse);
      expect(BarcodeValidator.isValid('036000291452', ScanKind.upcA), isTrue);
      expect(BarcodeValidator.isValid('036000291453', ScanKind.upcA), isFalse);
      // UPC-E 04252614 = UPC-A 042100005264
      expect(BarcodeValidator.isValid('04252614', ScanKind.upcE), isTrue);
      expect(BarcodeValidator.isValid('04252615', ScanKind.upcE), isFalse);
      expect(BarcodeValidator.isValid('425261', ScanKind.upcE), isFalse);
    });

    test('Code 128 dan Code 39: hanya karakter tercetak, tidak kosong', () {
      expect(BarcodeValidator.isValid('ABC-123', ScanKind.code128), isTrue);
      expect(BarcodeValidator.isValid('ABC 123', ScanKind.code39), isFalse);
      expect(BarcodeValidator.isValid('', ScanKind.code128), isFalse);
      expect(BarcodeValidator.isValid('A' * 49, ScanKind.code128), isFalse);
    });

    test('variants: UPC-A 12 digit dan EAN-13 berawalan 0', () {
      expect(
        BarcodeValidator.variants('036000291452'),
        ['036000291452', '0036000291452'],
      );
      expect(
        BarcodeValidator.variants('0036000291452'),
        ['0036000291452', '036000291452'],
      );
      expect(BarcodeValidator.variants(' 8998866200318 '), ['8998866200318']);
    });
  });

  group('ScanConfirmer', () {
    test('kode baru diterima setelah 3 frame beruntun', () {
      final c = ScanConfirmer();
      expect(c.confirm('A', ms(0)), isFalse);
      expect(c.confirm('A', ms(50)), isFalse);
      expect(c.confirm('A', ms(100)), isTrue);
    });

    test('kode berganti mereset hitungan', () {
      final c = ScanConfirmer();
      c.confirm('A', ms(0));
      c.confirm('A', ms(50));
      expect(c.confirm('B', ms(100)), isFalse);
      expect(c.confirm('A', ms(150)), isFalse);
    });

    test('jeda lebih dari 600 ms mereset hitungan', () {
      final c = ScanConfirmer();
      c.confirm('A', ms(0));
      c.confirm('A', ms(50));
      expect(c.confirm('A', ms(800)), isFalse);
    });

    test('bacaan tunggal yang salah tidak pernah lolos', () {
      final c = ScanConfirmer();
      expect(c.confirm('A', ms(0)), isFalse);
      expect(c.confirm('X', ms(30)), isFalse);
      expect(c.confirm('A', ms(60)), isFalse);
      expect(c.confirm('Y', ms(90)), isFalse);
    });
  });
}
