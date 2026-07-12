import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/college_image_widget.dart';
import '../../reviews/providers/review_provider.dart';
import '../../reviews/widgets/review_card_widget.dart';
import '../../reviews/widgets/star_rating_widget.dart';
import '../models/college_model.dart';
import '../providers/college_provider.dart';

class CollegeDetailScreen extends ConsumerWidget {
  final String collegeId;

  const CollegeDetailScreen({required this.collegeId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegeAsync = ref.watch(collegeByIdProvider(collegeId));
    final currency = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

    return collegeAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error loading college: $e')),
      ),
      data: (college) {
        if (college == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('College not found')),
          );
        }

        return DefaultTabController(
          length: 7,
          child: Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => context.go(
                '${RouteNames.writeReviewPath(college.id)}?name=${Uri.encodeComponent(college.name)}',
              ),
              icon: const Icon(Icons.rate_review),
              label: const Text('Write Review'),
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: () => context.go(RouteNames.home),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      college.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CollegeImageWidget(
                          collegeId: college.id,
                          imageUrl: college.coverPhotoUrl,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.55),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CollegeHeader(college: college),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      isScrollable: true,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppTheme.gray500,
                      indicatorColor: AppTheme.primaryColor,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Placements'),
                        Tab(text: 'Faculty'),
                        Tab(text: 'Hostel'),
                        Tab(text: 'Fees'),
                        Tab(text: 'Ratings'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _OverviewTab(college: college),
                  _PlacementsTab(college: college),
                  _FacultyTab(college: college),
                  _HostelTab(college: college),
                  _FeesTab(college: college, currency: currency),
                  _RatingsTab(college: college),
                  _ReviewsTab(collegeId: college.id),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CollegeHeader extends StatelessWidget {
  final CollegeModel college;

  const _CollegeHeader({required this.college});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppTheme.gray500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  college.locationLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.gray600,
                  ),
                ),
              ),
              _TypeChip(type: college.type),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: AppTheme.warningColor, size: 20),
              const SizedBox(width: 4),
              Text(
                '${college.aggregatedRatings.overall}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' (${college.reviewCount} reviews)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.gray500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: college.courses
                .map(
                  (c) => Chip(
                    label: Text(c, style: GoogleFonts.poppins(fontSize: 12)),
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final CollegeModel college;

  const _OverviewTab({required this.college});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: 'Address',
          content: college.address,
          icon: Icons.place_outlined,
        ),
        if (college.website != null)
          _InfoCard(
            title: 'Website',
            content: college.website!,
            icon: Icons.language,
          ),
        _InfoCard(
          title: 'Courses Offered',
          content: college.courses.join(', '),
          icon: Icons.menu_book_outlined,
        ),
        if (college.scholarships.isNotEmpty)
          _InfoCard(
            title: 'Scholarships',
            content: college.scholarships
                .map((s) => '${s.name}: ${s.amount} (${s.eligibility})')
                .join('\n'),
            icon: Icons.card_giftcard_outlined,
          ),
      ],
    );
  }
}

class _PlacementsTab extends StatelessWidget {
  final CollegeModel college;

  const _PlacementsTab({required this.college});

