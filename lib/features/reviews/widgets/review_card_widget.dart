import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../models/review_model.dart';
import 'star_rating_widget.dart';

class ReviewCardWidget extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback? onLike;
  final bool showCollegeName;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;

  const ReviewCardWidget({
    required this.review,
    this.onLike,
    this.showCollegeName = false,
    this.onApprove,
    this.onReject,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.gray200.withValues(alpha: 0.9)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.15),
                          AppTheme.secondaryColor.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                review.anonymousAlias,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (review.isVerifiedStudent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: AppTheme.accentColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (review.course != null || review.batchYear != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
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
                          ),
                      ],
                    ),
                  ),
                  StarRatingDisplay(
                    rating: review.overallRating,
                    starSize: 15,
                  ),
                ],
              ),
              if (showCollegeName) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    review.collegeName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
              if (!_isPublished(review.status)) ...[
                const SizedBox(height: 10),
                _StatusChip(status: review.status),
              ],
              if (review.textReview.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  review.textReview,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                    color: AppTheme.gray700,
                  ),
                ),
              ],
              if (review.pros.isNotEmpty) ...[
                const SizedBox(height: 12),
                _TagSection(
                  label: 'Pros',
                  items: review.pros,
                  color: AppTheme.accentColor,
                ),
              ],
              if (review.cons.isNotEmpty) ...[
                const SizedBox(height: 10),
                _TagSection(
                  label: 'Cons',
                  items: review.cons,
                  color: AppTheme.errorColor,
                ),
              ],
              const SizedBox(height: 14),
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
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onLike,
                      icon: Row(
                        children: [
                          const Icon(Icons.thumb_up_alt_outlined, size: 18),
                          const SizedBox(width: 4),
                          Text('${review.likeCount}'),
                        ],
                      ),
                    ),
                  if (onApprove != null)
                    IconButton(
                      tooltip: 'Approve',
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_circle_outline,
                          color: AppTheme.accentColor),
                    ),
                  if (onReject != null)
                    IconButton(
                      tooltip: 'Reject',
                      onPressed: onReject,
                      icon: const Icon(Icons.block, color: AppTheme.warningColor),
                    ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.errorColor),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPublished(String status) =>
      ReviewModel.normalizeStatus(status) == ReviewModel.statusPublished;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = ReviewModel.normalizeStatus(status);
    Color color = AppTheme.warningColor;
    if (normalized == ReviewModel.statusRejected) color = AppTheme.errorColor;
    if (normalized == ReviewModel.statusHidden) color = AppTheme.gray500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normalized.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
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
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items
              .map(
                (item) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
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
