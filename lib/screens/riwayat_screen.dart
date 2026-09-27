import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../services/format.dart';
import '../store/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar.dart';
import '../widgets/chips.dart';
import '../widgets/misc.dart';
import 'struk_screen.dart';

/// Layar 6: ringkasan hari ini dan daftar transaksi terbaru.
class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final sales = store.sales;
    return Column(
      children: [
        const AppTopBar(title: 'Riwayat'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: StatBox(
            leftLabel: 'Penjualan hari ini',
            leftValue: formatRupiah(store.todayTotal),
            rightLabel: 'Transaksi',
            rightValue: '${store.todaySales().length}',
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SectionLabel('TRANSAKSI TERBARU'),
          ),
        ),
        Expanded(
          child: sales.isEmpty
              ? const EmptyState(
                  'Belum ada transaksi.\nTransaksi yang selesai muncul di sini.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sales.length,
                  itemBuilder: (_, i) => _SaleRow(sale: sales[i]),
                ),
        ),
      ],
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => StrukScreen(sale: sale))),
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.no,
                    style: AppText.mono(14, weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatJam(sale.time)} · ${sale.items.length} jenis barang',
                    style: AppText.mono(11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            sale.method == PaymentMethod.tunai
                ? Pill.ok(sale.method.label, width: 58)
                : Pill.info(sale.method.label, width: 58),
            SizedBox(
              width: 96,
              child: Text(
                formatRupiah(sale.total),
                textAlign: TextAlign.right,
                style: AppText.mono(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
