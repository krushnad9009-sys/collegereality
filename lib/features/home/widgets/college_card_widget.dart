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
  final VoidCallback? onTap;

  const CollegeCardWidget({
    required this.collegeId,
    required this.collegeName,
    required this.location,
    required this.city,
    required this.rating,
    required this.reviewCount,
    this.imageUrl,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CollegeImageWidget(
                collegeId: collegeId,
                imageUrl: imageUrl,
                height: 160,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collegeName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.gray500,
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StarRatingDisplay(
                          rating: rating,
                          reviewCount: reviewCount,
                          starSize: 14,
                        ),
                        const Icon(
                          Icons.favorite_border_rounded,
                          size: 18,
                          color: AppTheme.gray500,
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
