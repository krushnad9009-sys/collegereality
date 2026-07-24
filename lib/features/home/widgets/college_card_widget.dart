import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../ranking/widgets/cr_score_badge_widget.dart';
import '../../reviews/widgets/star_rating_widget.dart';
import '../../../core/widgets/college_logo_widget.dart';
import '../../../core/widgets/college_image_widget.dart';

class CollegeCardWidget extends StatelessWidget {
  final String collegeId;
  final String collegeName;
  final String location;
  final String city;
  final double rating;
  final double? crScore;
  final int reviewCount;
  final String? imageUrl;
  final String? logoUrl;
  final VoidCallback? onTap;
  final bool isSelectedForCompare;
  final VoidCallback? onCompareToggle;

  const CollegeCardWidget({
    required this.collegeId,
    required this.collegeName,
    required this.location,
    required this.city,
    required this.rating,
    this.crScore,
    required this.reviewCount,
    this.imageUrl,
    this.logoUrl,
    this.onTap,
    this.isSelectedForCompare = false,
    this.onCompareToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray800 : AppTheme.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppTheme.gray700 : AppTheme.gray200.withValues(alpha: 0.8),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.primaryDark.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CollegeImageWidget(
                collegeId: collegeId,
                imageUrl: imageUrl,
                height: 168,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: CollegeLogoWidget(
                            collegeId: collegeId,
                            collegeName: collegeName,
                            logoUrl: logoUrl,
                            radius: 18,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            collegeName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$location, $city',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.gray600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StarRatingDisplay(
                                rating: rating,
                                reviewCount: reviewCount,
                                starSize: 14,
                              ),
                              if (crScore != null && crScore! > 0) ...[
                                const SizedBox(height: 8),
                                CrScoreBadgeWidget(score: crScore!),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (onCompareToggle != null)
                              IconButton(
                                tooltip: isSelectedForCompare
                                    ? 'Remove from compare'
                                    : 'Add to compare',
                                onPressed: onCompareToggle,
                                icon: Icon(
                                  isSelectedForCompare
                                      ? Icons.check_circle_rounded
                                      : Icons.compare_arrows_outlined,
                                  color: isSelectedForCompare
                                      ? AppTheme.accentColor
                                      : AppTheme.gray500,
                                  size: 22,
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'View',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
