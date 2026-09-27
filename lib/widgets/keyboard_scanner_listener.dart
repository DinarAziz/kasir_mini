import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/barcode_buffer.dart';

/// Menangkap ketikan scanner barcode USB/Bluetooth (mode keyboard/HID).
///
/// Aktif hanya bila layar ini yang sedang tampil paling atas dan tidak ada
/// kolom teks yang fokus. Karakter dikumpulkan oleh [BarcodeBuffer]; saat
/// Enter, kode lengkap dikirim ke [onCode]. Tidak butuh izin khusus.
class KeyboardScannerListener extends StatefulWidget {
  const KeyboardScannerListener({
    super.key,
    required this.onCode,
    required this.child,
  });

  final ValueChanged<String> onCode;
  final Widget child;

  @override
  State<KeyboardScannerListener> createState() =>
      _KeyboardScannerListenerState();
}

class _KeyboardScannerListenerState extends State<KeyboardScannerListener> {
  final _buffer = BarcodeBuffer();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handle);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handle);
    super.dispose();
  }

  bool _textFieldFocused() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _handle(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    // Hanya saat layar ini paling atas (bukan tertutup layar/dialog lain).
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      _buffer.clear();
      return false;
    }
    if (_textFieldFocused()) {
      _buffer.clear();
      return false;
    }
    final now = DateTime.now();
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final code = _buffer.submit(now);
      if (code == null) return false;
      widget.onCode(code);
      return true; // Enter sudah dipakai, jangan diteruskan ke tombol lain.
    }
    final ch = event.character;
    if (ch != null && ch.length == 1 && ch.codeUnitAt(0) >= 0x20) {
      _buffer.addChar(ch, now);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
