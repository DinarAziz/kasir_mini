import 'package:flutter/material.dart';

import '../widgets/unknown_code_sheet.dart';
import 'form_produk_screen.dart';

/// Dipanggil saat kode hasil scan tidak ada di daftar produk: tampilkan
/// sheet (layar 13), dan bila dipilih buka Form produk dengan kode terisi.
Future<void> handleUnknownCode(BuildContext context, String code) async {
  final add = await showUnknownCodeSheet(context, code);
  if (add && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FormProdukScreen(initialCode: code)),
    );
  }
}
