import 'package:flutter/widgets.dart';

import 'app_store.dart';

/// Membagikan [AppStore] ke seluruh widget. Widget yang memanggil
/// [AppScope.of] otomatis dibangun ulang saat data berubah.
class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child})
    : super(notifier: store);

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di atas widget ini.');
    return scope!.notifier!;
  }

  /// Ambil store tanpa ikut mendengarkan perubahan (untuk event handler).
  static AppStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    return scope!.notifier!;
  }
}
