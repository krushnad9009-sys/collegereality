import 'package:flutter/material.dart';

import '../../../config/theme/app_elevation.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';

/// Gradient hero banner for the home screen.
class HomeHeroBanner extends StatelessWidget {
  final String? greeting;
  final String? subtitle;
  final Widget? trailing;

  const HomeHeroBanner({
    this.greeting,
    this.subtitle,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.primaryDark,
                  AppTheme.gray900,
                  AppTheme.secondaryDark,
                ]
              : [
                  AppTheme.primaryColor,
                  AppTheme.primaryLight,
                  AppTheme.secondaryColor,
                ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppElevation.medium(AppTheme.primaryDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting ?? 'Discover your perfect college',
                      style: AppFonts.plusJakarta(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: AppFonts.plusJakarta(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 20),
          const _HeroStatsRow(),
        ],
      ),
    );
  }
}

class _HeroStatsRow extends StatelessWidget {
  const _HeroStatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _HeroStat(value: '47K+', label: 'Colleges'),
        SizedBox(width: 10),
        _HeroStat(value: 'Verified', label: 'Reviews'),
        SizedBox(width: 10),
        _HeroStat(value: 'AI', label: 'Assistant'),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppFonts.plusJakarta(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppFonts.plusJakarta(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}