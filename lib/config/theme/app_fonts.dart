import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Plus Jakarta Sans helper with a test-safe system fallback.
///
/// Widget tests cannot fetch Google Fonts over the network
/// ([TestWidgetsFlutterBinding] returns HTTP 400). Set
/// [useSystemFallback] from `test/flutter_test_config.dart`.
abstract final class AppFonts {
  /// When true, return metric-matched [TextStyle]s without network fonts.
  static bool useSystemFallback = false;

  static TextStyle plusJakarta({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    Color? color,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    if (useSystemFallback) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
        decoration: decoration,
        fontStyle: fontStyle,
      );
    }
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }
}