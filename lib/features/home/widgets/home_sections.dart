import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_theme.dart';
import '../../assistant/widgets/ai_search_bar.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../careers/models/careers_models.dart';
import '../../colleges/models/college_model.dart';
import '../../reviews/models/review_model.dart';
import '../../reviews/widgets/star_rating_widget.dart';
import '../providers/home_content_provider.dart';
import 'college_card_widget.dart';
import 'premium_college_carousel_card.dart';

class TrendingCollegesCarousel extends ConsumerWidget {
  const TrendingCollegesCarousel({super.key});

  static const double carouselHeight = 360;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trendingCollegesProvider);

    return async.when(
      loading: () => SizedBox(
        height: carouselHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, _) => SizedBox(
            width: 300,
            child: CollegeCardSkeleton(
              height: TrendingCollegesCarousel.carouselHeight,
            ),
          ),
        ),
      ),
      error: (e, _) => SizedBox(
        height: carouselHeight,
        child: AsyncErrorView.fromError(
          e,
          compact: true,
          onRetry: () => ref.invalidate(trendingCollegesProvider),
        ),
      ),
      data: (colleges) {
        if (colleges.isEmpty) {
          return SizedBox(
            height: carouselHeight,
            child: const AsyncEmptyView(
              icon: Icons.school_outlined,
              title: 'No trending colleges yet',
              subtitle: 'Featured campuses will appear here soon.',
            ),
          );
        }
        return SizedBox(
          height: carouselHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: colleges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return PremiumCollegeCarouselCard(
                college: colleges[index],
                height: carouselHeight,
              );
            },
          ),
        );
      },
    );
  }
}

