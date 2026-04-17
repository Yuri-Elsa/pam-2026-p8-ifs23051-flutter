// lib/shared/widgets/app_snackbar.dart

import 'package:flutter/material.dart';

enum SnackBarType { success, error, info, warning }

void showAppSnackBar(
    BuildContext context, {
      required String message,
      SnackBarType type = SnackBarType.info,
    }) {
  // Nebula-themed snackbar colors
  final configs = {
    SnackBarType.success: (
    const Color(0xFF065F46),   // bg dark
    const Color(0xFF34D399),   // icon/text color
    const Color(0xFFD1FAE5),   // bg light
    Icons.check_circle_rounded
    ),
    SnackBarType.error: (
    const Color(0xFF7F1D1D),
    const Color(0xFFF87171),
    const Color(0xFFFEE2E2),
    Icons.error_rounded
    ),
    SnackBarType.warning: (
    const Color(0xFF78350F),
    const Color(0xFFFBBF24),
    const Color(0xFFFEF3C7),
    Icons.warning_rounded
    ),
    SnackBarType.info: (
    const Color(0xFF1E1B4B),
    const Color(0xFFA78BFA),
    const Color(0xFFEDE9FE),
    Icons.info_rounded
    ),
  };

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final (darkBg, accentColor, lightBg, icon) = configs[type]!;

  final bgColor = isDark ? darkBg.withOpacity(0.95) : lightBg;
  final textColor = isDark ? accentColor : darkBg;
  final iconColor = isDark ? accentColor : darkBg;

  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accentColor.withOpacity(0.3)),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => messenger.hideCurrentSnackBar(),
              child: Icon(Icons.close_rounded, color: iconColor, size: 18),
            ),
          ],
        ),
      ),
    );
}