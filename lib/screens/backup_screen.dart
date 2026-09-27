import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/backup_service.dart';
import '../services/format.dart';
import '../store/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/misc.dart';

/// Layar 11: backup dan pindah data lewat clipboard (tanpa paket tambahan).
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _paste = TextEditingController();
  String? _error;
  bool _showPasteField = false;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final store = AppScope.read(context);
    final text = store.exportBackup();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _error = null);
    showMessage(
      context,
      'Backup disalin (${store.products.length} produk, ${store.sales.length} transaksi). '
      'Tempel di WhatsApp atau Catatan.',
    );
  }

  /// Membaca clipboard; bila kosong atau rusak, tampilkan pesan dan kolom tempel.
  Future<void> _restoreFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      setState(() {
        _showPasteField = true;
        _error =
            'Clipboard kosong. Salin teks backup dulu, atau tempel di kolom di bawah.';
      });
      return;
    }
    await _validateAndAsk(text);
  }

  Future<void> _validateAndAsk(String text) async {
    final BackupPreview preview;
    try {
      preview = BackupService.parse(text);
    } on BackupException catch (e) {
      setState(() {
        _showPasteField = true;
        _error = '${e.message} Data di HP ini tidak diubah.';
      });
      return;
    }
    setState(() => _error = null);
    final ok = await showRestoreDialog(context, preview);
    if (ok != true || !mounted) return;
    AppScope.read(context).restore(preview);
    setState(() {
      _paste.clear();
      _showPasteField = false;
    });
    showMessage(
      context,
      'Data dipulihkan: ${preview.productCount} produk, ${preview.transactionCount} transaksi.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final last = store.lastBackupAt;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Backup & Transfer',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data toko tersimpan di HP ini.',
                      style: AppText.sans(14, weight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Salin backup, kirim ke HP lain lewat WhatsApp, Catatan, '
                      'atau email, lalu tempel di HP tujuan.',
                      style: AppText.sans(
                        13,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StatBox(
                      leftLabel: 'Produk',
                      leftValue: '${store.products.length}',
                      rightLabel: 'Transaksi',
                      rightValue: '${store.sales.length}',
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Backup terakhir: ${last == null ? 'belum pernah' : formatTanggalJam(last)}',
                      style: AppText.sans(13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('BACKUP'),
                    const SizedBox(height: 12),
                    PrimaryButton(label: 'Salin data backup', onPressed: _copy),
                    const SizedBox(height: 12),
                    Text(
                      'Berisi semua produk, stok, dan riwayat transaksi.',
                      style: AppText.sans(12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 32),
                    const SectionLabel('PULIHKAN'),
                    const SizedBox(height: 12),
                    OutlineButton2(
                      label: 'Tempel & pulihkan data',
                      onPressed: _restoreFromClipboard,
                    ),
                    const SizedBox(height: 12),
                    if (_error != null) ...[
                      _Notice(text: _error!, bad: true),
                      const SizedBox(height: 12),
                    ],
                    if (_showPasteField) ...[
                      TextField(
                        controller: _paste,
                        minLines: 3,
                        maxLines: 6,
                        style: AppText.mono(12),
                        decoration: inputDecoration(
                          hint: 'Tempel teks backup di sini',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlineButton2(
                        label: 'Pulihkan dari teks di atas',
                        onPressed: () => _validateAndAsk(_paste.text),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const _Notice(
                      text:
                          'Memulihkan akan mengganti semua produk dan riwayat di HP ini. '
                          'Salin backup dulu jika ragu.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.bad = false});

  final String text;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bad ? AppColors.badSoft : AppColors.warnSoft,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Text(
        text,
        style: AppText.sans(
          13,
          weight: FontWeight.w500,
          color: bad ? AppColors.bad : AppColors.warn,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Layar 12: dialog konfirmasi pulihkan. Mengembalikan true bila dikonfirmasi.
Future<bool?> showRestoreDialog(BuildContext context, BackupPreview preview) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      titleTextStyle: AppText.sans(18, weight: FontWeight.w600),
      title: const Text('Pulihkan data?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ditemukan ${preview.productCount} produk dan ${preview.transactionCount} transaksi '
            'dari backup ${formatTanggalJam(preview.exportedAt)}.',
            style: AppText.sans(14, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Data di HP ini akan diganti.',
            style: AppText.sans(
              14,
              weight: FontWeight.w600,
              color: AppColors.warn,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      actions: [
        Row(
          children: [
            Expanded(
              flex: 130,
              child: OutlineButton2(
                label: 'Batal',
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 146,
              child: PrimaryButton(
                label: 'Pulihkan',
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
