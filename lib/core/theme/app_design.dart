import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppDesign {
  static const Color violet = Color(0xFF7C3AED);
  static const Color coral = Color(0xFFF43F5E);
  static const Color amber = Color(0xFFF59E0B);

  static List<Color> heroGradient(bool isDark) => isDark
      ? const [
          Color(0xFF0F172A),
          Color(0xFF0F172A),
        ]
      : const [
          Colors.white,
          Colors.white,
        ];

  static BoxDecoration pageBackground(bool isDark) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF0A1118), Color(0xFF101820), Color(0xFF17232D)]
          : const [Color(0xFFF8FBFA), Color(0xFFEAF6F3), Color(0xFFF8FAFC)],
    ),
  );

  static BoxDecoration premiumCard({
    required bool isDark,
    Color? tint,
    double radius = 14,
  }) {
    final accent = tint ?? AppColors.brandTeal;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF17232D),
                Color.lerp(const Color(0xFF17232D), accent, 0.12)!,
              ]
            : [Colors.white, Color.lerp(Colors.white, accent, 0.06)!],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : accent.withValues(alpha: 0.12),
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.22)
              : accent.withValues(alpha: 0.10),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration glassPanel({double radius = 14}) => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.14),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
  );

  static BoxDecoration accentIcon(List<Color> colors) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: colors.first.withValues(alpha: 0.28),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
    ],
  );
}
