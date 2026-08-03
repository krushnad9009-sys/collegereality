import 'package:flutter/material.dart';

import 'app_fonts.dart';
import 'app_theme.dart';

/// Central typography for a premium, consistent product feel.
abstract final class AppTypography {
  static TextStyle display(String text, {Color? color}) =>
      AppFonts.plusJakarta(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.15,
        color: color ?? AppTheme.gray900,
      );

  static TextStyle headline(String text, {Color? color}) =>
      AppFonts.plusJakarta(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.45,
        height: 1.2,
        color: color ?? AppTheme.gray900,
      );

  static TextStyle title(String text, {Color? color}) =>
      AppFonts.plusJakarta(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
        color: color ?? AppTheme.gray900,
      );

  static TextStyle body(String text, {Color? color}) =>
      AppFonts.plusJakarta(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: color ?? AppTheme.gray600,
      );

  static TextStyle caption(String text, {Color? color}) =>
      AppFonts.plusJakarta(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: color ?? AppTheme.gray500,
      );

  static TextStyle label(String text, {Color? color}) =>
      AppFonts.plusJakarta(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: color ?? AppTheme.gray500,
      );

  static TextStyle overline(String text, {Color? color}) =>
      AppFonts.plusJakarta(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: color ?? AppTheme.gray500,
      );

  static TextStyle button(String text, {Color? color}) =>
      AppFonts.plusJakarta(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: color ?? AppTheme.white,
      );

  static TextStyle searchHint(String text, {Color? color}) =>
      AppFonts.plusJakarta(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color ?? AppTheme.gray400,
      );
}