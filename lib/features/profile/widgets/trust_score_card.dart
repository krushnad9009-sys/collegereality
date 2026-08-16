import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/widgets/premium_components.dart';
import '../models/student_trust_model.dart';

/// Clean stat-card treatment for a student's trust score, consistent with
/// [PremiumCard] elsewhere in the app.
class TrustScoreCard extends StatelessWidget {
  final StudentTrustModel trust;

  const TrustScoreCard({required this.trust, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return PremiumCard(
      radius: tokens.cardRadius,
      color: primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trust Score',
            style: AppFonts.plusJakarta(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              letterSpacing: -0.1,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${trust.trustScore}',
                style: AppFonts.plusJakarta(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 3),
                child: Text(
                  '/100',
                  style: AppFonts.plusJakarta(
                    fontWeight: FontWeight.w600,
                    color: tokens.textTertiary,
                  ),
                ),
              ),
              const Spacer(),
              _MiniStat(
                label: 'Rating',
                value: trust.totalRatings > 0
                    ? trust.overallRating.toStringAsFixed(1)
                    : 'New',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: tokens.borderSubtle, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Ratings',
                  value: '${trust.totalRatings}',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Helpful Votes',
                  value: '${trust.helpfulVotes}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppFonts.plusJakarta(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: AppFonts.plusJakarta(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: tokens.textTertiary,
          ),
        ),
      ],
    );
  }
}
