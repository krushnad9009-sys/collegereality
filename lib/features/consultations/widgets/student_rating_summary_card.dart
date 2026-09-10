import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/widgets/index.dart';
import '../utils/consultation_rating_calculator.dart';

/// Compact read-only view of the ratings a student has received from
/// guides after past consultations ([StudentConsultationSummary]). Shown
/// to a guide in the consultation room so they have context on who they
/// are advising — the other half of the two-way rating loop, mirroring
/// how students see a guide's aggregate before booking.
class StudentRatingSummaryCard extends StatelessWidget {
  final StudentConsultationSummary summary;

  const StudentRatingSummaryCard({required this.summary, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (summary.totalRatings == 0) {
      return PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded,
                size: 18, color: tokens.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'First consultation for this student — no guide ratings yet.',
                style: AppFonts.plusJakarta(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: tokens.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 18, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Text(
                summary.overallAvg.toStringAsFixed(1),
                style: AppFonts.plusJakarta(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'from ${summary.totalRatings} '
                'guide${summary.totalRatings == 1 ? '' : 's'}',
                style: AppFonts.plusJakarta(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _criterion(context, 'Communication', summary.communicationAvg),
          _criterion(context, 'Respectful', summary.respectfulAvg),
          _criterion(context, 'Serious about admission', summary.seriousnessAvg),
          _criterion(context, 'Appropriate behaviour', summary.appropriateAvg),
        ],
      ),
    );
  }

  Widget _criterion(BuildContext context, String label, double value) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppFonts.plusJakarta(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: tokens.textSecondary,
              ),
            ),
          ),
          Text(
            value.toStringAsFixed(1),
            style: AppFonts.plusJakarta(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}
