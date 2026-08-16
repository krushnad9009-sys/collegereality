import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/rating_parameters.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/review_model.dart';
import '../providers/review_provider.dart';
import 'review_media_gallery.dart';
import 'review_yes_no_panel.dart';
import 'star_rating_widget.dart';

class ReviewCardWidget extends ConsumerStatefulWidget {
  final ReviewModel review;
  final VoidCallback? onHelpful;
  final VoidCallback? onReport;
  final bool showCollegeName;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onRestore;
  final VoidCallback? onEditContent;

  const ReviewCardWidget({
    required this.review,
    this.onHelpful,
    this.onReport,
    this.showCollegeName = false,
    this.onApprove,
    this.onReject,
    this.onDelete,
    this.onHide,
    this.onRestore,
    this.onEditContent,
    super.key,
  });

  @override
  ConsumerState<ReviewCardWidget> createState() => _ReviewCardWidgetState();
}

class _ReviewCardWidgetState extends ConsumerState<ReviewCardWidget> {
  bool _showBreakdown = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final primary = theme.colorScheme.primary;
    final helpfulMarkedAsync = ref.watch(reviewHelpfulMarkedProvider(review.id));
    final optimisticMarked = ref.watch(optimisticHelpfulProvider).contains(review.id);
    final hasMarked = helpfulMarkedAsync.valueOrNull == true || optimisticMarked;
    final displayHelpfulCount =
        review.helpfulCount + (optimisticMarked ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PremiumCard(
        radius: tokens.cardRadius,
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
                        primary.withValues(alpha: 0.15),
                        AppTheme.secondaryColor.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    review.isAnonymous ? Icons.visibility_off_outlined : Icons.school_outlined,
                    color: primary,
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
                              style: AppFonts.plusJakarta(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _VerifiedChip(label: review.reviewerBadge ?? 'Verified'),
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
                            style: AppFonts.plusJakarta(
                              fontSize: 12,
                              color: tokens.textTertiary,
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
            if (widget.showCollegeName) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  review.collegeName,
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary,
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
                  color: tokens.textSecondary,
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
            if (review.yesNoAnswers.isNotEmpty) ...[
              const SizedBox(height: 12),
              ReviewYesNoPanel(answers: review.yesNoAnswers, compact: true),
            ],
            if (review.photoUrls.isNotEmpty || review.videoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              ReviewMediaGallery(
                photoUrls: review.photoUrls,
                videoUrls: review.videoUrls,
              ),
            ],
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _showBreakdown = !_showBreakdown),
              child: Row(
                children: [
                  Text(
                    _showBreakdown ? 'Hide ratings' : 'View all ratings',
                    style: AppFonts.plusJakarta(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  Icon(
                    _showBreakdown
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: primary,
                  ),
                ],
              ),
            ),
            if (_showBreakdown) ...[
              const SizedBox(height: 8),
              ...RatingParameters.allKeys.map((key) {
                final value = review.ratings[key] ?? 0;
                if (value <= 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          RatingParameters.labelFor(key),
                          style: AppFonts.plusJakarta(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: value / 5,
                          backgroundColor: tokens.borderSubtle,
                          color: primary,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        value.toStringAsFixed(1),
                        style: AppFonts.plusJakarta(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _formatDate(review.createdAt),
                  style: AppFonts.plusJakarta(
                    fontSize: 11,
                    color: tokens.textTertiary,
                  ),
                ),
                const Spacer(),
                if (widget.onHelpful != null)
                  TextButton.icon(
                    onPressed: hasMarked ? null : widget.onHelpful,
                    icon: Icon(
                      hasMarked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 16,
                      color: hasMarked ? primary : null,
                    ),
                    label: Text(
                      hasMarked
                          ? 'Helpful ($displayHelpfulCount)'
                          : 'Helpful ($displayHelpfulCount)',
                    ),
                  ),
                if (widget.onReport != null)
                  IconButton(
                    tooltip: 'Report',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onReport,
                    icon: const Icon(Icons.flag_outlined, size: 18),
                  ),
                if (widget.onApprove != null)
                  IconButton(
                    tooltip: 'Approve',
                    onPressed: widget.onApprove,
                    icon: const Icon(Icons.check_circle_outline,
                        color: AppTheme.accentColor),
                  ),
                if (widget.onReject != null)
                  IconButton(
                    tooltip: 'Reject',
                    onPressed: widget.onReject,
                    icon: const Icon(Icons.block, color: AppTheme.warningColor),
                  ),
                if (widget.onHide != null)
                  IconButton(
                    tooltip: 'Hide',
                    onPressed: widget.onHide,
                    icon: const Icon(Icons.visibility_off_outlined),
                  ),
                if (widget.onRestore != null)
                  IconButton(
                    tooltip: 'Restore',
                    onPressed: widget.onRestore,
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                if (widget.onEditContent != null)
                  IconButton(
                    tooltip: 'Edit content',
                    onPressed: widget.onEditContent,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                if (widget.onDelete != null)
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.errorColor),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isPublished(String status) =>
      ReviewModel.normalizeStatus(status) == ReviewModel.statusPublished;

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _VerifiedChip extends StatelessWidget {
  final String label;

  const _VerifiedChip({this.label = 'Verified'});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: label,
      icon: Icons.verified,
      color: AppTheme.accentColor,
      fontSize: 10,
      iconSize: 12,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
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
    if (normalized == ReviewModel.statusHidden) {
      color = context.tokens.textTertiary;
    }

    return StatusBadge(
      label: normalized.toUpperCase(),
      color: color,
      fontSize: 10,
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
          style: AppFonts.plusJakarta(
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
                  child: Text(item, style: AppFonts.plusJakarta(fontSize: 11)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
