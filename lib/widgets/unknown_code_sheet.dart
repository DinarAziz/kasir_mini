import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'buttons.dart';

/// Layar 13: bottom sheet saat kode hasil scan belum ada di daftar produk.
/// Mengembalikan true bila pengguna memilih "Tambah produk dengan kode ini".
Future<bool> showUnknownCodeSheet(BuildContext context, String code) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Kode belum terdaftar',
              style: AppText.sans(18, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: AppText.sans(13, color: AppColors.muted),
                children: [
                  const TextSpan(text: 'Kode '),
                  TextSpan(
                    text: code,
                    style: AppText.mono(13, color: AppColors.muted),
                  ),
                  const TextSpan(text: ' belum ada di daftar produk.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Tambah produk dengan kode ini',
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 8),
            OutlineButton2(
              label: 'Tutup',
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
