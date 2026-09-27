import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Navigasi bawah 4 tab; tab aktif ditandai garis aksen di atas.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const labels = ['Kasir', 'Riwayat', 'Stok', 'Kelola'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelect(i),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (i == index)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: SizedBox(
                              height: 3,
                              child: ColoredBox(color: AppColors.accent),
                            ),
                          ),
                        Text(
                          labels[i],
                          style: AppText.sans(
                            14,
                            weight: FontWeight.w500,
                            color: i == index
                                ? AppColors.accent
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
