import 'package:flutter/material.dart';

import '../store/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/misc.dart';
import '../widgets/product_row.dart';
import 'backup_screen.dart';
import 'form_produk_screen.dart';

/// Layar 8: daftar produk untuk diubah, tombol Tambah produk, link Backup.
class KelolaScreen extends StatefulWidget {
  const KelolaScreen({super.key});

  @override
  State<KelolaScreen> createState() => _KelolaScreenState();
}

class _KelolaScreenState extends State<KelolaScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final list = store.search(_controller.text);
    return Column(
      children: [
        AppTopBar(
          title: 'Kelola',
          trailing: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            onPressed: () => _open(const BackupScreen()),
            child: Text(
              'Backup & Transfer',
              style: AppText.sans(
                14,
                weight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SearchField(
            hint: 'Cari produk',
            controller: _controller,
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SectionLabel(
              '${store.products.length} PRODUK · ${store.lowStock.length} STOK MENIPIS',
            ),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? EmptyState(
                  store.products.isEmpty
                      ? 'Belum ada produk.\nKetuk Tambah produk untuk mulai.'
                      : 'Produk "${_controller.text.trim()}" tidak ditemukan.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => ProductRow(
                    product: list[i],
                    showChevron: true,
                    onTap: () => _open(FormProdukScreen(product: list[i])),
                  ),
                ),
        ),
        BottomActionBar(
          child: PrimaryButton(
            label: 'Tambah produk',
            onPressed: () => _open(const FormProdukScreen()),
          ),
        ),
      ],
    );
  }
}
