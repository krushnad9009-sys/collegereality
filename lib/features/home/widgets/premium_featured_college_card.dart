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
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/providers/college_provider.dart';
import '../../engagement/providers/engagement_provider.dart';
import '../../ranking/utils/cr_score_engine.dart';
import 'home_college_image_fallback.dart';

/// "Featured Colleges" — a horizontal carousel of compact, listing-style
/// discovery cards (inset rounded photo, floating bookmark button, logo
/// chip) deliberately distinct from the Trending carousel's full-bleed
/// travel-card look, so the two sections read as different visual moments.
class FeaturedCollegesCarousel extends ConsumerWidget {
  const FeaturedCollegesCarousel({super.key});

  static const double _height = 258;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegesAsync = ref.watch(homeFeaturedCollegesProvider);

    return collegesAsync.when(
      loading: () => SizedBox(
        height: _height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, _) => SizedBox(
            width: 236,
            child: CollegeCardSkeleton(height: _height),
          ),
        ),
      ),
      error: (e, _) => SizedBox(
        height: _height,
        child: AsyncErrorView.fromError(
          e,
          compact: true,
          onRetry: () => ref.invalidate(homeFeaturedCollegesProvider),
        ),
      ),
      data: (colleges) {
        if (colleges.isEmpty) {
          // Not height-constrained like the loading/data states — the
          // empty illustration needs more room than the compact card row.
          return const AsyncEmptyView(
            icon: Icons.school_outlined,
            title: 'No featured colleges yet',
            subtitle: 'Colleges will appear here once the directory is seeded.',
          );
        }
        return SizedBox(
          height: _height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: colleges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) => PremiumFeaturedCollegeCard(
              college: colleges[index],
              height: _height,
            ),
          ),
        );
      },
    );
  }
}

/// Airbnb-listing-style discovery card: inset rounded photo with a floating
/// bookmark button and verified pill, a logo chip riding the bottom edge of
/// the photo, then name/location/rating below.
class PremiumFeaturedCollegeCard extends ConsumerStatefulWidget {
  final CollegeModel college;
  final double height;

  const PremiumFeaturedCollegeCard({
    required this.college,
    this.height = 258,
    super.key,
  });

  @override
  ConsumerState<PremiumFeaturedCollegeCard> createState() => _PremiumFeaturedCollegeCardState();
}

class _PremiumFeaturedCollegeCardState extends ConsumerState<PremiumFeaturedCollegeCard> {
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
    final college = widget.college;
    final crScore = CrScoreEngine.effectiveScore(college);
    final isVerified = college.verifiedStudentCount > 0 || college.reviewCount >= 3;
    final favoriteIds = ref.watch(favoriteCollegeIdsProvider).valueOrNull ?? {};
    final isSaved = favoriteIds.contains(college.id);
    const cardWidth = 236.0;
    const photoHeight = 148.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.go(RouteNames.collegeDetailsPath(college.id)),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: cardWidth,
          height: widget.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: photoHeight,
                width: cardWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: (college.coverPhotoUrl ?? '').isEmpty
                          ? CompactCollegeFallback(
                              initial: college.name.isNotEmpty ? college.name[0].toUpperCase() : 'C',
                              height: photoHeight,
                              width: cardWidth,
                            )
                          : CollegeImageWidget(
                              collegeId: college.id,
                              imageUrl: college.coverPhotoUrl,
                              height: photoHeight,
                              width: cardWidth,
                            ),
                    ),
                    if (isVerified)
                      const Positioned(
                        top: 10,
                        left: 10,
                        child: SolidStatusBadge(
                          label: 'Verified',
                          color: Color(0xFF059669),
                          icon: Icons.verified_rounded,
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _BookmarkButton(isSaved: isSaved, onTap: _toggleSave),
                    ),
                    if (crScore > 0)
                      Positioned(
                        left: 10,
                        bottom: -14,
                        child: _MiniCrBadge(score: crScore),
                      ),
                    Positioned(
                      right: 10,
                      bottom: -14,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: CollegeLogoWidget(
                          collegeId: college.id,
                          collegeName: college.name,
                          logoUrl: college.logoUrl,
                          radius: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      college.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.plusJakarta(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                        letterSpacing: -0.2,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: tokens.textTertiary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${college.city}, ${college.state}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.plusJakarta(fontSize: 11, color: tokens.textTertiary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (college.aggregatedRatings.overall > 0) ...[
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                          const SizedBox(width: 2),
                          Text(
                            college.aggregatedRatings.overall.toStringAsFixed(1),
                            style: AppFonts.plusJakarta(fontSize: 12, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                          ),
                          Text(
                            ' (${college.reviewCount})',
                            style: AppFonts.plusJakarta(fontSize: 11, fontWeight: FontWeight.w500, color: tokens.textTertiary),
                          ),
                        ] else
                          Text(
                            'New listing',
                            style: AppFonts.plusJakarta(fontSize: 11, fontWeight: FontWeight.w600, color: tokens.textTertiary),
                          ),
                        const Spacer(),
                        if (college.placements.averagePackageLpa > 0)
                          Text(
                            '₹${college.placements.averagePackageLpa.toStringAsFixed(1)}L',
                            style: AppFonts.plusJakarta(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF059669)),
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
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
            ],
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

class _MiniCrBadge extends StatelessWidget {
  final double score;

  const _MiniCrBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = CrScoreConstants.colorForScore(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(
        'CR ${score.toStringAsFixed(0)}',
        style: AppFonts.plusJakarta(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}
