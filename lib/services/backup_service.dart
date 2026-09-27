import 'dart:convert';

import '../models/app_data.dart';

/// Pesan error yang aman ditampilkan langsung ke pengguna.
class BackupException implements Exception {
  BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Hasil membaca teks backup yang valid, belum diterapkan ke data aktif.
class BackupPreview {
  BackupPreview({required this.data, required this.exportedAt});

  final AppData data;
  final DateTime exportedAt;

  int get productCount => data.products.length;
  int get transactionCount => data.sales.length;
}

/// Ekspor dan impor backup dalam bentuk teks JSON (lewat clipboard).
class BackupService {
  static const appId = 'kasir-mini';
  static const version = 1;

  /// Membuat teks backup. PIN tidak ikut.
  static String export(AppData data, DateTime now) {
    return jsonEncode({
      'app': appId,
      'version': version,
      'exportedAt': now.toIso8601String(),
      ...data.toJson(),
    });
  }

  /// Memvalidasi [text]. Melempar [BackupException] bila rusak atau versinya
  /// tidak dikenal. Tidak mengubah data apa pun.
  static BackupPreview parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw BackupException('Tidak ada teks untuk dipulihkan.');
    }
    final Object? json;
    try {
      json = jsonDecode(trimmed);
    } on FormatException {
      throw BackupException(
        'Teks bukan data backup yang utuh. Salin ulang seluruh teks backup.',
      );
    }
    if (json is! Map || json['app'] != appId) {
      throw BackupException('Ini bukan data backup Kasir Mini.');
    }
    final v = json['version'];
    if (v != version) {
      throw BackupException(
        'Versi backup ${v ?? '(tidak ada)'} tidak dikenal. Aplikasi ini hanya membaca versi $version.',
      );
    }
    final exported = json['exportedAt'];
    final exportedAt = exported is String ? DateTime.tryParse(exported) : null;
    if (exportedAt == null) {
      throw BackupException('Tanggal backup tidak terbaca. Data backup rusak.');
    }
    try {
      return BackupPreview(
        data: AppData.fromJson(json),
        exportedAt: exportedAt,
      );
    } on FormatException catch (e) {
      throw BackupException('Data backup rusak: ${e.message}');
    }
  }
}
