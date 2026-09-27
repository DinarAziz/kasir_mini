import 'package:flutter/material.dart';

/// Token warna dari desain.
class AppColors {
  static const bg = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B2321);
  static const muted = Color(0xFF5B6762);
  static const line = Color(0xFFD2D8D2);
  static const accent = Color(0xFF0B6E79);
  static const accentSoft = Color(0xFFD5EBEE);
  static const warn = Color(0xFF8F5200);
  static const warnSoft = Color(0xFFFBE9CD);
  static const ok = Color(0xFF1F7A38);
  static const okSoft = Color(0xFFDBF0E0);
  static const bad = Color(0xFFB3261E);
  static const badSoft = Color(0xFFF8DEDB);
  static const soft = Color(0xFFF2F4F1);
  static const disabled = Color(0xFFB9C1BC);
}

/// Radius: tombol/input 10, chip dan pill bulat penuh.
class AppRadius {
  static const double control = 10;
  static const double card = 12;
  static const double full = 999;
}

/// Gaya teks. Angka uang dan kode barcode memakai [mono].
class AppText {
  static const _sans = 'IBM Plex Sans';
  static const _mono = 'IBM Plex Mono';

  static TextStyle sans(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
  }) => TextStyle(
    fontFamily: _sans,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
  }) => TextStyle(
    fontFamily: _mono,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Judul bagian kecil huruf kapital, mis. "PRODUK CEPAT".
  static TextStyle get label => sans(
    12,
    weight: FontWeight.w600,
    color: AppColors.muted,
  ).copyWith(letterSpacing: 0.4);
}

class AppTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.accent,
          onPrimary: Colors.white,
          surface: AppColors.bg,
          onSurface: AppColors.ink,
          error: AppColors.bad,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'IBM Plex Sans',
      scaffoldBackgroundColor: AppColors.bg,
      dividerColor: AppColors.line,
      splashFactory: InkRipple.splashFactory,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.sans(14, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
      ),
    );
  }
}
