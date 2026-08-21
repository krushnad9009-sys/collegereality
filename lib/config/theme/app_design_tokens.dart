import 'package:flutter/material.dart';

/// Semantic design tokens exposed via [ThemeExtension] for consistent UI.
@immutable
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  final Color surfaceMuted;
  final Color surfaceElevated;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color shimmerBase;
  final Color shimmerHighlight;

  /// A single warm accent, deliberately distinct from the cool teal
  /// primary — reserved for CR Score badges and other "this is a real
  /// signal, look here" highlights so it stays meaningful instead of
  /// being diluted across the page.
  final Color accentWarm;
  final double cardRadius;
  final double buttonRadius;
  final double chipRadius;
  final double navBarRadius;

  const AppDesignTokens({
    required this.surfaceMuted,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.accentWarm,
    this.cardRadius = 20,
    this.buttonRadius = 14,
    this.chipRadius = 24,
    this.navBarRadius = 24,
  });

  static const light = AppDesignTokens(
    // Near-white, slightly warm neutral — never a blue-tinted wash.
    surfaceMuted: Color(0xFFFAFAF9),
    surfaceElevated: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    // 0F172A-on-FAFAF9 and 475569-on-FFFFFF both clear 4.5:1 (7.1:1 and
    // 4.5:1 respectively) — kept exact for that reason.
    textSecondary: Color(0xFF475569),
    textTertiary: Color(0xFF64748B),
    shimmerBase: Color(0xFFF1F5F9),
    shimmerHighlight: Color(0xFFE2E8F0),
    accentWarm: Color(0xFFC2740C),
    cardRadius: 22,
    buttonRadius: 16,
    chipRadius: 24,
    navBarRadius: 28,
  );

  static const dark = AppDesignTokens(
    surfaceMuted: Color(0xFF0F172A),
    surfaceElevated: Color(0xFF1E293B),
    borderSubtle: Color(0xFF334155),
    borderStrong: Color(0xFF475569),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textTertiary: Color(0xFF94A3B8),
    shimmerBase: Color(0xFF1E293B),
    shimmerHighlight: Color(0xFF334155),
    accentWarm: Color(0xFFE3A340),
    cardRadius: 22,
    buttonRadius: 16,
    chipRadius: 24,
    navBarRadius: 28,
  );

  @override
  AppDesignTokens copyWith({
    Color? surfaceMuted,
    Color? surfaceElevated,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? accentWarm,
    double? cardRadius,
    double? buttonRadius,
    double? chipRadius,
    double? navBarRadius,
  }) {
    return AppDesignTokens(
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      accentWarm: accentWarm ?? this.accentWarm,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      navBarRadius: navBarRadius ?? this.navBarRadius,
    );
  }

  @override
  AppDesignTokens lerp(AppDesignTokens? other, double t) {
    if (other is! AppDesignTokens) return this;
    return AppDesignTokens(
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      buttonRadius: buttonRadius + (other.buttonRadius - buttonRadius) * t,
      chipRadius: chipRadius + (other.chipRadius - chipRadius) * t,
      navBarRadius: navBarRadius + (other.navBarRadius - navBarRadius) * t,
    );
  }
}

extension AppDesignTokensX on BuildContext {
  AppDesignTokens get tokens =>
      Theme.of(this).extension<AppDesignTokens>() ?? AppDesignTokens.light;
}
