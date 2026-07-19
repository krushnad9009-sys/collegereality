import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/rating_parameters.dart';
import '../../../core/utils/indian_currency_formatter.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/college_image_widget.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../engagement/providers/engagement_provider.dart';
import '../../reviews/models/review_model.dart';
import '../../reviews/providers/review_provider.dart';
import '../../reviews/widgets/review_card_widget.dart';
import '../../reviews/widgets/review_summary_panel.dart';
import '../../reviews/widgets/star_rating_widget.dart';
import '../../compare/providers/compare_basket_provider.dart';
import '../../compare/widgets/compare_basket_bar.dart';
import '../../placements/widgets/placements_tab_content.dart';
import '../../questions/widgets/college_questions_tab_content.dart';
import '../widgets/accreditation_badges.dart';
import '../widgets/college_gallery_widget.dart';
import '../widgets/college_map_section.dart';
import '../widgets/connect_students_section.dart';
import '../../ecosystem/widgets/college_ecosystem_menu.dart';
import '../../ecosystem/widgets/official_college_content_section.dart';
import '../models/college_model.dart';
import '../providers/college_provider.dart';

class CollegeDetailScreen extends ConsumerStatefulWidget {
  final String collegeId;
  final String? initialTab;

  const CollegeDetailScreen({
    required this.collegeId,
    this.initialTab,
    super.key,
  });

  @override
  ConsumerState<CollegeDetailScreen> createState() =>
      _CollegeDetailScreenState();
}

