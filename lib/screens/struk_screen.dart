import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../models/sale.dart';
import '../services/format.dart';
import '../services/receipt.dart';
import '../store/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar.dart';
import '../widgets/buttons.dart';
import '../widgets/misc.dart';

/// Layar 5: struk dari snapshot transaksi.
class StrukScreen extends StatelessWidget {
  const StrukScreen({super.key, required this.sale});

  final Sale sale;

  Future<void> _copyForWhatsApp(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: receiptText(sale)));
    if (context.mounted) {
      showMessage(context, 'Teks struk disalin. Tempel di WhatsApp.');
    }
  }

  void _newTransaction(BuildContext context) {
    final store = AppScope.read(context);
    store.selectTab(0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Struk',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.okSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.ok,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pembayaran berhasil',
                      style: AppText.sans(16, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _Receipt(sale: sale),
                  ],
                ),
              ),
            ),
            BottomActionBar(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlineButton2(
                          label: 'Cetak',
                          onPressed: () => showMessage(
                            context,
                            'Struk dikirim ke printer (simulasi)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlineButton2(
                          label: 'Kirim WhatsApp',
                          onPressed: () => _copyForWhatsApp(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: 'Transaksi baru',
                    onPressed: () => _newTransaction(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({required this.sale});

  final Sale sale;

  Widget _row(String l, String r, {bool bold = false}) {
    final style = AppText.mono(
      12,
      weight: bold ? FontWeight.w600 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(l, style: style)),
          const SizedBox(width: 8),
          Text(r, style: style),
        ],
      ),
    );
  }

  Widget _center(String t, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Text(
      t,
      textAlign: TextAlign.center,
      style: AppText.mono(12, weight: bold ? FontWeight.w600 : FontWeight.w400),
    ),
  );

  Widget get _line => const Padding(
    padding: EdgeInsets.symmetric(vertical: 5),
    child: Divider(height: 1, color: AppColors.muted),
  );

  @override
  Widget build(BuildContext context) {
    final cash = sale.method == PaymentMethod.tunai;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.muted),
      ),
      child: Column(
        children: [
          _center(kStoreName, bold: true),
          _center(kStoreAddress),
          _line,
          _row(sale.no, formatJam(sale.time)),
          _row('Kasir', kCashierName),
          _line,
          for (final i in sale.items)
            _row('${i.qty} x ${i.name}', formatAngka(i.subtotal)),
          _line,
          _row('TOTAL', formatAngka(sale.total), bold: true),
          _row('Metode', sale.method.label),
          if (cash) ...[
            _row('Tunai', formatAngka(sale.tendered ?? sale.total)),
            _row('Kembali', formatAngka(sale.change ?? 0)),
          ],
          _line,
          _center('Terima kasih'),
        ],
      ),
    );
  }
}
