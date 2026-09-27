import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/barcode_validator.dart';
import '../services/scan_confirmer.dart';
import '../services/scan_debouncer.dart';
import '../store/app_scope.dart';
import '../store/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import 'scan_flow.dart';

/// [repeat]: kamera tetap terbuka, tiap kode masuk keranjang (layar Kasir).
/// [once]: baca satu kode lalu tutup dan kembalikan kodenya (Form produk).
enum ScanMode { repeat, once }

/// Layar 10: scan barcode dengan kamera.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.mode = ScanMode.repeat});

  final ScanMode mode;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanEntry {
  _ScanEntry(this.productId, this.name, this.problem);

  final int productId;
  final String name;

  /// Null bila berhasil ditambahkan; selain itu pesan seperti "Stok habis".
  final String? problem;
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
    ],
    // Semua frame diperiksa sendiri (konfirmasi beberapa frame), bukan
    // dibatasi plugin.
    detectionSpeed: DetectionSpeed.unrestricted,
    // Resolusi lebih tinggi membuat garis barcode kecil tetap terbaca.
    cameraResolution: const Size(1280, 720),
    autoZoom: true,
  );
  final _confirmer = ScanConfirmer();
  final _debouncer = ScanDebouncer();
  final List<_ScanEntry> _entries = [];
  final _hint = ValueNotifier<String?>(null);
  bool _busy = false; // true selama sheet/form terbuka atau layar sudah ditutup

  @override
  void dispose() {
    _hint.dispose();
    _controller.dispose();
    super.dispose();
  }

  static ScanKind? _kindOf(BarcodeFormat f) => switch (f) {
    BarcodeFormat.ean13 => ScanKind.ean13,
    BarcodeFormat.ean8 => ScanKind.ean8,
    BarcodeFormat.upcA => ScanKind.upcA,
    BarcodeFormat.upcE => ScanKind.upcE,
    BarcodeFormat.code128 => ScanKind.code128,
    BarcodeFormat.code39 => ScanKind.code39,
    _ => null,
  };

  /// Kode sah dalam satu frame. Kosong bila tidak ada; [ambiguous] bila ada
  /// lebih dari satu kode berbeda (jangan menebak mana yang dimaksud).
  static ({String? code, bool ambiguous, bool rejected}) _pick(
    BarcodeCapture capture,
  ) {
    final valid = <String>{};
    var rejected = false;
    for (final b in capture.barcodes) {
      final raw = b.rawValue?.trim();
      final kind = _kindOf(b.format);
      if (raw == null || raw.isEmpty || kind == null) continue;
      if (BarcodeValidator.isValid(raw, kind)) {
        valid.add(raw);
      } else {
        rejected = true;
      }
    }
    return (
      code: valid.length == 1 ? valid.first : null,
      ambiguous: valid.length > 1,
      rejected: valid.isEmpty && rejected,
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final pick = _pick(capture);
    final code = pick.code;
    if (code == null) {
      _confirmer.reset();
      if (pick.ambiguous) {
        _hint.value = 'Ada beberapa barcode. Arahkan ke satu barcode saja.';
      } else if (pick.rejected) {
        _hint.value = 'Barcode kurang jelas. Tahan stabil dan dekatkan.';
      }
      return;
    }
    final now = DateTime.now();
    if (!_confirmer.confirm(code, now)) {
      _hint.value = 'Menahan... jangan gerakkan kamera.';
      return;
    }
    _hint.value = null;
    if (!_debouncer.accept(code, now)) return;

    if (widget.mode == ScanMode.once) {
      _busy = true;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(code);
      return;
    }

    final store = AppScope.read(context);
    final result = store.addByCode(code);
    if (result.status == AddStatus.notFound) {
      _busy = true;
      HapticFeedback.mediumImpact();
      await handleUnknownCode(context, code);
      // Kamera mungkin masih mengarah ke kode yang sama: jangan buka sheet lagi.
      _debouncer.accept(code, DateTime.now());
      _confirmer.reset();
      _busy = false;
      return;
    }
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() {
      final p = result.product!;
      _entries.removeWhere((e) => e.productId == p.id);
      _entries.insert(0, _ScanEntry(p.id, p.name, result.message));
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final repeat = widget.mode == ScanMode.repeat;
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, box) {
          // Hanya barcode di dalam kotak bidik yang dibaca, jadi barcode
          // lain di pinggir frame tidak ikut terbaca.
          final window = Rect.fromCenter(
            center: Offset(box.maxWidth / 2, box.maxHeight * 0.33),
            width: box.maxWidth * 0.8,
            height: 170,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                scanWindow: window,
                errorBuilder: (context, error) => _CameraError(error: error),
              ),
              Positioned.fromRect(
                rect: window,
                child: const IgnorePointer(child: _Viewfinder()),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: window.bottom + 16,
                child: IgnorePointer(child: _Hint(hint: _hint)),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _TopBar(controller: _controller),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _Sheet(
                  repeat: repeat,
                  entries: _entries,
                  store: store,
                  onDone: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.black45,
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Tutup',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'Scan barcode',
              style: AppText.sans(
                18,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, _) {
              final on = state.torchState == TorchState.on;
              return TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
                onPressed: state.torchState == TorchState.unavailable
                    ? null
                    : controller.toggleTorch,
                child: Text(
                  'Senter',
                  style:
                      AppText.sans(
                        14,
                        weight: FontWeight.w500,
                        color: on ? AppColors.accentSoft : Colors.white,
                      ).copyWith(
                        decoration: on ? TextDecoration.underline : null,
                        decorationColor: Colors.white,
                      ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Sudut bidik dan garis pindai; mengisi kotak baca ([scanWindow]).
class _Viewfinder extends StatelessWidget {
  const _Viewfinder();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _CornerPainter());
}

/// Petunjuk di bawah kotak bidik; berubah sesuai kondisi bacaan.
class _Hint extends StatelessWidget {
  const _Hint({required this.hint});

  final ValueNotifier<String?> hint;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: hint,
      builder: (context, text, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text ?? 'Arahkan barcode ke dalam kotak',
            textAlign: TextAlign.center,
            style: AppText.sans(
              14,
              weight: FontWeight.w500,
              color: text == null ? Colors.white : AppColors.accentSoft,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Jarak sekitar 10-20 cm. Tahan sampai terbaca.',
            textAlign: TextAlign.center,
            style: AppText.sans(12, color: const Color(0xFF9AA6A0)),
          ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final corner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, 0)
        ..lineTo(len, 0)
        ..moveTo(w - len, 0)
        ..lineTo(w, 0)
        ..lineTo(w, len)
        ..moveTo(w, h - len)
        ..lineTo(w, h)
        ..lineTo(w - len, h)
        ..moveTo(len, h)
        ..lineTo(0, h)
        ..lineTo(0, h - len),
      corner,
    );
    canvas.drawLine(
      Offset(10, h / 2),
      Offset(w - 10, h / 2),
      Paint()
        ..color = const Color(0xFF4FC0CC)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.repeat,
    required this.entries,
    required this.store,
    required this.onDone,
  });

  final bool repeat;
  final List<_ScanEntry> entries;
  final AppStore store;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (repeat) ...[
              const SectionLabel('TERAKHIR DIPINDAI'),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 132,
                  minHeight: 56,
                ),
                child: entries.isEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Belum ada kode dipindai.',
                          style: AppText.sans(14, color: AppColors.muted),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: entries.length,
                        itemBuilder: (_, i) => _EntryRow(
                          entry: entries[i],
                          qtyInCart: store.qtyInCart(entries[i].productId),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Selesai (${store.cartCount} item)',
                onPressed: onDone,
              ),
            ] else ...[
              Text(
                'Kode akan terisi otomatis setelah terbaca.',
                style: AppText.sans(14, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              OutlineButton2(label: 'Batal', onPressed: onDone),
            ],
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.qtyInCart});

  final _ScanEntry entry;
  final int qtyInCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.name,
                  style: AppText.sans(15, weight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Di keranjang: $qtyInCart',
                  style: AppText.sans(12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          entry.problem == null
              ? Pill.ok('Ditambahkan')
              : Pill.warn(entry.problem!),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            denied
                ? 'Izin kamera ditolak.\nBuka Pengaturan > Aplikasi > Kasir Mini > Izin, lalu aktifkan Kamera.\nAnda tetap bisa mencari produk atau memakai scanner keyboard.'
                : 'Kamera tidak bisa dibuka.\nCoba tutup layar ini dan buka lagi.',
            textAlign: TextAlign.center,
            style: AppText.sans(14, color: Colors.white, height: 1.5),
          ),
        ),
      ),
    );
  }
}
