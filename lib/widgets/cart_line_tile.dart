import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/format.dart';
import '../theme/app_theme.dart';

/// Satu baris keranjang: nama, harga, tombol kurang/tambah, subtotal, hapus.
class CartLineTile extends StatelessWidget {
  const CartLineTile({
    super.key,
    required this.product,
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
  });

  final Product product;
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(14, weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRupiah(product.price),
                    style: AppText.mono(12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          _StepButton(
            label: '−',
            semantics: 'Kurangi ${product.name}',
            onTap: onDecrement,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: AppText.mono(15, weight: FontWeight.w500),
            ),
          ),
          _StepButton(
            label: '+',
            semantics: 'Tambah ${product.name}',
            onTap: onIncrement,
          ),
          SizedBox(
            width: 76,
            child: Text(
              formatRupiah(product.price * qty),
              textAlign: TextAlign.right,
              style: AppText.mono(12),
            ),
          ),
          SizedBox(
            width: 44,
            height: 48,
            child: IconButton(
              tooltip: 'Hapus ${product.name}',
              onPressed: onRemove,
              icon: Text('×', style: AppText.sans(20, color: AppColors.muted)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.semantics,
    required this.onTap,
  });

  final String label;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 48,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(label, style: AppText.sans(18)),
            ),
          ),
        ),
      ),
    );
  }
}
