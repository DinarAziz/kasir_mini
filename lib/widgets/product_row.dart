import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/format.dart';
import '../theme/app_theme.dart';

/// Baris produk: nama + kode di kiri, harga + stok di kanan.
/// Dipakai di layar Cari dan Kelola (dengan [showChevron]).
class ProductRow extends StatelessWidget {
  const ProductRow({
    super.key,
    required this.product,
    this.onTap,
    this.showChevron = false,
  });

  final Product product;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                  Text(product.name, style: AppText.sans(15)),
                  const SizedBox(height: 2),
                  Text(
                    product.code ?? 'tanpa barcode',
                    style: AppText.mono(11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatRupiah(product.price), style: AppText.mono(14)),
                const SizedBox(height: 2),
                Text(
                  'stok ${product.stock}',
                  style: AppText.sans(12, color: AppColors.muted),
                ),
              ],
            ),
            if (showChevron)
              SizedBox(
                width: 28,
                child: Text(
                  '›',
                  textAlign: TextAlign.right,
                  style: AppText.sans(24, color: AppColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
