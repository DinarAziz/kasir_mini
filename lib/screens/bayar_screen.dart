import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/sale.dart';
import '../services/format.dart';
import '../store/app_scope.dart';
import '../store/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/misc.dart';
import '../widgets/qr_placeholder.dart';
import 'struk_screen.dart';

/// Layar 4: pembayaran. Tunai (numpad + kembalian), QRIS dan Debit (simulasi).
class BayarScreen extends StatefulWidget {
  const BayarScreen({super.key});

  @override
  State<BayarScreen> createState() => _BayarScreenState();
}

class _BayarScreenState extends State<BayarScreen> {
  PaymentMethod _method = PaymentMethod.tunai;
  int _tendered = 0;

  void _tap(String key, int total) {
    setState(() {
      switch (key) {
        case 'pas':
          _tendered = total;
        case 'del':
          _tendered ~/= 10;
        case '000':
          _tendered = (_tendered * 1000).clamp(0, kMaxTendered);
        default:
          final v = int.parse(key);
          _tendered = key.length > 1
              ? v // chip nominal: 20000, 50000, 100000
              : (_tendered * 10 + v).clamp(0, kMaxTendered);
      }
    });
  }

  void _confirm(AppStore store) {
    try {
      final sale = store.checkout(
        _method,
        tendered: _method == PaymentMethod.tunai ? _tendered : null,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => StrukScreen(sale: sale)),
      );
    } on CheckoutException catch (e) {
      showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final total = store.cartTotal;
    final isCash = _method == PaymentMethod.tunai;
    final canConfirm =
        store.cart.isNotEmpty &&
        (!isCash || (_tendered > 0 && _tendered >= total));
    final label = switch (_method) {
      PaymentMethod.tunai => 'Konfirmasi pembayaran',
      PaymentMethod.qris => 'Simulasikan pembayaran diterima',
      PaymentMethod.debit => 'Simulasikan kartu disetujui',
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Pembayaran',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total tagihan (${store.cartCount} item)',
                      style: AppText.sans(14, color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(total),
                      style: AppText.mono(32, weight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    _MethodTabs(
                      selected: _method,
                      onSelect: (m) => setState(() => _method = m),
                    ),
                    const SizedBox(height: 16),
                    if (isCash)
                      _CashPanel(
                        total: total,
                        tendered: _tendered,
                        onKey: (k) => _tap(k, total),
                      )
                    else
                      _SimulationPanel(method: _method),
                  ],
                ),
              ),
            ),
            BottomActionBar(
              child: PrimaryButton(
                label: label,
                onPressed: canConfirm ? () => _confirm(store) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTabs extends StatelessWidget {
  const _MethodTabs({required this.selected, required this.onSelect});

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final m in PaymentMethod.values)
            Expanded(
              child: Material(
                color: m == selected ? AppColors.ink : Colors.white,
                child: InkWell(
                  onTap: () => onSelect(m),
                  child: Center(
                    child: Text(
                      m.label,
                      style: AppText.sans(
                        15,
                        weight: FontWeight.w600,
                        color: m == selected ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CashPanel extends StatelessWidget {
  const _CashPanel({
    required this.total,
    required this.tendered,
    required this.onKey,
  });

  final int total;
  final int tendered;
  final ValueChanged<String> onKey;

  static const _keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '000',
    '0',
    'del',
  ];
  static const _quick = [
    ('pas', 'Uang pas'),
    ('20000', '20.000'),
    ('50000', '50.000'),
    ('100000', '100.000'),
  ];

  @override
  Widget build(BuildContext context) {
    final enough = tendered >= total;
    final Color fg;
    final Color bg;
    final String status;
    if (tendered == 0) {
      fg = AppColors.muted;
      bg = AppColors.soft;
      status = 'Masukkan uang yang diterima';
    } else if (enough) {
      fg = AppColors.ok;
      bg = AppColors.okSoft;
      status = 'Kembalian ${formatRupiah(tendered - total)}';
    } else {
      fg = AppColors.warn;
      bg = AppColors.warnSoft;
      status = 'Kurang ${formatRupiah(total - tendered)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 6),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.ink)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Uang diterima',
                style: AppText.sans(14, color: AppColors.muted),
              ),
              Text(
                formatRupiah(tendered),
                style: AppText.mono(22, weight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < _quick.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: AppChip(
                  label: _quick[i].$2,
                  fontSize: 13,
                  padding: 4,
                  onTap: () => onKey(_quick[i].$1),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 114 / 48,
          children: [
            for (final k in _keys) _NumKey(label: k, onTap: () => onKey(k)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Text(
            status,
            style: AppText.sans(15, weight: FontWeight.w600, color: fg),
          ),
        ),
      ],
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDel = label == 'del';
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        onTap: onTap,
        child: Semantics(
          button: true,
          label: isDel ? 'Hapus' : label,
          child: Center(
            child: Text(
              isDel ? '⌫' : label,
              style: AppText.sans(17, weight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

/// QRIS dan Debit hanya simulasi, bukan integrasi pembayaran asli.
class _SimulationPanel extends StatelessWidget {
  const _SimulationPanel({required this.method});

  final PaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final isQris = method == PaymentMethod.qris;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warnSoft,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Text(
            'SIMULASI. Aplikasi ini belum terhubung ke ${isQris ? 'QRIS' : 'mesin EDC'} asli. '
            'Tombol di bawah hanya mencatat transaksi.',
            style: AppText.sans(
              13,
              weight: FontWeight.w500,
              color: AppColors.warn,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (isQris) ...[
          const QrPlaceholder(size: 190),
          const SizedBox(height: 16),
          Text(
            'Minta pelanggan memindai kode QR.\nMenunggu pembayaran...',
            textAlign: TextAlign.center,
            style: AppText.sans(14, color: AppColors.muted, height: 1.5),
          ),
        ] else ...[
          const SizedBox(height: 24),
          Text(
            'Minta pelanggan menempelkan atau menggesek kartu di mesin EDC.',
            textAlign: TextAlign.center,
            style: AppText.sans(14, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          Pill.info('Menunggu kartu'),
        ],
      ],
    );
  }
}
