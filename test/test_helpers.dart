import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_mini/models/app_data.dart';
import 'package:kasir_mini/services/storage_service.dart';
import 'package:kasir_mini/store/app_store.dart';

/// Penyimpanan di memori untuk tes.
class MemoryStorage implements Storage {
  MemoryStorage([this.data]);
  AppData? data;
  int saveCount = 0;

  @override
  Future<AppData?> load() async => data;

  @override
  Future<void> save(AppData d) async {
    data = d;
    saveCount++;
  }
}

final testNow = DateTime(2026, 9, 21, 16, 5);

/// Store berisi data contoh dengan jam tetap.
AppStore makeStore({MemoryStorage? storage}) => AppStore(
  storage: storage ?? MemoryStorage(),
  data: AppData.seed(testNow),
  clock: () => testNow,
);

/// Memuat font IBM Plex dari assets supaya lebar teks di tes sama dengan di HP
/// (tanpa ini flutter_test memakai font kotak "Ahem" yang jauh lebih lebar).
Future<void> loadAppFonts() async {
  const files = {
    'IBM Plex Sans': [
      'IBMPlexSans-Regular.ttf',
      'IBMPlexSans-Medium.ttf',
      'IBMPlexSans-SemiBold.ttf',
    ],
    'IBM Plex Mono': ['IBMPlexMono-Regular.ttf', 'IBMPlexMono-Medium.ttf'],
  };
  for (final entry in files.entries) {
    final loader = FontLoader(entry.key);
    for (final f in entry.value) {
      loader.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await loader.load();
  }
}

/// Clipboard palsu untuk tes widget. [text] adalah isi clipboard saat ini.
class FakeClipboard {
  String? text;

  void install(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          text = (call.arguments as Map)['text'] as String?;
          return null;
        }
        if (call.method == 'Clipboard.getData') {
          return text == null ? null : <String, dynamic>{'text': text};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }
}
