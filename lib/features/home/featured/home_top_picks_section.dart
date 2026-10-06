import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/widgets/college_image_widget.dart';
import '../../colleges/models/college_model.dart';
import '../../communication/models/public_guide_profile.dart';
import 'home_featured_provider.dart';
import '../../../core/navigation/safe_navigation.dart';

const double _kCollegeCardWidth = 196;
const double _kCollegeMediaHeight = _kCollegeCardWidth / 16 * 9;
const double _kCollegeCardHeight = _kCollegeMediaHeight + 78;
const double _kGuideCardWidth = 150;
const double _kGuideCardHeight = 168;

/// "Top Picks" -- the Super Admin-curated colleges and guides (Admin panel
/// → Featured / Top List), in their chosen order, near the top of Home.
/// Falls back to top-rated colleges / top guides when nothing is pinned;
/// renders nothing at all if both rows are empty.
class HomeTopPicksSection extends ConsumerWidget {
  const HomeTopPicksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colleges = ref.watch(homeTopCollegesProvider).valueOrNull;
    final guides = ref.watch(homeTopGuidesProvider).valueOrNull;
    final hasColleges = colleges != null && colleges.items.isNotEmpty;
    final hasGuides = guides != null && guides.items.isNotEmpty;
    if (!hasColleges && !hasGuides) return const SizedBox.shrink();

    final curated = (colleges?.curated ?? false) || (guides?.curated ?? false);
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Picks',
                    style: AppFonts.plusJakarta(
                      fontSize: 21,
                      fontWeight: tokens.headingWeight,
                      letterSpacing: -0.4,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    curated
                        ? 'Handpicked by the College Kundli team'
                        : 'Top rated right now',
                    style: AppFonts.plusJakarta(
                      fontSize: 13.5,
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hasColleges) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: _kCollegeCardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: colleges.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _CollegePickCard(
                college: colleges.items[i],
                position: colleges.curated ? i + 1 : null,
              ),
            ),
          ),
        ],
        if (hasGuides) ...[
          const SizedBox(height: 16),
          Text(
            'Top guides',
            style: AppFonts.plusJakarta(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _kGuideCardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: guides.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _GuidePickCard(guide: guides.items[i]),
            ),
          ),
        ],
      ],
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  final tokens = context.tokens;
  return BoxDecoration(
    color: tokens.surfaceElevated,
    borderRadius: BorderRadius.circular(tokens.cardRadius),
    border: Border.all(color: tokens.borderSubtle),
  );
}

class _CollegePickCard extends StatelessWidget {
  final CollegeModel college;
  final int? position;

  const _CollegePickCard({required this.college, this.position});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = college;
    final rating = c.aggregatedRatings.overall;
    return GestureDetector(
      onTap: () => context.go(RouteNames.collegeDetailsPath(c.id)),
      child: Container(
        width: _kCollegeCardWidth,
        decoration: _cardDecoration(context),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CollegeImageWidget(
                  collegeId: c.id,
                  imageUrl: c.coverPhotoUrl,
                  collegeName: c.name,
                  height: _kCollegeMediaHeight,
                  width: _kCollegeCardWidth,
                ),
                if (position != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '#$position',
                        style: AppFonts.plusJakarta(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      fontWeight: tokens.headingWeight,
                      height: 1.2,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      c.city,
                      if (rating > 0) '★ ${rating.toStringAsFixed(1)}',
                    ].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.plusJakarta(
                      fontSize: 11.5,
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidePickCard extends StatelessWidget {
  final PublicGuideProfile guide;

  const _GuidePickCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final g = guide;
    final online = g.presence.isLiveOnline;
    final rating = g.stats.overallRating;
    final initials = g.displayName.trim().isEmpty
        ? '?'
        : g.displayName.trim().characters.first.toUpperCase();
    return GestureDetector(
      onTap: () => context.pushOnce(RouteNames.guideProfilePath(g.uid)),
      child: Container(
        width: _kGuideCardWidth,
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(context),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      g.photoURL != null ? NetworkImage(g.photoURL!) : null,
                  child: g.photoURL == null ? Text(initials) : null,
                ),
                if (online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: tokens.surfaceElevated, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              g.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.plusJakarta(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              g.collegeName ?? 'Verified guide',
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.plusJakarta(
                fontSize: 11,
                color: tokens.textTertiary,
              ),
            ),
            const Spacer(),
            Text(
              [
                if (rating > 0) '★ ${rating.toStringAsFixed(1)}',
                online ? 'Online' : 'Offline',
              ].join(' · '),
              style: AppFonts.plusJakarta(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: online ? Colors.green.shade700 : tokens.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
