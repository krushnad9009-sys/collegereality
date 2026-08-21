import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/widgets/skeleton_loader.dart';
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
    final topRatedAsync = ref.watch(topRatedCollegesProvider);
    final placementsAsync = ref.watch(homePlacementHighlightsProvider);
    final reviews = ref.watch(homeRecentReviewsProvider).valueOrNull;

    final topRated = topRatedAsync.valueOrNull;
    final placements = placementsAsync.valueOrNull;

    final topCrScore = (topRated != null && topRated.isNotEmpty)
        ? topRated.map(CrScoreEngine.effectiveScore).reduce((a, b) => a > b ? a : b)
        : null;
    final bestPackage = (placements != null && placements.isNotEmpty)
        ? placements.map((c) => c.placements.averagePackageLpa).reduce((a, b) => a > b ? a : b)
        : null;
    final topReview = (reviews != null && reviews.isNotEmpty) ? reviews.first : null;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Loading (no cached value yet) gets a shimmer, not a bare dash;
    // settled-but-empty gets a short explanatory line instead of "—".
    final crScoreLoading = topRatedAsync.isLoading && topRated == null;
    final packageLoading = placementsAsync.isLoading && placements == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // College Reality's core value proposition gets the one deliberately
        // tinted panel on the page — everything else stays white/neutral.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.09),
            colorScheme.secondary.withValues(alpha: isDark ? 0.10 : 0.05),
          ],
        ),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TrustMetric(
                    icon: Icons.insights_rounded,
                    color: const Color(0xFF0369A1),
                    value: topCrScore != null && topCrScore > 0 ? topCrScore.toStringAsFixed(0) : null,
                    label: 'Top CR Score',
                    emptyText: 'Not enough verified data yet',
                    isLoading: crScoreLoading,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TrustMetric(
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF059669),
                    value: bestPackage != null && bestPackage > 0 ? '₹${bestPackage.toStringAsFixed(1)}L' : null,
                    label: 'Best package',
                    emptyText: 'Not enough verified data yet',
                    isLoading: packageLoading,
                  ),
                ),
              ],
            ),
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

/// A single trust stat with a real empty-state design: a shimmer while the
/// provider is still loading (never a flash of "—"), and a short honest
/// explanatory line — never a bare dash — once settled with no data.
class _TrustMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? value;
  final String label;
  final String emptyText;
  final bool isLoading;

  const _TrustMetric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.emptyText,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(color: tokens.surfaceElevated, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: SkeletonBox(height: 18, width: 44),
                  )
                else if (value != null)
                  Text(value!, style: AppFonts.plusJakarta(fontSize: 16, fontWeight: FontWeight.w800, color: tokens.textPrimary))
                else
                  Text(
                    emptyText,
                    maxLines: 2,
                    style: AppFonts.plusJakarta(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textTertiary, height: 1.25),
                  ),
                const SizedBox(height: 1),
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
        decoration: BoxDecoration(color: tokens.surfaceElevated, borderRadius: BorderRadius.circular(16)),
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
