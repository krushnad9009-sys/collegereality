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

  /// Cool accent for verification status and "trust" badges (electric
  /// indigo). Pairs with [accentWarm]: gold for ratings, indigo for
  /// verified/status.
  final Color accentCool;

  /// Weight for headings/titles. Legacy is heavy (w800); the premium theme
  /// uses a crisper SemiBold.
  final FontWeight headingWeight;

  /// Weight for body/supporting copy. Legacy is Medium (w500); the premium
  /// theme uses Regular.
  final FontWeight bodyWeight;

  /// Resting / hover shadow for cards. Null keeps each widget's own legacy
  /// shadow, so screens that don't opt in are untouched.
  final List<BoxShadow>? cardShadow;
  final List<BoxShadow>? cardShadowHover;

  /// True for the premium look: cards are pure white with a hairline border
  /// and a soft shadow, instead of carrying a tinted wash of the primary.
  final bool flatSurfaces;

  /// Category / discovery pill: a soft indigo tint with dark-blue ink, so
  /// pills read as distinct, tappable chips instead of white-on-white. Only
  /// consulted when [flatSurfaces] is true.
  final Color chipFill;
  final Color chipBorder;
  final Color chipInk;

  /// Solid deep royal-blue background of the Home hero header, with white
  /// text on top (white is ~11:1 on it). Used in light AND dark mode.
  final Color heroColor;
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
    this.accentCool = const Color(0xFF6366F1),
    this.headingWeight = FontWeight.w800,
    this.bodyWeight = FontWeight.w500,
    this.cardShadow,
    this.cardShadowHover,
    this.flatSurfaces = false,
    this.chipFill = const Color(0xFFEEF2FF),
    this.chipBorder = const Color(0xFFC7D2FE),
    this.chipInk = const Color(0xFF1E3A8A),
    this.heroColor = const Color(0xFF093F72),
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

  /// Executive / premium light palette used by the Home screen (see
  /// `PremiumHomeTheme`): crisp off-white canvas, pure-white cards with a
  /// hairline border and an ultra-soft diffused shadow, deep slate text,
  /// indigo + muted gold accents, 16px card radius.
  static const premiumLight = AppDesignTokens(
    surfaceMuted: Color(0xFFF8FAFC),
    surfaceElevated: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    // 475569 on white = 7.6:1, 64748B on white = 4.8:1 (both clear AA).
    textSecondary: Color(0xFF475569),
    textTertiary: Color(0xFF64748B),
    shimmerBase: Color(0xFFF1F5F9),
    shimmerHighlight: Color(0xFFE2E8F0),
    accentWarm: Color(0xFFCA8A04),
    accentCool: Color(0xFF6366F1),
    headingWeight: FontWeight.w600,
    bodyWeight: FontWeight.w400,
    cardShadow: [
      BoxShadow(
        color: Color(0x0A000000), // black @ 4%
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    cardShadowHover: [
      BoxShadow(
        color: Color(0x14000000), // black @ 8%
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
    flatSurfaces: true,
    // Indigo-50 fill / indigo-200 edge / royal-blue ink. 1E3A8A on EEF2FF is
    // ~9:1, so the pill text is comfortably readable.
    chipFill: Color(0xFFEEF2FF),
    chipBorder: Color(0xFFC7D2FE),
    chipInk: Color(0xFF1E3A8A),
    heroColor: Color(0xFF093F72),
    cardRadius: 16,
    buttonRadius: 14,
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
    accentCool: Color(0xFF818CF8),
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
    Color? accentCool,
    FontWeight? headingWeight,
    FontWeight? bodyWeight,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? cardShadowHover,
    bool? flatSurfaces,
    Color? chipFill,
    Color? chipBorder,
    Color? chipInk,
    Color? heroColor,
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
      accentCool: accentCool ?? this.accentCool,
      headingWeight: headingWeight ?? this.headingWeight,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      cardShadow: cardShadow ?? this.cardShadow,
      cardShadowHover: cardShadowHover ?? this.cardShadowHover,
      flatSurfaces: flatSurfaces ?? this.flatSurfaces,
      chipFill: chipFill ?? this.chipFill,
      chipBorder: chipBorder ?? this.chipBorder,
      chipInk: chipInk ?? this.chipInk,
      heroColor: heroColor ?? this.heroColor,
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
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!,
      accentCool: Color.lerp(accentCool, other.accentCool, t)!,
      headingWeight: FontWeight.lerp(headingWeight, other.headingWeight, t)!,
      bodyWeight: FontWeight.lerp(bodyWeight, other.bodyWeight, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t),
      cardShadowHover: BoxShadow.lerpList(
        cardShadowHover,
        other.cardShadowHover,
        t,
      ),
      flatSurfaces: t < 0.5 ? flatSurfaces : other.flatSurfaces,
      chipFill: Color.lerp(chipFill, other.chipFill, t)!,
      chipBorder: Color.lerp(chipBorder, other.chipBorder, t)!,
      chipInk: Color.lerp(chipInk, other.chipInk, t)!,
      heroColor: Color.lerp(heroColor, other.heroColor, t)!,
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
