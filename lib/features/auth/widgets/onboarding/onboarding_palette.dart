import 'package:flutter/material.dart';

/// Onboarding-specific color system.
abstract final class OnboardingPalette {
  static const Color royalBlue = Color(0xFF2563EB);
  static const Color royalBlueLight = Color(0xFF3B82F6);
  static const Color royalBlueDark = Color(0xFF1D4ED8);

  static const Color indigo = Color(0xFF4F46E5);
  static const Color indigoLight = Color(0xFF6366F1);
  static const Color indigoDark = Color(0xFF4338CA);

  static const Color softPurple = Color(0xFF8B5CF6);
  static const Color softPurpleLight = Color(0xFFA78BFA);
  static const Color softPurpleDark = Color(0xFF7C3AED);

  static const Color warmWhite = Color(0xFFFFFBF8);
  static const Color warmWhiteDeep = Color(0xFFF8F4EF);

  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenLight = Color(0xFF34D399);
  static const Color successGreenDark = Color(0xFF059669);

  static const Color starGold = Color(0xFFFBBF24);
  static const Color ink = Color(0xFF1F172A);
  static const Color inkMuted = Color(0xFF64748B);
  static const Color inkSoft = Color(0xFF94A3B8);

  static List<Color> gradientFor(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return const [royalBlue, royalBlueLight];
      case 1:
        return const [indigo, indigoLight];
      case 2:
        return const [softPurple, softPurpleLight];
      case 3:
        return const [successGreen, successGreenLight];
      default:
        return const [royalBlue, royalBlueLight];
    }
  }

  static Color accentFor(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return royalBlue;
      case 1:
        return indigo;
      case 2:
        return softPurple;
      case 3:
        return successGreen;
      default:
        return royalBlue;
    }
  }

  static List<Color> pageBackgroundFor(int pageIndex) {
    final accent = accentFor(pageIndex);
    return [
      warmWhite,
      Color.lerp(warmWhiteDeep, accent, 0.06)!,
      accent.withValues(alpha: 0.05),
    ];
  }
}