  @override
  Widget build(BuildContext context) {
    final p = college.placements;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Highest Package',
                value: '${p.highestPackageLpa} LPA',
                icon: Icons.trending_up,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Average Package',
                value: '${p.averagePackageLpa} LPA',
                icon: Icons.analytics_outlined,
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Placement Rate',
          value: '${p.placementPercentage}%',
          icon: Icons.work_outline,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          'Top Recruiters',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: p.topRecruiters
              .map(
                (r) => Chip(
                  label: Text(r),
                  avatar: const Icon(Icons.business, size: 16),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _FacultyTab extends StatelessWidget {
  final CollegeModel college;

  const _FacultyTab({required this.college});

  @override
  Widget build(BuildContext context) {
    final ratings = college.aggregatedRatings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionRatingHeader(
          title: 'Faculty & Academics',
          rating: ratings.faculty,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _RatingBar(label: 'Faculty Quality', value: ratings.faculty),
        _RatingBar(label: 'Infrastructure', value: ratings.infrastructure),
        _RatingBar(label: 'Campus Life', value: ratings.campusLife),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Courses Offered',
          content: college.courses.join(', '),
          icon: Icons.menu_book_outlined,
        ),
        _InfoCard(
          title: 'College Type',
          content: college.type.toUpperCase(),
          icon: Icons.account_balance_outlined,
        ),
      ],
    );
  }
}

class _HostelTab extends StatelessWidget {
  final CollegeModel college;

  const _HostelTab({required this.college});

  @override
  Widget build(BuildContext context) {
    final ratings = college.aggregatedRatings;
    final currency = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionRatingHeader(
          title: 'Hostel & Accommodation',
          rating: ratings.hostel,
          icon: Icons.hotel_outlined,
        ),
        const SizedBox(height: 16),
        _RatingBar(label: 'Hostel Quality', value: ratings.hostel),
        const SizedBox(height: 16),
        _StatCard(
          label: 'Hostel Fee (Annual)',
          value: currency.format(college.fees.hostelAnnual),
          icon: Icons.hotel_outlined,
          color: AppTheme.accentColor,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Hostel Notes',
          content: ratings.hostel > 0
              ? 'Rating based on ${college.reviewCount} student reviews.'
              : 'No hostel reviews yet. Be the first to review!',
          icon: Icons.info_outline,
        ),
      ],
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  final String collegeId;

  const _ReviewsTab({required this.collegeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(collegeReviewsProvider(collegeId));

    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load reviews: $e')),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rate_review_outlined,
                      size: 64, color: AppTheme.gray400),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to share your experience!',
                    style: GoogleFonts.poppins(color: AppTheme.gray500),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return ReviewCardWidget(
              review: review,
              onLike: () async {
                await ref.read(reviewRepositoryProvider).likeReview(review.id);
                ref.invalidate(collegeReviewsProvider(collegeId));
              },
            );
          },
        );
      },
    );
  }
}

class _SectionRatingHeader extends StatelessWidget {
  final String title;
  final double rating;
  final IconData icon;

  const _SectionRatingHeader({
    required this.title,
    required this.rating,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.secondaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          StarRatingDisplay(rating: rating),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final double value;

  const _RatingBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text(
                value > 0 ? '${value.toStringAsFixed(1)}/5' : 'N/A',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value > 0 ? value / 5 : 0,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: AppTheme.gray200,
            color: AppTheme.warningColor,
          ),
        ],
      ),
    );
  }
}

class _RatingsTab extends StatelessWidget {
  final CollegeModel college;

  const _RatingsTab({required this.college});

  @override
  Widget build(BuildContext context) {
    final ratings = college.aggregatedRatings;
    final items = [
      ('Overall', ratings.overall),
      ('Faculty', ratings.faculty),
      ('Hostel', ratings.hostel),
      ('Placements', ratings.placements),
      ('Fees (Value)', ratings.fees),
      ('Infrastructure', ratings.infrastructure),
      ('Campus Life', ratings.campusLife),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.$1,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${item.$2}/5',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: item.$2 / 5,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: AppTheme.gray200,
                    color: AppTheme.warningColor,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FeesTab extends StatelessWidget {
  final CollegeModel college;
  final NumberFormat currency;

  const _FeesTab({required this.college, required this.currency});

  @override
  Widget build(BuildContext context) {
    final fees = college.fees;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCard(
          label: 'Tuition (Min)',
          value: currency.format(fees.tuitionMin),
          icon: Icons.payments_outlined,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Tuition (Max)',
          value: currency.format(fees.tuitionMax),
          icon: Icons.payments_outlined,
          color: AppTheme.secondaryColor,
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Hostel (Annual)',
          value: currency.format(fees.hostelAnnual),
          icon: Icons.hotel_outlined,
          color: AppTheme.accentColor,
        ),
        const SizedBox(height: 24),
        if (college.scholarships.isNotEmpty) ...[
          Text(
            'Available Scholarships',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...college.scholarships.map(
            (s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.school_outlined),
                title: Text(s.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('${s.eligibility}\n${s.amount}'),
                isThreeLine: true,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.gray600,
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.gray600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.secondaryColor,
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
