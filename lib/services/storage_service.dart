import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_data.dart';

/// Tempat menyimpan [AppData]. Dibuat abstrak supaya mudah diganti di tes.
abstract class Storage {
  /// Mengembalikan null bila belum ada data tersimpan.
  Future<AppData?> load();
  Future<void> save(AppData data);
}

/// Menyimpan seluruh data sebagai satu JSON di shared_preferences.
class PrefsStorage implements Storage {
  static const key = 'kasir_mini_data';

  @override
  Future<AppData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(key);
    if (text == null) return null;
    final json = jsonDecode(text);
    if (json is! Map) throw const FormatException('Data tersimpan rusak.');
    final last = json['lastBackupAt'];
    return AppData.fromJson(
      json,
      lastBackupAt: last is String ? DateTime.tryParse(last) : null,
    );
  }

  @override
  Future<void> save(AppData data) async {
    final prefs = await SharedPreferences.getInstance();
    final json = data.toJson()
      ..['lastBackupAt'] = data.lastBackupAt?.toIso8601String();
    await prefs.setString(key, jsonEncode(json));
  }
}
