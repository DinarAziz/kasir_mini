import 'package:flutter/material.dart';

import '../store/app_scope.dart';
import '../store/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar.dart';
import '../widgets/buttons.dart';
import '../widgets/misc.dart';
import '../widgets/product_row.dart';

/// Layar 3: cari produk. Menyaring sambil mengetik.
/// Enter dengan kode yang persis cocok langsung menambah produk (scanner keyboard).
class CariScreen extends StatefulWidget {
  const CariScreen({super.key});

  @override
  State<CariScreen> createState() => _CariScreenState();
}

class _CariScreenState extends State<CariScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(int productId) {
    final store = AppScope.read(context);
    final result = store.addToCart(productId);
    showMessage(
      context,
      result.message ?? 'Ditambahkan: ${result.product!.name}',
    );
  }

  void _submit(String text) {
    final store = AppScope.read(context);
    final code = text.trim();
    if (code.isNotEmpty && store.productByCode(code) != null) {
      final result = store.addByCode(code);
      showMessage(
        context,
        result.message ?? 'Ditambahkan: ${result.product!.name}',
      );
      setState(_controller.clear);
    }
    // Fokus dipertahankan agar scan berikutnya bisa langsung masuk.
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final query = _controller.text;
    final results = store.search(query);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Cari produk',
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SearchField(
                hint: 'Ketik nama atau kode',
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: _submit,
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? EmptyState(
                      'Produk "${query.trim()}" tidak ditemukan.\nPeriksa ejaan atau coba kode barcode.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: results.length,
                      itemBuilder: (_, i) => ProductRow(
                        product: results[i],
                        onTap: () => _add(results[i].id),
                      ),
                    ),
            ),
            _CartShortcut(store: store),
          ],
        ),
      ),
    );
  }
}

class _CartShortcut extends StatelessWidget {
  const _CartShortcut({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.all(12).copyWith(left: 16, right: 16),
      child: PrimaryButton(
        label: 'Lihat keranjang (${store.cartCount} item)',
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
