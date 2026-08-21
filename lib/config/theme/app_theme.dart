import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_fonts.dart';

import 'app_design_tokens.dart';

class AppTheme {
  // Brand — deep teal (trust / academic), not generic indigo/purple.
  static const Color primaryColor = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF115E59);

  static const Color secondaryColor = Color(0xFF0369A1);
  static const Color secondaryLight = Color(0xFF0EA5E9);
  static const Color secondaryDark = Color(0xFF075985);

  static const Color accentColor = Color(0xFF059669);
  static const Color warningColor = Color(0xFFD97706);
  static const Color errorColor = Color(0xFFDC2626);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = Color(0xFF0F172A);

  // Near-white, slightly warm neutral — matches AppDesignTokens.light so
  // the scaffold background and the token consumers agree on one base.
  static const Color surfaceMuted = Color(0xFFFAFAF9);

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
          secondary: secondaryColor,
          tertiary: accentColor,
          error: errorColor,
          surface: white,
        ),
        tokens: AppDesignTokens.light,
        scaffoldBg: surfaceMuted,
        appBarBg: white,
        appBarFg: gray900,
        cardBg: white,
        cardBorder: gray200,
        inputFill: gray100,
        inputBorder: gray200,
        textColor: gray900,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryLight,
          brightness: Brightness.dark,
          primary: primaryLight,
          secondary: secondaryLight,
          tertiary: accentColor,
          error: errorColor,
          surface: gray900,
        ),
        tokens: AppDesignTokens.dark,
        scaffoldBg: gray900,
        appBarBg: gray900,
        appBarFg: white,
        cardBg: gray800,
        cardBorder: gray700,
        inputFill: gray800,
        inputBorder: gray700,
        textColor: white,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required AppDesignTokens tokens,
    required Color scaffoldBg,
    required Color appBarBg,
    required Color appBarFg,
    required Color cardBg,
    required Color cardBorder,
    required Color inputFill,
    required Color inputBorder,
    required Color textColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _buildTextTheme(textColor);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: appBarFg),
        titleTextStyle: AppFonts.plusJakarta(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: appBarFg,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: cardBorder.withValues(alpha: 0.85)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: primaryColor.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppFonts.plusJakarta(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: -0.1,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? primaryLight : primaryColor,
          foregroundColor: isDark ? gray900 : white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          minimumSize: const Size(64, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
          ),
          textStyle: AppFonts.plusJakarta(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? primaryLight : primaryColor,
          foregroundColor: isDark ? gray900 : white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          minimumSize: const Size(64, 52),
          elevation: 0,
          shadowColor: primaryDark.withValues(alpha: 0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
          ),
          textStyle: AppFonts.plusJakarta(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? primaryLight : primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
          ),
          side: BorderSide(
            color: isDark ? primaryLight : primaryColor,
            width: 1.5,
          ),
          textStyle: AppFonts.plusJakarta(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? primaryLight : primaryColor,
          minimumSize: const Size(48, 44),
          textStyle: AppFonts.plusJakarta(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
          borderSide: BorderSide(
            color: isDark ? primaryLight : primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: AppFonts.plusJakarta(
          color: tokens.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: AppFonts.plusJakarta(color: tokens.textTertiary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputFill,
        selectedColor: isDark ? primaryLight : primaryColor,
        disabledColor: inputFill.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.chipRadius),
        ),
        labelStyle: AppFonts.plusJakarta(
          color: tokens.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
        ),
        titleTextStyle: AppFonts.plusJakarta(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.cardRadius),
          ),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: AppFonts.plusJakarta(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: cardBorder.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? primaryLight : primaryColor,
        linearTrackColor: inputFill,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    TextStyle base({
      required double size,
      required FontWeight weight,
      double? height,
      double? letterSpacing,
    }) =>
        AppFonts.plusJakarta(
          fontSize: size,
          fontWeight: weight,
          color: textColor,
          height: height,
          letterSpacing: letterSpacing,
        );

    return TextTheme(
      displayLarge: base(size: 32, weight: FontWeight.w800, letterSpacing: -0.6, height: 1.12),
      displayMedium: base(size: 28, weight: FontWeight.w800, letterSpacing: -0.5, height: 1.15),
      displaySmall: base(size: 24, weight: FontWeight.w700, letterSpacing: -0.4, height: 1.2),
      headlineLarge: base(size: 20, weight: FontWeight.w700, letterSpacing: -0.35),
      headlineMedium: base(size: 18, weight: FontWeight.w700, letterSpacing: -0.3),
      headlineSmall: base(size: 16, weight: FontWeight.w700),
      titleLarge: base(size: 16, weight: FontWeight.w700),
      titleMedium: base(size: 14, weight: FontWeight.w600),
      titleSmall: base(size: 12, weight: FontWeight.w600),
      bodyLarge: base(size: 16, weight: FontWeight.w500, height: 1.5),
      bodyMedium: base(size: 14, weight: FontWeight.w500, height: 1.45),
      bodySmall: base(size: 12, weight: FontWeight.w500, height: 1.4),
      labelLarge: base(size: 14, weight: FontWeight.w700),
      labelMedium: base(size: 12, weight: FontWeight.w700),
      labelSmall: base(size: 10, weight: FontWeight.w700),
    );
  }
}
