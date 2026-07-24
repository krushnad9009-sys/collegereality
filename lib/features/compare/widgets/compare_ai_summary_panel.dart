import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../models/college_comparison_result.dart';

class CompareAiSummaryPanel extends StatelessWidget {
  final CompareAiSummary summary;

  const CompareAiSummaryPanel({required this.summary, super.key});

  @override
  Widget build(BuildContext context) {
    if (!summary.hasAny) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'AI Summary',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Based on verified student feedback and CR Score categories.',
          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (summary.bestOverall != null)
              _SummaryChip(
                icon: Icons.emoji_events_outlined,
                label: 'Best Overall',
                value: summary.bestOverall!,
                color: AppTheme.accentColor,
              ),
            if (summary.bestForPlacements != null)
              _SummaryChip(
                icon: Icons.work_outline,
                label: 'Best for Placements',
                value: summary.bestForPlacements!,
                color: AppTheme.primaryColor,
              ),
            if (summary.bestForCampusLife != null)
              _SummaryChip(
                icon: Icons.park_outlined,
                label: 'Best for Campus Life',
                value: summary.bestForCampusLife!,
                color: Colors.teal,
              ),
            if (summary.bestValueForMoney != null)
              _SummaryChip(
                icon: Icons.savings_outlined,
                label: 'Best Value for Money',
                value: summary.bestValueForMoney!,
                color: AppTheme.warningColor,
              ),
          ],
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