class TopRatedCollegesSection extends ConsumerWidget {
  const TopRatedCollegesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topRatedCollegesProvider);

    return async.when(
      loading: () => Column(
        children: List.generate(
          2,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: CollegeCardSkeleton(),
          ),
        ),
      ),
      error: (e, _) => AsyncErrorView.fromError(
        e,
        compact: true,
        onRetry: () => ref.invalidate(topRatedCollegesProvider),
      ),
      data: (colleges) {
        if (colleges.isEmpty) {
          return const AsyncEmptyView(
            icon: Icons.star_outline_rounded,
            title: 'No top-rated colleges yet',
            subtitle: 'Ratings will appear here as reviews come in.',
          );
        }
        return Column(
          children: colleges
              .take(4)
              .map(
                (college) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: CollegeCardWidget.fromCollege(
                    college,
                    onTap: () =>
                        context.go(RouteNames.collegeDetailsPath(college.id)),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class AiAssistantHomeCard extends StatelessWidget {
  const AiAssistantHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AiSearchBar();
  }
}

/// Obvious, tap-first home entry point into the paid "Talk to a Verified
/// Student/Alumni" consultation flow (browse guides -> checkout -> call).
/// Previously this was only reachable via a buried Profile menu button, so
/// the feature existed in code without a visible home-screen entry point.
class PremiumConsultationHomeCard extends StatelessWidget {
  const PremiumConsultationHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go(RouteNames.guidesDirectory),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Talk to a Verified Student or Alumni',
                      style: AppFonts.plusJakarta(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Book a private 1:1 call — real answers on admissions, hostel & placements',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.plusJakarta(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Obvious home entry point into side-by-side college comparison. Previously
/// only reachable from within a college's own detail screen, so users had
/// no way to start a comparison without first opening a specific college.
class CompareCollegesHomeCard extends StatelessWidget {
  const CompareCollegesHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go(RouteNames.compare),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.compare_arrows_rounded,
                  color: primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compare Colleges',
                      style: AppFonts.plusJakarta(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fees, placements, hostel & ratings — side by side',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.plusJakarta(
                        fontSize: 12,
                        color: tokens.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: tokens.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PopularCitiesSection extends StatelessWidget {
  static const _cities = [
    ('Mumbai', 'Maharashtra'),
    ('Delhi', 'Delhi'),
    ('Bangalore', 'Karnataka'),
    ('Pune', 'Maharashtra'),
    ('Hyderabad', 'Telangana'),
    ('Chennai', 'Tamil Nadu'),
    ('Kolkata', 'West Bengal'),
    ('Ahmedabad', 'Gujarat'),
  ];

  const PopularCitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _cities.map((entry) {
        return PremiumChip(
          label: entry.$1,
          icon: Icons.location_city_rounded,
          onTap: () => context.go(
            '${RouteNames.collegeSearch}?city=${Uri.encodeComponent(entry.$1)}&state=${Uri.encodeComponent(entry.$2)}',
          ),
        );
      }).toList(),
    );
  }
}

class TopBranchesSection extends StatelessWidget {
  static const _branches = [
    'B.Tech',
    'MBA',
    'MBBS',
    'BBA',
    'B.Com',
    'LLB',
    'B.Arch',
    'MCA',
  ];

  const TopBranchesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _branches.map((course) {
        return PremiumChip(
          label: course,
          icon: Icons.menu_book_rounded,
          onTap: () => context.go(
            '${RouteNames.collegeSearch}?course=${Uri.encodeComponent(course)}',
          ),
        );
      }).toList(),
    );
  }
}

class BrowseByCategorySection extends ConsumerWidget {
  const BrowseByCategorySection({super.key});

  static const _categories = [
    ('Engineering', Icons.precision_manufacturing_rounded),
    ('Medical', Icons.local_hospital_rounded),
    ('MBA', Icons.business_center_rounded),
    ('Law', Icons.gavel_rounded),
    ('Pharmacy', Icons.medication_rounded),
    ('Commerce', Icons.account_balance_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _categories.map((entry) {
            return PremiumChip(
              label: entry.$1,
              icon: entry.$2,
              onTap: () => context.go(
                '${RouteNames.collegeSearch}?category=${Uri.encodeComponent(entry.$1)}',
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => context.go(RouteNames.collegeBrowse),
          icon: const Icon(Icons.grid_view_rounded, size: 18),
          label: const Text('View all categories'),
        ),
      ],
    );
  }
}

class StudentReviewsSection extends ConsumerWidget {
  const StudentReviewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeRecentReviewsProvider);

    return async.when(
      loading: () => Column(
        children: List.generate(
          2,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: SkeletonBox(height: 100),
          ),
        ),
      ),
      error: (e, _) => AsyncErrorView.fromError(
        e,
        onRetry: () => ref.invalidate(homeRecentReviewsProvider),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          final tokens = context.tokens;
          return PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 40, color: tokens.textTertiary),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share an honest review',
                  style: AppFonts.plusJakarta(
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go(RouteNames.collegeSearch),
                  child: const Text('Find a College'),
                ),
              ],
            ),
          );
        }
        return Column(
          children: reviews
              .map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReviewCard(review: r),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return PremiumCard(
      onTap: () => context.go(RouteNames.collegeDetailsPath(review.collegeId)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primary.withValues(alpha: 0.12),
                child: Text(
                  review.anonymousAlias.isNotEmpty
                      ? review.anonymousAlias[0].toUpperCase()
                      : 'S',
                  style: AppFonts.plusJakarta(
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.anonymousAlias,
                      style: AppFonts.plusJakarta(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    Text(
                      review.collegeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.plusJakarta(
                        fontSize: 11,
                        color: tokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              StarRatingDisplay(
                rating: review.overallRating,
                starSize: 12,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.textReview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.plusJakarta(
              fontSize: 13,
              height: 1.45,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class AlumniStoriesSection extends ConsumerWidget {
  const AlumniStoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeAlumniStoriesProvider);

    return async.when(
      loading: () => SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => const SizedBox(
            width: 260,
            child: SkeletonBox(height: 120),
          ),
        ),
      ),
      error: (e, _) => AsyncErrorView.fromError(
        e,
        onRetry: () => ref.invalidate(homeAlumniStoriesProvider),
      ),
      data: (alumni) {
        if (alumni.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: alumni.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _AlumniStoryCard(alumni: alumni[index]),
          ),
        );
      },
    );
  }
}

class _AlumniStoryCard extends StatelessWidget {
  final AlumniProfileModel alumni;

  const _AlumniStoryCard({required this.alumni});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final secondary = Theme.of(context).colorScheme.secondary;
    return PremiumCard(
      onTap: () => context.go(RouteNames.careersAlumni),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: secondary.withValues(alpha: 0.15),
                  child: Text(
                    alumni.displayName.isNotEmpty
                        ? alumni.displayName[0].toUpperCase()
                        : 'A',
                    style: AppFonts.plusJakarta(
                      fontWeight: FontWeight.w700,
                      color: secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alumni.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.plusJakarta(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      Text(
                        '${alumni.jobTitle} · ${alumni.company}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.plusJakarta(
                          fontSize: 11,
                          color: tokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              alumni.successStory,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.plusJakarta(
                fontSize: 12,
                height: 1.4,
                color: tokens.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              'Batch ${alumni.batchYear} · ${alumni.collegeName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.plusJakarta(
                fontSize: 10,
                color: tokens.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlacementHighlightsSection extends ConsumerWidget {
  const PlacementHighlightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homePlacementHighlightsProvider);

    return async.when(
      loading: () => Column(
        children: List.generate(
          2,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: SkeletonBox(height: 72),
          ),
        ),
      ),
      error: (e, _) => AsyncErrorView.fromError(
        e,
        onRetry: () => ref.invalidate(homePlacementHighlightsProvider),
      ),
      data: (colleges) {
        if (colleges.isEmpty) return const SizedBox.shrink();
        return Column(
          children: colleges
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PlacementTile(college: c),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _PlacementTile extends StatelessWidget {
  final CollegeModel college;

  const _PlacementTile({required this.college});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final avg = college.placements.averagePackageLpa;
    final pct = college.placements.placementPercentage;

    return PremiumCard(
      onTap: () => context.go(RouteNames.collegeDetailsPath(college.id)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppTheme.accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  college.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.plusJakarta(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  '${college.city} · ${pct > 0 ? '$pct% placed' : 'Placements tracked'}',
                  style: AppFonts.plusJakarta(
                    fontSize: 11,
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (avg > 0)
            Text(
              '₹${avg.toStringAsFixed(1)}L',
              style: AppFonts.plusJakarta(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentColor,
              ),
            ),
        ],
      ),
    );
  }
}
