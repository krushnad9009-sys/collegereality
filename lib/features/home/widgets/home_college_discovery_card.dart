import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/constants/cr_score_constants.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/college_image_widget.dart';
import '../../../core/widgets/college_logo_widget.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/providers/college_provider.dart';
import '../../engagement/providers/engagement_provider.dart';
import '../../ranking/utils/cr_score_engine.dart';

const double _kCardWidth = 250;
const double _kCardHeight = 300;
const double _kMediaHeight = 168;

/// "Featured / Recommended Colleges" — the ONE college-discovery carousel
/// on Home (replaces the old Featured/Trending/Top-Rated/Placement-highlight
/// quadruplication). Every card is real data from [homeFeaturedCollegesProvider].
class FeaturedCollegesSection extends ConsumerWidget {
  const FeaturedCollegesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegesAsync = ref.watch(homeFeaturedCollegesProvider);

    return collegesAsync.when(
      loading: () => SizedBox(
        height: _kCardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, _) => SizedBox(
            width: _kCardWidth,
            child: CollegeCardSkeleton(height: _kCardHeight),
          ),
        ),
      ),
      error: (e, _) => SizedBox(
        height: _kCardHeight,
        child: AsyncErrorView.fromError(
          e,
          compact: true,
          onRetry: () => ref.invalidate(homeFeaturedCollegesProvider),
        ),
      ),
      data: (colleges) {
        if (colleges.isEmpty) {
          return const AsyncEmptyView(
            icon: Icons.school_outlined,
            title: 'No recommended colleges yet',
            subtitle: 'Colleges will appear here once the directory is seeded.',
          );
        }
        return SizedBox(
          height: _kCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: colleges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) => HomeCollegeDiscoveryCard(college: colleges[index]),
          ),
        );
      },
    );
  }
}

/// A single college card that honestly reflects whether a verified photo
/// exists: image-dominant when it does, a compact honest data card when it
/// doesn't — never a fake gradient pretending to be a campus photo.
class HomeCollegeDiscoveryCard extends ConsumerStatefulWidget {
  final CollegeModel college;

  const HomeCollegeDiscoveryCard({required this.college, super.key});

  @override
  ConsumerState<HomeCollegeDiscoveryCard> createState() => _HomeCollegeDiscoveryCardState();
}

class _HomeCollegeDiscoveryCardState extends ConsumerState<HomeCollegeDiscoveryCard> {
  bool _pressed = false;

  Future<void> _toggleSave() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to save colleges')),
        );
        context.go(RouteNames.loginWithReturn(RouteNames.collegeDetailsPath(widget.college.id)));
      }
      return;
    }
    await ref.read(engagementRepositoryProvider).toggleFavoriteCollege(user.uid, widget.college.id);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final college = widget.college;
    final hasPhoto = (college.coverPhotoUrl ?? '').isNotEmpty;
    final crScore = CrScoreEngine.effectiveScore(college);
    final isVerified = college.verifiedStudentCount > 0 || college.reviewCount >= 3;
    final favoriteIds = ref.watch(favoriteCollegeIdsProvider).valueOrNull ?? {};
    final isSaved = favoriteIds.contains(college.id);
    final supportingFact = college.placements.averagePackageLpa > 0
        ? '₹${college.placements.averagePackageLpa.toStringAsFixed(1)}L avg. package'
        : college.reviewCount > 0
            ? '${college.reviewCount} student reviews'
            : 'New on College Reality';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.go(RouteNames.collegeDetailsPath(college.id)),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          width: _kCardWidth,
          height: _kCardHeight,
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle.withValues(alpha: isDark ? 0.5 : 0.9)),
            boxShadow: isDark
                ? null
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: _kMediaHeight,
                width: _kCardWidth,
                child: hasPhoto
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CollegeImageWidget(
                            collegeId: college.id,
                            imageUrl: college.coverPhotoUrl,
                            height: _kMediaHeight,
                            width: _kCardWidth,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _BookmarkButton(isSaved: isSaved, onTap: _toggleSave),
                          ),
                        ],
                      )
                    : _DataFirstMedia(college: college, isSaved: isSaved, onBookmark: _toggleSave),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            college.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.plusJakarta(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.2,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${college.city} · ${college.category}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.plusJakarta(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: tokens.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (isVerified) ...[
                            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0F766E)),
                            const SizedBox(width: 3),
                          ],
                          if (crScore > 0) ...[
                            Icon(Icons.star_rounded, size: 14, color: const Color(0xFFD97706)),
                            const SizedBox(width: 2),
                            Text(
                              college.aggregatedRatings.overall > 0
                                  ? college.aggregatedRatings.overall.toStringAsFixed(1)
                                  : crScore.toStringAsFixed(0),
                              style: AppFonts.plusJakarta(fontSize: 12.5, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                            ),
                            const SizedBox(width: 6),
                            Text('·', style: AppFonts.plusJakarta(fontSize: 12.5, color: tokens.textTertiary)),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              supportingFact,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.plusJakarta(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Honest no-photo state — a small real (or initials) logo on a neutral
/// tinted panel, never a gradient standing in for a campus photo.
class _DataFirstMedia extends StatelessWidget {
  final CollegeModel college;
  final bool isSaved;
  final VoidCallback onBookmark;

  const _DataFirstMedia({required this.college, required this.isSaved, required this.onBookmark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      color: tokens.surfaceMuted,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: CollegeLogoWidget(
                collegeId: college.id,
                collegeName: college.name,
                logoUrl: college.logoUrl,
                radius: 29,
              ),
            ),
          ),
          Positioned(top: 8, right: 8, child: _BookmarkButton(isSaved: isSaved, onTap: onBookmark)),
        ],
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;

  const _BookmarkButton({required this.isSaved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            size: 16,
            color: isSaved ? const Color(0xFF059669) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

/// CR Score chip kept available for reuse where a standalone badge (rather
/// than the inline row above) is a better fit.
class HomeCrScoreBadge extends StatelessWidget {
  final double score;

  const HomeCrScoreBadge({required this.score, super.key});

  @override
  Widget build(BuildContext context) {
    final color = CrScoreConstants.colorForScore(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(
        'CR ${score.toStringAsFixed(0)}',
        style: AppFonts.plusJakarta(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
