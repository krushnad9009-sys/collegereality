import 'package:flutter/material.dart';

/// Onboarding-specific color system — teal / sky / emerald (no purple).
abstract final class OnboardingPalette {
  static const Color teal = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color tealDark = Color(0xFF115E59);

  static const Color sky = Color(0xFF0369A1);
  static const Color skyLight = Color(0xFF0EA5E9);
  static const Color skyDark = Color(0xFF075985);

  static const Color slate = Color(0xFF334155);
  static const Color slateLight = Color(0xFF475569);
  static const Color slateDark = Color(0xFF1E293B);

  static const Color coolWhite = Color(0xFFF8FAFC);
  static const Color coolWhiteDeep = Color(0xFFF1F5F9);

  /// Back-compat alias used by existing onboarding widgets.
  static const Color warmWhite = coolWhite;
  static const Color warmWhiteDeep = coolWhiteDeep;

  static const Color successGreen = Color(0xFF059669);
  static const Color successGreenLight = Color(0xFF10B981);
  static const Color successGreenDark = Color(0xFF047857);

  static const Color starGold = Color(0xFFFBBF24);
  static const Color ink = Color(0xFF0F172A);
  static const Color inkMuted = Color(0xFF64748B);
  static const Color inkSoft = Color(0xFF94A3B8);

  /// Back-compat names mapped onto the new palette.
  static const Color royalBlue = teal;
  static const Color royalBlueLight = tealLight;
  static const Color royalBlueDark = tealDark;
  static const Color indigo = sky;
  static const Color indigoLight = skyLight;
  static const Color indigoDark = skyDark;
  static const Color softPurple = slate;
  static const Color softPurpleLight = slateLight;
  static const Color softPurpleDark = slateDark;

  static List<Color> gradientFor(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return const [teal, tealLight];
      case 1:
        return const [sky, skyLight];
      case 2:
        return const [slateDark, slate];
      case 3:
        return const [successGreen, successGreenLight];
      default:
        return const [teal, tealLight];
    }
  }

  static Color accentFor(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return teal;
      case 1:
        return sky;
      case 2:
        return slate;
      case 3:
        return successGreen;
      default:
        return teal;
    }
  }

  static List<Color> pageBackgroundFor(int pageIndex) {
    final accent = accentFor(pageIndex);
    return [
      coolWhite,
      Color.lerp(coolWhiteDeep, accent, 0.07)!,
      accent.withValues(alpha: 0.06),
    ];
  }
}
