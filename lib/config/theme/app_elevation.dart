import 'package:flutter/material.dart';

/// Elevation / shadow tokens for a premium layered UI.
abstract final class AppElevation {
  static List<BoxShadow> get none => const [];

  static List<BoxShadow> soft(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.07),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> medium(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.12),
          blurRadius: 32,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> floating(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.16),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> navBar(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

/// Motion durations and curves used across transitions and micro-interactions.
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration breathe = Duration(milliseconds: 3400);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
}
