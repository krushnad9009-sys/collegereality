import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trendingCollegesProvider);

    return async.when(
      loading: () => SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, _) => const SizedBox(
            width: 268,
            child: CollegeCardSkeleton(),
          ),
        ),
      ),
      error: (e, _) => AsyncErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(trendingCollegesProvider),
      ),
      data: (colleges) {
        if (colleges.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: colleges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return PremiumCollegeCarouselCard(college: colleges[index]);
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
      error: (e, _) => AsyncErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(topRatedCollegesProvider),
      ),
      data: (colleges) {
        if (colleges.isEmpty) return const SizedBox.shrink();
        return Column(
          children: colleges
              .take(4)
              .map(
                (college) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: CollegeCardWidget(
                    collegeId: college.id,
                    collegeName: college.name,
                    location: college.state,
                    city: college.city,
                    rating: college.aggregatedRatings.overall,
                    reviewCount: college.reviewCount,
                    imageUrl: college.coverPhotoUrl,
                    logoUrl: college.logoUrl,
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
      error: (e, _) => AsyncErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(homeRecentReviewsProvider),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 40, color: AppTheme.gray400),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share an honest review',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray600,
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
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  review.anonymousAlias.isNotEmpty
                      ? review.anonymousAlias[0].toUpperCase()
                      : 'S',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
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
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      review.collegeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.gray500,
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
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.gray700,
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
      error: (e, _) => AsyncErrorView(
        message: e.toString(),
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
                  backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.15),
                  child: Text(
                    alumni.displayName.isNotEmpty
                        ? alumni.displayName[0].toUpperCase()
                        : 'A',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.secondaryColor,
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
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${alumni.jobTitle} · ${alumni.company}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.gray500,
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
              style: GoogleFonts.poppins(fontSize: 12, height: 1.4),
            ),
            const Spacer(),
            Text(
              'Batch ${alumni.batchYear} · ${alumni.collegeName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.gray500,
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
      error: (e, _) => AsyncErrorView(
        message: e.toString(),
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
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${college.city} · ${pct > 0 ? '$pct% placed' : 'Placements tracked'}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.gray500,
                  ),
                ),
              ],
            ),
          ),
          if (avg > 0)
            Text(
              '₹${avg.toStringAsFixed(1)}L',
              style: GoogleFonts.poppins(
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
