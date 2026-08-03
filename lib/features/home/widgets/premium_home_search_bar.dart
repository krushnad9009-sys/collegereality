import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';

/// Primary home search entry with gradient accent.
class PremiumHomeSearchBar extends StatefulWidget {
  const PremiumHomeSearchBar({super.key});

  @override
  State<PremiumHomeSearchBar> createState() => _PremiumHomeSearchBarState();
}

class _PremiumHomeSearchBarState extends State<PremiumHomeSearchBar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.go(RouteNames.collegeSearch),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            gradient: LinearGradient(
              colors: isDark
                  ? [AppTheme.gray800, AppTheme.gray800]
                  : [AppTheme.white, AppTheme.white],
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: AppTheme.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
            border: Border.all(
              color: isDark
                  ? AppTheme.gray700
                  : AppTheme.primaryColor.withValues(alpha: 0.12),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(1.5),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl - 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppTheme.gray800, AppTheme.gray900]
                    : [
                        AppTheme.white,
                        AppTheme.primaryColor.withValues(alpha: 0.03),
                      ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Where do you want to study?',
                        style: AppFonts.plusJakarta(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? AppTheme.gray100 : AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Search colleges, cities, courses & more',
                        style: AppFonts.plusJakarta(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: AppTheme.primaryColor.withValues(alpha: 0.9),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
