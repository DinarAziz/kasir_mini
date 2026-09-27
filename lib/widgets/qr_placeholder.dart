import 'package:flutter/material.dart';

/// Gambar mirip kode QR untuk simulasi QRIS. Bukan kode QR yang bisa dipindai.
class QrPlaceholder extends StatelessWidget {
  const QrPlaceholder({super.key, this.size = 190});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Contoh kode QRIS, simulasi',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD2D8D2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(size: Size(size, size), painter: _QrPainter()),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  static const _n = 21;

  static bool _finder(int x, int y) =>
      (x < 7 && y < 7) || (x >= _n - 7 && y < 7) || (x < 7 && y >= _n - 7);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _n;
    final paint = Paint()..color = const Color(0xFF111111);
    var seed = 7;
    double next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        bool on;
        if (_finder(x, y)) {
          final fx = x < 7 ? x : (x >= _n - 7 ? x - (_n - 7) : x);
          final fy = y < 7 ? y : (y >= _n - 7 ? y - (_n - 7) : y);
          on =
              fx == 0 ||
              fx == 6 ||
              fy == 0 ||
              fy == 6 ||
              (fx >= 2 && fx <= 4 && fy >= 2 && fy <= 4);
        } else {
          on = next() > 0.52;
        }
        if (on) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
