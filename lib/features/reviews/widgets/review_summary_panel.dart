import 'package:flutter/material.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/rating_parameters.dart';
import '../../../core/widgets/status_badge.dart';
import '../../colleges/models/college_model.dart';
import 'star_rating_widget.dart';
import 'rating_distribution_chart.dart';

class ReviewSummaryPanel extends StatelessWidget {
  final CollegeModel college;

  const ReviewSummaryPanel({required this.college, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final ratings = college.aggregatedRatings;
    final breakdown = RatingParameters.allKeys
        .map((key) => (RatingParameters.labelFor(key), ratings.ratingFor(key)))
        .where((item) => item.$2 > 0)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Rating',
                    style: AppFonts.plusJakarta(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ratings.overall > 0 ? ratings.overall.toStringAsFixed(1) : '—',
                    style: AppFonts.plusJakarta(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                  StarRatingDisplay(rating: ratings.overall, starSize: 16),
                  const SizedBox(height: 4),
                  Text(
                    '${college.reviewCount} verified review${college.reviewCount == 1 ? '' : 's'}',
                    style: AppFonts.plusJakarta(
                      fontSize: 11,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Star distribution',
                      style: AppFonts.plusJakarta(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RatingDistributionChart(
                      distribution: college.ratingDistribution,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Rating breakdown',
              style: AppFonts.plusJakarta(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...breakdown.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.$1,
                          style: AppFonts.plusJakarta(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: tokens.textSecondary,
                          ),
                        ),
                        Text(
                          '${item.$2.toStringAsFixed(1)}/5',
                          style: AppFonts.plusJakarta(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: item.$2 / 5,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: tokens.borderSubtle,
                      color: AppTheme.warningColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (college.wouldChooseAgainPercent != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.thumb_up_alt_outlined,
                      color: AppTheme.accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${college.wouldChooseAgainPercent!.round()}% would choose this college again',
                      style: AppFonts.plusJakarta(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (college.verifiedStudentCount > 0)
                _TrustChip(
                  icon: Icons.verified,
                  label: '${college.verifiedStudentCount} verified students',
                ),
              if (college.verifiedAlumniCount > 0)
                _TrustChip(
                  icon: Icons.school_outlined,
                  label: '${college.verifiedAlumniCount} verified alumni',
                ),
              if (college.questionCount > 0)
                _TrustChip(
                  icon: Icons.quiz_outlined,
                  label: '${college.questionCount} questions',
                ),
              if (college.answersAnsweredCount > 0)
                _TrustChip(
                  icon: Icons.forum_outlined,
                  label: '${college.answersAnsweredCount} answers',
                ),
              const _TrustChip(
                icon: Icons.visibility_off_outlined,
                label: 'Anonymous option',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: label,
      icon: icon,
      color: AppTheme.accentColor,
      fontSize: 10,
      iconSize: 12,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
