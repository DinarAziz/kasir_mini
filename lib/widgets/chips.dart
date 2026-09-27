import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Chip bulat penuh, tinggi 38 (area sentuh dilebarkan ke 48).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.fontSize = 14,
    this.padding = 16,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final double fontSize;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      highlightShape: BoxShape.rectangle,
      containedInkWell: true,
      radius: 30,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(
          child: Container(
            height: 38,
            padding: EdgeInsets.symmetric(horizontal: padding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.accentSoft : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.line,
              ),
            ),
            child: Text(
              label,
              style: AppText.sans(
                fontSize,
                weight: FontWeight.w500,
                color: selected ? AppColors.accent : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Label status kecil (mis. "Menipis", "Tunai").
class Pill extends StatelessWidget {
  const Pill(
    this.label, {
    super.key,
    required this.fg,
    required this.bg,
    this.width,
  });

  final String label;
  final Color fg;
  final Color bg;
  final double? width;

  factory Pill.ok(String label, {double? width}) =>
      Pill(label, fg: AppColors.ok, bg: AppColors.okSoft, width: width);
  factory Pill.warn(String label, {double? width}) =>
      Pill(label, fg: AppColors.warn, bg: AppColors.warnSoft, width: width);
  factory Pill.info(String label, {double? width}) =>
      Pill(label, fg: AppColors.accent, bg: AppColors.accentSoft, width: width);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppText.sans(12, weight: FontWeight.w600, color: fg),
      ),
    );
  }
}

/// Judul bagian huruf kapital kecil.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: AppText.label);
}
