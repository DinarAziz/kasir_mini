import 'package:flutter/material.dart';

import '../store/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar.dart';
import '../widgets/buttons.dart';
import '../widgets/cart_line_tile.dart';
import '../widgets/chips.dart';
import '../widgets/misc.dart';
import '../services/format.dart';
import '../store/app_store.dart';
import '../widgets/keyboard_scanner_listener.dart';
import 'bayar_screen.dart';
import 'cari_screen.dart';
import 'scan_flow.dart';
import 'scan_screen.dart';

/// Layar 2: kasir. Cari/scan, produk cepat, keranjang, total, tombol Bayar.
class KasirScreen extends StatelessWidget {
  const KasirScreen({super.key});

  void _openCari(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CariScreen()));
  }

  void _openBayar(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BayarScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final quick = store.products.take(6).toList();
    final lines = store.cart;
    final count = store.cartCount;

    return KeyboardScannerListener(
      onCode: (code) => _onKeyboardCode(context, code),
      child: Column(
        children: [
          const AppTopBar(title: 'Kasir'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    onTap: () => _openCari(context),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        'Cari nama atau kode produk',
                        style: AppText.sans(14, color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlineButton2(
                  label: 'Scan',
                  width: 86,
                  onPressed: () => _openScan(context),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SectionLabel('PRODUK CEPAT'),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: quick.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = quick[i];
                final short = p.name.split(' ').take(2).join(' ');
                return AppChip(label: short, onTap: () => _add(context, p.id));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SectionLabel(
                count == 0 ? 'KERANJANG' : 'KERANJANG ($count ITEM)',
              ),
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? const EmptyState(
                    'Keranjang kosong.\nScan barcode atau cari produk untuk mulai.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: lines.length,
                    itemBuilder: (_, i) {
                      final line = lines[i];
                      final p = store.productById(line.productId)!;
                      return CartLineTile(
                        product: p,
                        qty: line.qty,
                        onDecrement: () => store.decrementCart(p.id),
                        onIncrement: () => _add(context, p.id),
                        onRemove: () => store.removeFromCart(p.id),
                      );
                    },
                  ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppText.sans(14, color: AppColors.muted),
                    ),
                    Text(
                      formatRupiah(store.cartTotal),
                      style: AppText.mono(22, weight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Bayar',
                  onPressed: count == 0 ? null : () => _openBayar(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _add(BuildContext context, int productId) {
    final result = AppScope.read(context).addToCart(productId);
    final msg = result.message;
    if (msg != null) showMessage(context, msg);
  }

  void _openScan(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
  }

  /// Kode dari scanner fisik (keyboard): tambah ke keranjang.
  void _onKeyboardCode(BuildContext context, String code) {
    final result = AppScope.read(context).addByCode(code);
    if (result.status == AddStatus.notFound) {
      handleUnknownCode(context, code);
    } else {
      showMessage(
        context,
        result.message ?? 'Terpindai: ${result.product!.name}',
      );
    }
  }
}
