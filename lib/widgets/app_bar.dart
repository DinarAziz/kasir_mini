import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bilah judul layar: judul 18/600, garis bawah, tombol kembali opsional.
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.title, this.onBack, this.trailing});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.only(left: onBack == null ? 16 : 4, right: 16),
      child: Row(
        children: [
          if (onBack != null)
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                tooltip: 'Kembali',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: AppColors.ink),
              ),
            ),
          Expanded(
            child: Text(
              title,
              style: AppText.sans(18, weight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
