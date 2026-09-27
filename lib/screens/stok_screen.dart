import 'package:flutter/material.dart';

import '../constants.dart';
import '../store/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar.dart';
import '../widgets/chips.dart';
import '../widgets/misc.dart';

/// Layar 7: stok, urut dari yang paling sedikit. Filter Semua atau Menipis.
class StokScreen extends StatefulWidget {
  const StokScreen({super.key});

  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> {
  bool _onlyLow = false;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final low = store.lowStock;
    final list = (_onlyLow ? low : store.products).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    return Column(
      children: [
        const AppTopBar(title: 'Stok'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              AppChip(
                label: 'Semua (${store.products.length})',
                selected: !_onlyLow,
                onTap: () => setState(() => _onlyLow = false),
              ),
              const SizedBox(width: 8),
              AppChip(
                label: 'Menipis (${low.length})',
                selected: _onlyLow,
                onTap: () => setState(() => _onlyLow = true),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? EmptyState(
                  _onlyLow
                      ? 'Tidak ada stok menipis.\nSemua produk di atas $kLowStockLimit.'
                      : 'Belum ada produk.\nTambah produk di tab Kelola.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final p = list[i];
                    return Container(
                      constraints: const BoxConstraints(minHeight: 58),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.line),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: AppText.sans(15)),
                                const SizedBox(height: 2),
                                Text(
                                  p.code ?? 'tanpa barcode',
                                  style: AppText.mono(
                                    11,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (p.stock <= kLowStockLimit)
                            Pill.warn('Menipis', width: 70),
                          SizedBox(
                            width: 56,
                            child: Text(
                              '${p.stock}',
                              textAlign: TextAlign.right,
                              style: AppText.mono(18),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
