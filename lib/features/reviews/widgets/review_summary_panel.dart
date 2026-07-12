import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../colleges/models/college_model.dart';
import 'star_rating_widget.dart';
import 'rating_distribution_chart.dart';

class ReviewSummaryPanel extends StatelessWidget {
  final CollegeModel college;

  const ReviewSummaryPanel({required this.college, super.key});

  @override
  Widget build(BuildContext context) {
    final ratings = college.aggregatedRatings;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    ratings.overall > 0 ? ratings.overall.toStringAsFixed(1) : '—',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  StarRatingDisplay(rating: ratings.overall, starSize: 16),
                  const SizedBox(height: 4),
                  Text(
                    '${college.reviewCount} verified reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.gray600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: RatingDistributionChart(
                  distribution: college.ratingDistribution,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TrustChip(
                icon: Icons.verified,
                label: 'Verified students only',
              ),
              _TrustChip(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.accentColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
