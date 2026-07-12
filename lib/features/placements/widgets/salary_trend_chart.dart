import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../models/verified_placement_stats.dart';

class SalaryTrendChart extends StatelessWidget {
  final List<YearPlacementTrend> trends;

  const SalaryTrendChart({required this.trends, super.key});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return _emptyState('No year-wise salary data from verified records yet.');
    }

    final maxPackage = trends
        .map((e) => e.avgPackageLpa)
        .fold(0.0, (a, b) => a > b ? a : b);

    if (maxPackage <= 0) {
      return _emptyState('Verified records exist but package data is unavailable.');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.gray800
            : AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Salary Trend (Verified Avg LPA)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trends.map((t) {
                final heightFactor = t.avgPackageLpa / maxPackage;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          t.avgPackageLpa > 0
                              ? t.avgPackageLpa.toStringAsFixed(1)
                              : '—',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 120 * heightFactor.clamp(0.05, 1.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${t.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.gray500,
                          ),
                        ),
                        Text(
                          'n=${t.count}',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: AppTheme.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
      ),
    );
  }
}
