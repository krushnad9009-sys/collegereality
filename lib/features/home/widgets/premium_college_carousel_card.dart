import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/college_image_widget.dart';
import '../../ranking/utils/cr_score_engine.dart';
import '../../ranking/widgets/cr_score_badge_widget.dart';
import '../../reviews/widgets/star_rating_widget.dart';
import '../../colleges/models/college_model.dart';

/// Compact horizontal college card for carousels.
class PremiumCollegeCarouselCard extends StatelessWidget {
  final CollegeModel college;
  final VoidCallback? onTap;

  const PremiumCollegeCarouselCard({
    required this.college,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ??
            () => context.go(RouteNames.collegeDetailsPath(college.id)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Ink(
            width: 268,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray800 : AppTheme.white,
              border: Border.all(
                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: AppTheme.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CollegeImageWidget(
                    collegeId: college.id,
                    imageUrl: college.coverPhotoUrl,
                    height: 130,
                    width: 268,
                  ),
                  if (college.isFeatured)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Trending',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      college.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${college.city}, ${college.state}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.gray500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CrScoreBadgeWidget(
                      score: CrScoreEngine.effectiveScore(college),
                      showGrade: true,
                      fontSize: 11,
                    ),
                    const SizedBox(height: 8),
                    StarRatingDisplay(
                      rating: college.aggregatedRatings.overall,
                      reviewCount: college.reviewCount,
                      starSize: 12,
                    ),
                  ],
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
