import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Applies the premium / executive look ([AppTheme.premiumLightTheme]) to
/// everything below it, without touching the rest of the app.
///
/// Home widgets read colour from `Theme.of(context).colorScheme` and
/// `context.tokens`, so wrapping the screen in this restyles them all. Only
/// the LIGHT theme is upgraded: in dark mode the ambient theme is returned
/// untouched (the existing dark palette is already deep slate navy).
///
/// Promoting the premium look app-wide later is a one-line change: make
/// `MaterialApp.theme` use [AppTheme.premiumLightTheme] and drop the wrapper.
class PremiumHomeTheme extends StatelessWidget {
  final Widget child;

  const PremiumHomeTheme({required this.child, super.key});

  /// The theme [child] will see for a given ambient [theme].
  static ThemeData resolve(ThemeData theme) =>
      theme.brightness == Brightness.dark ? theme : AppTheme.premiumLightTheme;

  @override
  Widget build(BuildContext context) {
    return Theme(data: resolve(Theme.of(context)), child: child);
  }
}
