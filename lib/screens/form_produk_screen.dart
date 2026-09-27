import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../services/format.dart';
import '../services/product_validator.dart';
import '../store/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar.dart';
import '../widgets/buttons.dart';
import '../widgets/misc.dart';
import '../widgets/thousands_formatter.dart';
import 'scan_screen.dart';

/// Layar 9: form tambah atau ubah produk. [product] null berarti tambah baru;
/// [initialCode] mengisi kolom kode (dari layar "Kode belum terdaftar").
class FormProdukScreen extends StatefulWidget {
  const FormProdukScreen({super.key, this.product, this.initialCode});

  final Product? product;
  final String? initialCode;

  @override
  State<FormProdukScreen> createState() => _FormProdukScreenState();
}

class _FormProdukScreenState extends State<FormProdukScreen> {
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _code = TextEditingController(
    text: widget.product?.code ?? widget.initialCode ?? '',
  );
  late final _price = TextEditingController(
    text: widget.product == null ? '' : formatAngka(widget.product!.price),
  );
  late final _stock = TextEditingController(
    text: widget.product == null ? '' : '${widget.product!.stock}',
  );
  ProductFormResult? _errors;

  bool get _editing => widget.product != null;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  void _save() {
    final store = AppScope.read(context);
    final result = ProductValidator.validate(
      name: _name.text,
      code: _code.text,
      price: _price.text,
      stock: _stock.text,
      existing: store.products,
      id: widget.product?.id ?? store.nextProductId,
      editingId: widget.product?.id,
    );
    if (!result.isValid) {
      setState(() => _errors = result);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (_editing) {
      store.updateProduct(result.product!);
    } else {
      store.addProduct(result.product!);
    }
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Produk "${result.product!.name}" disimpan')),
      );
  }

  Future<void> _delete() async {
    final store = AppScope.read(context);
    final p = widget.product!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Hapus produk?',
          style: AppText.sans(18, weight: FontWeight.w600),
        ),
        content: Text(
          '"${p.name}" akan dihapus dari daftar produk. '
          'Riwayat transaksi lama tidak berubah.',
          style: AppText.sans(14, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlineButton2(
                  label: 'Batal',
                  onPressed: () => Navigator.pop(ctx, false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlineButton2(
                  label: 'Hapus',
                  color: AppColors.bad,
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    store.deleteProduct(p.id);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Produk "${p.name}" dihapus')));
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: AppText.label),
  );

  @override
  Widget build(BuildContext context) {
    final e = _errors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: _editing ? 'Ubah produk' : 'Tambah produk',
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
                    _label('NAMA PRODUK'),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: AppText.sans(15),
                      decoration: inputDecoration(error: e?.nameError),
                    ),
                    const SizedBox(height: 20),
                    _label('KODE BARCODE'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _code,
                            textInputAction: TextInputAction.next,
                            style: AppText.mono(15),
                            decoration: inputDecoration(error: e?.codeError),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlineButton2(
                          label: 'Scan',
                          width: 60,
                          onPressed: _scan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kosongkan jika produk tanpa barcode. Scanner USB '
                      'atau Bluetooth juga bisa mengisi kolom ini.',
                      style: AppText.sans(
                        12,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('HARGA JUAL'),
                    TextField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [ThousandsFormatter()],
                      style: AppText.mono(15),
                      decoration: inputDecoration(
                        error: e?.priceError,
                        prefix: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            'Rp',
                            style: AppText.sans(14, color: AppColors.muted),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('STOK'),
                    TextField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppText.mono(15),
                      decoration: inputDecoration(error: e?.stockError),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stok 10 ke bawah ditandai Menipis.',
                      style: AppText.sans(12, color: AppColors.muted),
                    ),
                    if (_editing) ...[
                      const SizedBox(height: 32),
                      OutlineButton2(
                        label: 'Hapus produk',
                        color: AppColors.bad,
                        onPressed: _delete,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            BottomActionBar(
              child: PrimaryButton(label: 'Simpan produk', onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanScreen(mode: ScanMode.once)),
    );
    if (code != null && mounted) setState(() => _code.text = code);
  }
}
