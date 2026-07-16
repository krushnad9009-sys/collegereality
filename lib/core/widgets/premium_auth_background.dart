import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';

/// Gradient backdrop for auth and onboarding screens.
class PremiumAuthBackground extends StatelessWidget {
  final Widget child;
  final bool showOrbs;

  const PremiumAuthBackground({
    required this.child,
    this.showOrbs = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.gray900, AppTheme.gray800, AppTheme.primaryDark]
              : [AppTheme.white, AppTheme.gray50, AppTheme.primaryColor.withValues(alpha: 0.08)],
        ),
      ),
      child: Stack(
        children: [
          if (showOrbs) ...[
            Positioned(
              top: -80,
              right: -40,
              child: _Orb(
                size: 220,
                color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.18 : 0.12),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -30,
              child: _Orb(
                size: 180,
                color: AppTheme.secondaryColor.withValues(alpha: isDark ? 0.16 : 0.1),
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
