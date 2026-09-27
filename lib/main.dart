import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'services/storage_service.dart';
import 'store/app_scope.dart';
import 'store/app_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppStore.open(PrefsStorage());
  runApp(KasirMiniApp(store: store));
}

class KasirMiniApp extends StatelessWidget {
  const KasirMiniApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      child: MaterialApp(
        title: 'Kasir Mini',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );
  }
}