class _CollegeDetailScreenState extends ConsumerState<CollegeDetailScreen> {
  int _initialTabIndex() {
    switch (widget.initialTab) {
      case 'reviews':
        return 7;
      case 'ratings':
        return 6;
      case 'fees':
        return 5;
      case 'hostel':
        return 4;
      case 'faculty':
        return 3;
      case 'questions':
        return 2;
      case 'placements':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final collegeAsync = ref.watch(collegeByIdProvider(widget.collegeId));

    return collegeAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CollegeCardSkeleton()),
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

        final verifiedAsync = ref.watch(isVerifiedForReviewProvider);
        final basket = ref.watch(compareBasketProvider);
        final isInCompare = basket.contains(college.id);
        final favoriteIds = ref.watch(favoriteCollegeIdsProvider).valueOrNull ?? {};
        final isFavorite = favoriteIds.contains(college.id);
        final user = ref.read(currentUserProvider);

        return DefaultTabController(
          initialIndex: _initialTabIndex(),
          length: 8,
          child: Scaffold(
            floatingActionButton: verifiedAsync.when(
              loading: () => null,
              error: (_, _) => null,
              data: (isVerified) {
                if (!isVerified) {
                  return FloatingActionButton.extended(
                    onPressed: () => context.go(RouteNames.verification),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Verify to Review'),
                  );
                }
                return FloatingActionButton.extended(
                  elevation: 4,
                  onPressed: () => context.go(
                    '${RouteNames.writeReviewPath(college.id)}?name=${Uri.encodeComponent(college.name)}',
                  ),
                  icon: const Icon(Icons.rate_review),
                  label: const Text('Write Review'),
                );
              },
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  stretch: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: () => context.go(RouteNames.home),
                  ),
                  actions: [
                    CollegeEcosystemMenu(
                      collegeId: college.id,
                      collegeName: college.name,
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                        color: isFavorite ? AppTheme.accentColor : null,
                      ),
                      tooltip: isFavorite ? 'Remove bookmark' : 'Save college',
                      onPressed: user == null
                          ? null
                          : () async {
                              await ref
                                  .read(engagementRepositoryProvider)
                                  .toggleFavoriteCollege(user.uid, college.id);
                            },
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final message = ref
                            .read(compareBasketProvider.notifier)
                            .toggle(college.id);
                        if (message != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        }
                      },
                      icon: Icon(
                        isInCompare
                            ? Icons.check_circle_rounded
                            : Icons.compare_arrows_outlined,
                        size: 18,
                        color: isInCompare ? AppTheme.accentColor : null,
                      ),
                      label: Text(
                        isInCompare ? 'Added' : 'Compare',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go(
                        RouteNames.assistantPath(
                          collegeId: college.id,
                          collegeName: college.name,
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        'AI Assistant',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
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
                          height: 280,
                          fit: BoxFit.cover,
                          showComingSoonLabel: true,
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
                        Tab(text: 'Questions'),
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
                  PlacementsTabContent(college: college),
                  CollegeQuestionsTabContent(college: college),
                  _FacultyTab(college: college),
                  _HostelTab(college: college),
                  _FeesTab(college: college),
                  _RatingsTab(college: college),
                  _ReviewsTab(college: college),
                ],
              ),
            ),
            bottomNavigationBar: const CompareBasketBar(),
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
              if (college.logoUrl != null && college.logoUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(college.logoUrl!),
                  ),
                ),
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
          AccreditationBadges(
            accreditation: college.accreditation,
            universityName: college.universityName,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: college.displayCourses
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

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Future<void> _openPhone(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$digits');
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  Future<void> _openEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Gallery',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 10),
        CollegeGalleryWidget(photoUrls: college.photoUrls),
        const SizedBox(height: 20),
        Text(
          'Accreditation & Affiliation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 10),
        AccreditationBadges(
          accreditation: college.accreditation,
          universityName: college.universityName,
        ),
        const SizedBox(height: 20),
        CollegeMapSection(
          mapsLink: college.mapsLink,
          address: college.address,
          latitude: college.latitude,
          longitude: college.longitude,
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Address',
          content: college.address,
          icon: Icons.place_outlined,
        ),
        if (college.website != null && college.website!.trim().isNotEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.language, color: AppTheme.primaryColor),
              title: Text('Website', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text(college.website!),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _openUrl(context, college.website!),
            ),
          ),
        if (college.phone != null && college.phone!.trim().isNotEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
              title: Text('Phone', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text(college.phone!),
              onTap: () => _openPhone(context, college.phone!),
            ),
          ),
        if (college.email != null && college.email!.trim().isNotEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
              title: Text('Email', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text(college.email!),
              onTap: () => _openEmail(context, college.email!),
            ),
          ),
        if (college.officialLinks.isNotEmpty) ...[
          Text(
            'Official Links',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...college.officialLinks.map(
            (link) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.link, color: AppTheme.secondaryColor),
                title: Text(link, style: GoogleFonts.poppins(fontSize: 13)),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _openUrl(context, link),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        OfficialCollegeContentSection(collegeId: college.id),
        const SizedBox(height: 20),
        if (college.coursesDetailed.isNotEmpty) ...[
          Text(
            'Courses',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...college.coursesDetailed.map(
            (c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(c.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  [
                    if (c.degree.isNotEmpty) c.degree,
                    if (c.duration.isNotEmpty) c.duration,
                    if (c.seats > 0) '${c.seats} seats',
                    if (c.annualFees != null)
                      IndianCurrencyFormatter.format(c.annualFees!),
                  ].join(' · '),
                ),
              ),
            ),
          ),
        ] else
          _InfoCard(
            title: 'Courses Offered',
            content: college.displayCourses.join(', '),
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
    final hostel = college.hostel;
    final annualFee = hostel.annualFee > 0
        ? hostel.annualFee
        : college.fees.hostelAnnual;

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
          value: IndianCurrencyFormatter.format(annualFee),
          icon: Icons.hotel_outlined,
          color: AppTheme.accentColor,
        ),
        const SizedBox(height: 12),
        if (hostel.available) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hostel.boysHostel) const Chip(label: Text('Boys Hostel')),
              if (hostel.girlsHostel) const Chip(label: Text('Girls Hostel')),
              if (hostel.acAvailable) const Chip(label: Text('AC Rooms')),
              if (hostel.messIncluded) const Chip(label: Text('Mess Included')),
            ],
          ),
          if (hostel.amenities.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Amenities',
              content: hostel.amenities.join(', '),
              icon: Icons.checklist_outlined,
            ),
          ],
          if (hostel.description != null && hostel.description!.trim().isNotEmpty)
            _InfoCard(
              title: 'Hostel Details',
              content: hostel.description!,
              icon: Icons.info_outline,
            ),
        ] else
          _InfoCard(
            title: 'Hostel Notes',
            content: ratings.hostel > 0
                ? 'Rating based on ${college.reviewCount} student reviews.'
                : 'Hostel details have not been added for this college.',
            icon: Icons.info_outline,
          ),
      ],
    );
  }
}

class _ReviewsTab extends ConsumerStatefulWidget {
  final CollegeModel college;

  const _ReviewsTab({required this.college});

