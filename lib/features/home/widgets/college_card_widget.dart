import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../reviews/widgets/star_rating_widget.dart';
import '../../../core/widgets/college_image_widget.dart';

class CollegeCardWidget extends StatelessWidget {
  final String collegeId;
  final String collegeName;
  final String location;
  final String city;
  final double rating;
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppTheme.gray200.withValues(alpha: 0.9)),
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
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
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
                        if (logoUrl != null && logoUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(logoUrl!),
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
                      children: [
                        StarRatingDisplay(
                          rating: rating,
                          reviewCount: reviewCount,
                          starSize: 14,
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
