import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tombol utama (isi warna aksen), tinggi 48, radius 10.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Material(
        color: enabled ? AppColors.accent : AppColors.line,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: AppText.sans(
                15,
                weight: FontWeight.w600,
                color: enabled ? Colors.white : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol sekunder: latar putih, garis tebal.
class OutlineButton2 extends StatelessWidget {
  const OutlineButton2({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.ink,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: width ?? double.infinity,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(color: color, width: 1.5),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: AppText.sans(15, weight: FontWeight.w600, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bar bawah dengan garis di atas, berisi tombol aksi.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(top: false, child: child),
    );
  }
}
