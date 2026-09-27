import 'package:flutter/material.dart';

import '../store/app_scope.dart';
import '../widgets/bottom_nav.dart';
import 'kasir_screen.dart';
import 'kelola_screen.dart';
import 'riwayat_screen.dart';
import 'stok_screen.dart';

/// Kerangka utama: 4 tab (Kasir, Riwayat, Stok, Kelola) dan navigasi bawah.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    const tabs = <Widget>[
      KasirScreen(),
      RiwayatScreen(),
      StokScreen(),
      KelolaScreen(),
    ];
    return Scaffold(
      body: SafeArea(bottom: false, child: tabs[store.tabIndex]),
      bottomNavigationBar: AppBottomNav(
        index: store.tabIndex,
        onSelect: store.selectTab,
      ),
    );
  }
}
