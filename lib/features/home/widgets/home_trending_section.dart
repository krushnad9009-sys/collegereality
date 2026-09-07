import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/widgets/college_image_widget.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../colleges/models/college_model.dart';
import '../../ranking/utils/cr_score_engine.dart';
import '../providers/home_content_provider.dart';

const double _kCardWidth = 208;
const double _kMediaHeight = _kCardWidth / 16 * 9;
const double _kCardHeight = _kMediaHeight + 92;

/// "Trending Colleges" — a live horizontal carousel of the most
/// searched / reviewed colleges right now ([trendingCollegesProvider]),
/// each card rank-badged (#1, #2, …). Replaces the old static
/// "Know the reality before you decide" panel. Renders nothing while empty
/// so it never becomes dead space.
class HomeTrendingSection extends ConsumerWidget {
  const HomeTrendingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingCollegesProvider);

    return trendingAsync.when(
      loading: () => const _TrendingHeaderWrap(child: _SkeletonRow()),
      error: (_, _) => const SizedBox.shrink(),
      data: (colleges) {
        if (colleges.isEmpty) return const SizedBox.shrink();
        final items = colleges.take(10).toList();
        return _TrendingHeaderWrap(
          child: SizedBox(
            height: _kCardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                return _TrendingCard(college: items[i], rank: i + 1)
                    .animate()
                    .fadeIn(
                      delay: (55 * i).ms,
                      duration: 340.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .slideX(
                      begin: 0.14,
                      end: 0,
                      delay: (55 * i).ms,
                      duration: 340.ms,
                      curve: Curves.easeOutCubic,
                    );
              },
            ),
          ),
        );
      },
    );
  }
}

class _TrendingHeaderWrap extends StatelessWidget {
  final Widget child;
  const _TrendingHeaderWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trending Colleges',
                      style: AppFonts.plusJakarta(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.15,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Most searched & reviewed right now',
                      style: AppFonts.plusJakarta(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: tokens.textTertiary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kCardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => const SkeletonBox(
          width: _kCardWidth,
          height: _kCardHeight,
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
    );
  }
}

class _TrendingCard extends StatefulWidget {
  final CollegeModel college;
  final int rank;

  const _TrendingCard({required this.college, required this.rank});

  @override
  State<_TrendingCard> createState() => _TrendingCardState();
}

class _TrendingCardState extends State<_TrendingCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.college;
    final crScore = CrScoreEngine.effectiveScore(c);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.go(RouteNames.collegeDetailsPath(c.id)),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          width: _kCardWidth,
          height: _kCardHeight,
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.borderSubtle),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: _kMediaHeight,
                    width: _kCardWidth,
                    child: CollegeImageWidget(
                      collegeId: c.id,
                      imageUrl: c.coverPhotoUrl,
                      collegeName: c.name,
                      height: _kMediaHeight,
                      width: _kCardWidth,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: _kMediaHeight * 0.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.34),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _RankBadge(rank: widget.rank),
                  ),
                  if (crScore > 0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: context.tokens.accentWarm,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'CR ${crScore.toStringAsFixed(0)}',
                              style: AppFonts.plusJakarta(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.plusJakarta(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.2,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: tokens.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              c.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.plusJakarta(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: tokens.textTertiary,
                              ),
                            ),
                          ),
                          if (c.reviewCount > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${c.reviewCount} reviews',
                              style: AppFonts.plusJakarta(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
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

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            '#$rank',
            style: AppFonts.plusJakarta(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
