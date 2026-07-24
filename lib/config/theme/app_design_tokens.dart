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
    this.cardRadius = 20,
    this.buttonRadius = 14,
    this.chipRadius = 24,
    this.navBarRadius = 24,
  });

  static const light = AppDesignTokens(
    surfaceMuted: Color(0xFFF5F7FB),
    surfaceElevated: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFE5E7EB),
    borderStrong: Color(0xFFD1D5DB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textTertiary: Color(0xFF9CA3AF),
    shimmerBase: Color(0xFFF3F4F6),
    shimmerHighlight: Color(0xFFE5E7EB),
  );

  static const dark = AppDesignTokens(
    surfaceMuted: Color(0xFF111827),
    surfaceElevated: Color(0xFF1F2937),
    borderSubtle: Color(0xFF374151),
    borderStrong: Color(0xFF4B5563),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFFD1D5DB),
    textTertiary: Color(0xFF9CA3AF),
    shimmerBase: Color(0xFF1F2937),
    shimmerHighlight: Color(0xFF374151),
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
