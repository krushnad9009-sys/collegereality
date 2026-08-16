import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/college_image_widget.dart';
import '../../../core/widgets/premium_components.dart';
import '../models/ai_college_recommendation.dart';

class AiRecommendationCard extends StatelessWidget {
  final AiCollegeRecommendation recommendation;
  final VoidCallback? onAddToCompare;

  const AiRecommendationCard({
    required this.recommendation,
    this.onAddToCompare,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final college = recommendation.college;
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PremiumCard(
        radius: tokens.cardRadius,
        padding: const EdgeInsets.all(AppSpacing.lg),
        onTap: () => context.go(RouteNames.collegeDetailsPath(college.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CollegeImageWidget(
                    collegeId: college.id,
                    imageUrl: college.coverPhotoUrl ?? college.logoUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withValues(alpha: 0.18),
                                  AppTheme.secondaryColor.withValues(alpha: 0.12),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#${recommendation.rank}',
                              style: AppFonts.plusJakarta(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (college.aggregatedRatings.overall > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warningColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: AppTheme.warningColor,
                                  ),
                                  Text(
                                    college.aggregatedRatings.overall
                                        .toStringAsFixed(1),
                                    style: AppFonts.plusJakarta(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.warningColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        college.name,
                        style: AppFonts.plusJakarta(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.25,
                          height: 1.25,
                          color: tokens.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        college.locationLabel,
                        style: AppFonts.plusJakarta(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (recommendation.reasons.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'WHY RECOMMENDED',
                style: AppFonts.plusJakarta(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              ...recommendation.reasons.take(3).map(
                    (reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppTheme.accentColor.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reason,
                              style: AppFonts.plusJakarta(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            if (onAddToCompare != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onAddToCompare,
                  icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                  label: Text(
                    'Add to Compare',
                    style: AppFonts.plusJakarta(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