  @override
  ConsumerState<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends ConsumerState<_ReviewsTab> {
  final List<ReviewModel> _extraReviews = [];
  String? _cursor;
  bool _hasMore = true;
  bool _loadingMore = false;

  String get _collegeId => widget.college.id.trim();

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref.read(reviewRepositoryProvider).getReviewsPage(
            _collegeId,
            startAfterDocumentId: _cursor,
          );
      if (!mounted) return;
      setState(() {
        final existingIds = {
          ..._extraReviews.map((r) => r.id),
        };
        _extraReviews.addAll(
          page.reviews.where((r) => !existingIds.contains(r.id)),
        );
        _cursor = page.lastDocumentId;
        _hasMore = page.hasMore;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<ReviewModel> _mergeLists(List<ReviewModel> firstPage) {
    final byId = <String, ReviewModel>{};
    for (final r in firstPage) {
      byId[r.id] = r;
    }
    for (final r in _extraReviews) {
      byId[r.id] = r;
    }
    return byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(collegeReviewsProvider(_collegeId), (previous, next) {
      next.whenData((reviews) {
        ref.read(optimisticReviewsProvider.notifier).syncWithStream(
              _collegeId,
              reviews,
            );
        if (_cursor == null && reviews.isNotEmpty) {
          _cursor = reviews.last.id;
        }
      });
    });

    final reviewsAsync = ref.watch(mergedCollegeReviewsProvider(_collegeId));

    return reviewsAsync.when(
      loading: () => const ReviewListSkeleton(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 12),
              Text(
                'Failed to load reviews',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('$e', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (firstPage) {
        final reviews = _mergeLists(firstPage);

        if (reviews.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ReviewSummaryPanel(college: widget.college),
              const SizedBox(height: 8),
              ConnectStudentsSection(collegeId: _collegeId),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: 64,
                          color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'No reviews yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Only verified students and alumni can write reviews.',
                        style: GoogleFonts.poppins(color: AppTheme.gray500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length + 2 + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return ReviewSummaryPanel(college: widget.college);
            }
            if (index == 1) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ConnectStudentsSection(collegeId: _collegeId),
              );
            }

            final reviewIndex = index - 2;
            if (reviewIndex == reviews.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: _loadingMore
                      ? const CircularProgressIndicator()
                      : OutlinedButton(
                          onPressed: _loadMore,
                          child: const Text('Load more reviews'),
                        ),
                ),
              );
            }

            final review = reviews[reviewIndex];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 280 + (reviewIndex * 40)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: child,
                ),
              ),
              child: ReviewCardWidget(
                review: review,
                onHelpful: () async {
                  final user = ref.read(currentUserProvider);
                  if (user == null) return;
                  ref.read(optimisticHelpfulProvider.notifier).mark(review.id);
                  try {
                    await ref
                        .read(reviewRepositoryProvider)
                        .markHelpful(review.id, user.uid);
                    ref.invalidate(reviewHelpfulMarkedProvider(review.id));
                  } catch (e) {
                    ref
                        .read(optimisticHelpfulProvider.notifier)
                        .unmark(review.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  }
                },
                onReport: () => _showReportDialog(context, ref, review),
              ),
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

Future<void> _showReportDialog(
  BuildContext context,
  WidgetRef ref,
  ReviewModel review,
) async {
  final controller = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Report Review'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Why is this review inappropriate?',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Report'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (reason == null || reason.isEmpty) return;

  final user = ref.read(currentUserProvider);
  if (user == null) return;

  await ref.read(reviewRepositoryProvider).reportReview(
        reviewId: review.id,
        collegeId: review.collegeId,
        reporterId: user.uid,
        reason: reason,
      );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review reported. Our team will review it.')),
    );
  }
}

class _RatingsTab extends StatelessWidget {
  final CollegeModel college;

  const _RatingsTab({required this.college});

  @override
  Widget build(BuildContext context) {
    final ratings = college.aggregatedRatings;
    final items = RatingParameters.allKeys
        .map((key) => (RatingParameters.labelFor(key), ratings.ratingFor(key)))
        .where((item) => item.$2 > 0)
        .toList();

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No verified ratings yet',
          style: GoogleFonts.poppins(color: AppTheme.gray500),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ReviewSummaryPanel(college: college),
        const SizedBox(height: 8),
        Text(
          'Category-wise ratings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
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
        ),
      ],
    );
  }
}

class _FeesTab extends StatelessWidget {
  final CollegeModel college;

  const _FeesTab({required this.college});

  @override
  Widget build(BuildContext context) {
    final fees = college.fees;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCard(
          label: 'Tuition (Min)',
          value: IndianCurrencyFormatter.format(fees.tuitionMin),
          icon: Icons.payments_outlined,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Tuition (Max)',
          value: IndianCurrencyFormatter.format(fees.tuitionMax),
          icon: Icons.payments_outlined,
          color: AppTheme.secondaryColor,
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Hostel (Annual)',
          value: IndianCurrencyFormatter.format(fees.hostelAnnual),
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
