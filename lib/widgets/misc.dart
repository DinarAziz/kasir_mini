import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ringkasan dua angka berdampingan (mis. penjualan dan jumlah transaksi).
class StatBox extends StatelessWidget {
  const StatBox({
    super.key,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  Widget _cell(String label, String value) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.sans(12, color: AppColors.muted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppText.mono(20, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _cell(leftLabel, leftValue),
            const VerticalDivider(width: 1, color: AppColors.line),
            _cell(rightLabel, rightValue),
          ],
        ),
      ),
    );
  }
}

/// Teks tengah untuk daftar kosong.
class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppText.sans(14, color: AppColors.muted, height: 1.5),
        ),
      ),
    );
  }
}

/// Kolom cari dengan tepi 1px (aktif: tepi hitam).
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: AppText.sans(14),
      decoration: inputDecoration(hint: hint),
    );
  }
}

/// Dekorasi input seragam: tinggi 48, radius 10, tepi aksen saat fokus.
InputDecoration inputDecoration({String? hint, String? error, Widget? prefix}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.control),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: AppText.sans(14, color: AppColors.muted),
    errorText: error,
    errorStyle: AppText.sans(12, color: AppColors.bad),
    prefix: prefix,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    enabledBorder: border(AppColors.line),
    focusedBorder: border(AppColors.ink, 1.5),
    errorBorder: border(AppColors.bad),
    focusedErrorBorder: border(AppColors.bad, 1.5),
  );
}

void showMessage(BuildContext context, String text) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 1800),
      ),
    );
}
