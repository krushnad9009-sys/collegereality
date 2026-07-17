import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/bootstrap/startup_bootstrap.dart';
import '../../../core/cache/college_session_cache.dart';
import '../../../core/widgets/premium_components.dart';
import '../../auth/providers/auth_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../providers/home_content_provider.dart';
import '../widgets/deferred_incoming_call_banner.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/home_sections.dart';
import '../widgets/premium_home_search_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(homeContentReadyProvider.notifier).state = true;
      StartupBootstrap.runAfterHomeVisible(ref);
    });
  }

  Future<void> _onRefresh() async {
    CollegeSessionCache.clearFeatured();
    ref.invalidate(collegeSeedProvider);
    ref.invalidate(homeFeaturedCollegesProvider);
    ref.invalidate(featuredCollegesProvider);
    ref.invalidate(trendingCollegesProvider);
    ref.invalidate(topRatedCollegesProvider);
    ref.invalidate(maharashtraCollegesProvider);
    ref.invalidate(homeRecentReviewsProvider);
    ref.invalidate(homeAlumniStoriesProvider);
    ref.invalidate(homePlacementHighlightsProvider);
    await ref.read(collegeSeedProvider.future);
    await ref.read(homeFeaturedCollegesProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final currentUser = authState.user ?? FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.gray900 : AppTheme.surfaceMuted,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInSection(
                    delayMs: 0,
                    child: currentUser != null
                        ? HomeHeaderWidget(user: currentUser)
                        : _GuestHomeHeader(onLogin: () => context.go(RouteNames.login)),
                  ),
                        const SizedBox(height: AppSpacing.md),
                        const DeferredIncomingCallBanner(),
                        const SizedBox(height: AppSpacing.lg),
                        FadeInSection(
                          delayMs: 60,
                          child: const PremiumHomeSearchBar(),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FadeInSection(
                          delayMs: 100,
                          child: SectionHeader(
                            title: 'Trending Colleges',
                            subtitle: 'Most explored this week',
                            actionLabel: 'See all',
                            onAction: () => context.go(RouteNames.collegeSearch),
                          ),
                        ),
                        FadeInSection(
                          delayMs: 120,
                          child: const TrendingCollegesCarousel(),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FadeInSection(
                          delayMs: 160,
                          child: SectionHeader(
                            title: 'Top Rated',
                            subtitle: 'Highest student ratings',
                            actionLabel: 'View all',
                            onAction: () => context.go(RouteNames.collegeSearch),
                          ),
                        ),
                        FadeInSection(
                          delayMs: 180,
                          child: const TopRatedCollegesSection(),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FadeInSection(
                          delayMs: 220,
                          child: SectionHeader(
                            title: 'AI Assistant',
                            subtitle: 'Personalized college recommendations',
                          ),
                        ),
                        FadeInSection(
                          delayMs: 240,
                          child: const AiAssistantHomeCard(),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FadeInSection(
                          delayMs: 280,
                          child: SectionHeader(
                            title: 'Popular Cities',
                            subtitle: 'Explore colleges by location',
                          ),
                        ),
                        FadeInSection(
                          delayMs: 300,
                          child: const PopularCitiesSection(),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FadeInSection(
                          delayMs: 340,
                          child: SectionHeader(
                            title: 'Top Branches',
                            subtitle: 'Browse by course',
                          ),
                        ),
                        FadeInSection(
                          delayMs: 360,
                          child: const TopBranchesSection(),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FadeInSection(
                          delayMs: 380,
                          child: SectionHeader(
                            title: 'Browse by Type',
                            subtitle: 'Engineering, Medical, MBA and more',
                            actionLabel: 'All',
                            onAction: () => context.go(RouteNames.collegeBrowse),
                          ),
                        ),
                        FadeInSection(
                          delayMs: 400,
                          child: const BrowseByCategorySection(),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FadeInSection(
                          delayMs: 420,
                          child: SectionHeader(
                            title: 'Student Reviews',
                            subtitle: 'Real experiences from verified students',
                            actionLabel: 'More',
                            onAction: () => context.go(RouteNames.community),
                          ),
                        ),
                        FadeInSection(
                          delayMs: 420,
                          child: const StudentReviewsSection(),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FadeInSection(
                          delayMs: 460,
                          child: SectionHeader(
                            title: 'Alumni Stories',
                            subtitle: 'Where graduates are today',
                            actionLabel: 'Explore',
                            onAction: () => context.go(RouteNames.careersAlumni),
                          ),
                        ),
                        FadeInSection(
                          delayMs: 480,
                          child: const AlumniStoriesSection(),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FadeInSection(
                          delayMs: 520,
                          child: SectionHeader(
                            title: 'Placement Highlights',
                            subtitle: 'Top packages & placement rates',
                          ),
                        ),
                        FadeInSection(
                          delayMs: 540,
                          child: const PlacementHighlightsSection(),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 96,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _GuestHomeHeader extends StatelessWidget {
  final VoidCallback onLogin;

  const _GuestHomeHeader({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'College Reality',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore 47,000+ colleges across India',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray600,
                    ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onLogin,
          child: const Text('Sign in'),
        ),
      ],
    );
  }
}
