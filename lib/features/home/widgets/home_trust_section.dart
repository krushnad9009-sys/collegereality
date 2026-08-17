import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../reviews/models/review_model.dart';
import '../../reviews/widgets/star_rating_widget.dart';
import '../providers/home_content_provider.dart';
import '../../ranking/utils/cr_score_engine.dart';

/// The single consolidated trust proposition for Home: what CR Score means,
/// real placement signal, one real verified-review excerpt (only if one
/// exists — never fabricated), and the one CTA to talk to a verified
/// student. Replaces four previously-separate, conceptually-duplicate
/// sections (Reality Check tiles / Verified Reviews list / insights strip /
/// consultation CTA card).
class HomeTrustSection extends ConsumerWidget {
  const HomeTrustSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final topRated = ref.watch(topRatedCollegesProvider).valueOrNull;
    final placements = ref.watch(homePlacementHighlightsProvider).valueOrNull;
    final reviews = ref.watch(homeRecentReviewsProvider).valueOrNull;

    final topCrScore = (topRated != null && topRated.isNotEmpty)
        ? topRated.map(CrScoreEngine.effectiveScore).reduce((a, b) => a > b ? a : b)
        : null;
    final bestPackage = (placements != null && placements.isNotEmpty)
        ? placements.map((c) => c.placements.averagePackageLpa).reduce((a, b) => a > b ? a : b)
        : null;
    final topReview = (reviews != null && reviews.isNotEmpty) ? reviews.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: tokens.surfaceElevated,
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Know the reality before you decide.',
            style: AppFonts.plusJakarta(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: tokens.textPrimary,
              letterSpacing: -0.3,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'CR Score, real placement outcomes and verified student reviews — not marketing copy.',
            style: AppFonts.plusJakarta(fontSize: 13.5, fontWeight: FontWeight.w500, color: tokens.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TrustMetric(
                  icon: Icons.insights_rounded,
                  color: const Color(0xFF0369A1),
                  value: topCrScore != null && topCrScore > 0 ? topCrScore.toStringAsFixed(0) : '—',
                  label: 'Top CR Score',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrustMetric(
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF059669),
                  value: bestPackage != null && bestPackage > 0 ? '₹${bestPackage.toStringAsFixed(1)}L' : '—',
                  label: 'Best package',
                ),
              ),
            ],
          ),
          if (topReview != null) ...[
            const SizedBox(height: 16),
            _ReviewExcerpt(review: topReview),
          ],
        ],
      ),
    );
  }
}

class _TrustMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _TrustMetric({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(color: tokens.surfaceMuted, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: AppFonts.plusJakarta(fontSize: 16, fontWeight: FontWeight.w800, color: tokens.textPrimary)),
                Text(label, style: AppFonts.plusJakarta(fontSize: 11.5, fontWeight: FontWeight.w500, color: tokens.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewExcerpt extends StatelessWidget {
  final ReviewModel review;

  const _ReviewExcerpt({required this.review});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: () => context.go(RouteNames.collegeDetailsPath(review.collegeId)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: tokens.surfaceMuted, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF0F766E)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${review.anonymousAlias} · ${review.collegeName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.plusJakarta(fontSize: 12.5, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                  ),
                ),
                StarRatingDisplay(rating: review.overallRating, starSize: 12),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              review.textReview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.plusJakarta(fontSize: 13, fontWeight: FontWeight.w500, color: tokens.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
