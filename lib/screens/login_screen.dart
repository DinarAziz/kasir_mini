import 'package:flutter/material.dart';

import '../constants.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

/// Layar 1: masuk dengan PIN 4 digit.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  String _error = '';

  void _press(String key) {
    setState(() {
      _error = '';
      if (key == 'del') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
        return;
      }
      if (_pin.length < kAppPin.length) _pin += key;
    });
    if (_pin.length == kAppPin.length) _check();
  }

  void _check() {
    if (_pin == kAppPin) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } else {
      setState(() {
        _pin = '';
        _error = 'PIN salah. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Logo(),
                      const SizedBox(height: 28),
                      Text(
                        'Kasir Mini',
                        style: AppText.sans(22, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Masukkan PIN kasir',
                        style: AppText.sans(14, color: AppColors.muted),
                      ),
                      const SizedBox(height: 24),
                      _Dots(filled: _pin.length),
                      SizedBox(
                        height: 32,
                        child: Center(
                          child: Text(
                            _error,
                            style: AppText.sans(13, color: AppColors.bad),
                          ),
                        ),
                      ),
                      _Keypad(onKey: _press),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                '$kStoreNameTitle (contoh) · $kShiftName',
                style: AppText.sans(12, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < kAppPin.length; i++)
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? AppColors.ink : Colors.transparent,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
          ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});

  final ValueChanged<String> onKey;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final k in row)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: k.isEmpty
                        ? const SizedBox(width: 76, height: 56)
                        : _Key(label: k, onTap: () => onKey(k)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDel = label == 'del';
    return SizedBox(
      width: 76,
      height: 56,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onTap,
          child: Semantics(
            button: true,
            label: isDel ? 'Hapus' : label,
            child: Center(
              child: Text(
                isDel ? '⌫' : label,
                style: AppText.sans(20, weight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
