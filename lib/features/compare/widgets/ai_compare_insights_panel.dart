import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../models/college_comparison_result.dart';

class AiCompareInsightsPanel extends StatelessWidget {
  final List<CollegeCompareInsight> insights;

  const AiCompareInsightsPanel({required this.insights, super.key});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'AI Compare Insights',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Insights based on verified college records.',
          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
        ),
        const SizedBox(height: 12),
        ...insights.map((insight) => _InsightCard(insight: insight)),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final CollegeCompareInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              insight.collegeName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (insight.strengths.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Strengths',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentColor,
                ),
              ),
              ...insight.strengths.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.add_circle_outline,
                          size: 14, color: AppTheme.accentColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(s, style: GoogleFonts.poppins(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (insight.weaknesses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Weaknesses',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warningColor,
                ),
              ),
              ...insight.weaknesses.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.remove_circle_outline,
                          size: 14, color: AppTheme.warningColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(w, style: GoogleFonts.poppins(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (insight.strengths.isEmpty && insight.weaknesses.isEmpty)
              Text(
                'Insufficient verified data to determine relative strengths.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.gray500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
