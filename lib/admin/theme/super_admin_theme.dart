import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_theme.dart';

class SuperAdminTheme {
  static const Color sidebarBg = Color(0xFF0F172A);
  static const Color sidebarActive = Color(0xFF6366F1);
  static const Color sidebarText = Color(0xFFCBD5E1);
  static const Color accent = Color(0xFF818CF8);

  static ThemeData get lightTheme {
    final base = AppTheme.lightTheme;
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      colorScheme: base.colorScheme.copyWith(
        primary: AppTheme.primaryDark,
        surface: Colors.white,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: sidebarBg,
        indicatorColor: sidebarActive.withValues(alpha: 0.25),
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: IconThemeData(color: sidebarText.withValues(alpha: 0.7)),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: sidebarText,
          fontSize: 12,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.gray200.withValues(alpha: 0.8)),
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.gray900,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.gray900,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.gray200),
        ),
      ),
    );
  }
}
