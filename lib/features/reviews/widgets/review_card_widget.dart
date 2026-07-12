import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../models/review_model.dart';
import 'star_rating_widget.dart';

class ReviewCardWidget extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback? onLike;
  final bool showCollegeName;

  const ReviewCardWidget({
    required this.review,
    this.onLike,
    this.showCollegeName = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              review.anonymousAlias,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (review.isVerifiedStudent) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 14,
                              color: AppTheme.accentColor,
                            ),
                          ],
                        ],
                      ),
                      if (review.course != null || review.batchYear != null)
                        Text(
                          [
                            if (review.course != null) review.course,
                            if (review.batchYear != null)
                              'Batch ${review.batchYear}',
                          ].join(' · '),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.gray500,
                          ),
                        ),
                    ],
                  ),
                ),
                StarRatingDisplay(rating: review.overallRating, starSize: 14),
              ],
            ),
            if (showCollegeName) ...[
              const SizedBox(height: 8),
              Text(
                review.collegeName,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
            if (review.textReview.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.textReview,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.gray700,
                  height: 1.5,
                ),
              ),
            ],
            if (review.pros.isNotEmpty) ...[
              const SizedBox(height: 10),
              _TagSection(label: 'Pros', items: review.pros, color: AppTheme.accentColor),
            ],
            if (review.cons.isNotEmpty) ...[
              const SizedBox(height: 8),
              _TagSection(label: 'Cons', items: review.cons, color: AppTheme.errorColor),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _formatDate(review.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.gray400,
                  ),
                ),
                const Spacer(),
                if (onLike != null)
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.thumb_up_outlined,
                            size: 16,
                            color: AppTheme.gray500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${review.likeCount}',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _TagSection extends StatelessWidget {
  final String label;
  final List<String> items;
  final Color color;

  const _TagSection({
    required this.label,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
