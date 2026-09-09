import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../communication/models/guide_stats_model.dart';
import '../../communication/providers/communication_provider.dart';
import '../models/guide_review_model.dart';
import '../providers/consultation_provider.dart';

/// Public, anonymised review list for a guide — average + count from
/// [GuideStatsModel] (the denormalised aggregate), individual reviews from
/// `guide_reviews`. Shows no reviewer name/avatar ("Verified student").
class GuideReviewsList extends ConsumerWidget {
  final String guideId;
  final GuideStatsModel stats;

  /// Cap the list; the profile is a summary surface, not a full archive.
  final int max;

  const GuideReviewsList({
    required this.guideId,
    required this.stats,
    this.max = 8,
    super.key,
  });

  double get _average => stats.consultationRatingAvg > 0
      ? stats.consultationRatingAvg
      : stats.overallRating;

  int get _total => stats.completedConsultations > 0
      ? stats.completedConsultations
      : stats.totalRatings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final reviewsAsync = ref.watch(guideReviewsProvider(guideId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reviews',
              style: AppFonts.plusJakarta(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: tokens.textPrimary,
              ),
            ),
            const Spacer(),
            if (_total > 0) ...[
              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 3),
              Text(
                '${_average.toStringAsFixed(1)} · $_total review${_total == 1 ? '' : 's'}',
                style: AppFonts.plusJakarta(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        reviewsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => Text(
            'Couldn\'t load reviews.',
            style: AppFonts.plusJakarta(
              fontSize: 12.5,
              color: tokens.textTertiary,
            ),
          ),
          data: (reviews) {
            final withText =
                reviews.where((r) => r.hasComment).take(max).toList();
            if (withText.isEmpty) {
              return Text(
                _total > 0
                    ? 'No written reviews yet.'
                    : 'No reviews yet — be the first after a consultation.',
                style: AppFonts.plusJakarta(
                  fontSize: 12.5,
                  color: tokens.textTertiary,
                ),
              );
            }
            return Column(
              children: [
                for (final r in withText)
                  _ReviewTile(review: r, guideId: guideId),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewTile extends ConsumerWidget {
  final GuideReviewModel review;
  final String guideId;

  const _ReviewTile({required this.review, required this.guideId});

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final reporterId = ref.read(currentUserProvider)?.uid;
    if (reporterId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report this review?'),
        content: const Text(
          'Flag this review for our team if it\'s abusive, fake, or off-topic.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(communicationServiceProvider).reportUser(
            reporterId: reporterId,
            reportedId: guideId,
            reason: 'inappropriate_review',
            details: 'Review (${review.consultationId}): "${review.comment}"',
          );
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Thanks — our team will review it.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Could not submit the report. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.overall
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 15,
                  color: const Color(0xFFF59E0B),
                ),
              const Spacer(),
              InkWell(
                onTap: () => _report(context, ref),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.flag_outlined,
                    size: 15,
                    color: tokens.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.comment,
            style: AppFonts.plusJakarta(
              fontSize: 13,
              height: 1.4,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              'Verified student',
              if (review.collegeName.trim().isNotEmpty) review.collegeName.trim(),
              _relativeDate(review.createdAt),
            ].join(' · '),
            style: AppFonts.plusJakarta(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  static String _relativeDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays < 1) return 'today';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}
