import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/bootstrap/startup_bootstrap.dart';
import '../../../core/constants/college_constants.dart';
import '../../../core/cache/college_session_cache.dart';
import '../../../core/cache/firestore_quota_guard.dart';
import '../../../core/providers/firestore_quota_provider.dart';
import '../../../core/widgets/premium_components.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../../admin/providers/platform_settings_provider.dart';
import '../../admin/services/admin_ads_service.dart';
import '../providers/home_content_provider.dart';
import '../widgets/deferred_incoming_call_banner.dart';
import '../widgets/featured_colleges_section.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/home_hero_banner.dart';
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
    await FirestoreQuotaGuard.instance.retryNowIfAllowed();
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
    ref.watch(firestoreQuotaCoordinatorProvider);
    final quotaBlocked = ref.watch(firestoreQuotaBlockedProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final currentUser = authState.user ?? FirebaseAuth.instance.currentUser;
    final userDetail = ref.watch(currentUserDetailProvider).valueOrNull;

    final greeting = currentUser != null
        ? 'Hi, ${userDetail?.effectivePublicDisplayName ?? currentUser.displayName ?? 'Student'} 👋'
        : 'Find your dream college';

    final countAsync = ref.watch(collegeCountProvider);
    final guestSubtitle = countAsync.when(
      data: (total) => CollegeConstants.homeExploreLabel(liveCount: total),
      loading: () => CollegeConstants.homeExploreLabel(),
      error: (_, _) => CollegeConstants.homeExploreLabel(),
    );

    return Scaffold(
      backgroundColor: context.tokens.surfaceMuted,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: Theme.of(context).colorScheme.primary,
          edgeOffset: 8,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? AppSpacing.lg : AppSpacing.xxl,
                    AppSpacing.md,
                    isMobile ? AppSpacing.lg : AppSpacing.xxl,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInSection(
                        delayMs: 0,
                        child: HomeHeroBanner(
                          greeting: greeting,
                          subtitle: currentUser != null
                              ? 'Personalized recommendations, verified reviews & CR Scores'
                              : guestSubtitle,
                          trailing: currentUser != null
                              ? HomeHeaderActions(user: currentUser)
                              : TextButton(
                                  onPressed: () =>
                                      context.go(RouteNames.login),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.16),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                  ),
                                  child: const Text('Sign in'),
                                ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -18),
                        child: FadeInSection(
                          delayMs: 60,
                          child: const PremiumHomeSearchBar(),
                        ),
                      ),
                      const DeferredIncomingCallBanner(),
                      if (quotaBlocked) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _QuotaNoticeBanner(),
                      ],
                      const _PlatformAnnouncementBanner(),
                      const _HomePromoAdsStrip(),
                      const SizedBox(height: AppSpacing.lg),
                      FadeInSection(
                        delayMs: 80,
                        child: const FeaturedCollegesSection(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FadeInSection(
                        delayMs: 90,
                        child: const PremiumConsultationHomeCard(),
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
                          subtitle: 'Highest CR Scores & student ratings',
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
                        child: const SectionHeader(
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
                        delayMs: 250,
                        child: const CompareCollegesHomeCard(),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      FadeInSection(
                        delayMs: 280,
                        child: const SectionHeader(
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
                        delayMs: 380,
                        child: SectionHeader(
                          title: 'Browse by Category',
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
                        delayMs: 440,
                        child: const StudentReviewsSection(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FadeInSection(
                        delayMs: 450,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.go(RouteNames.requestCollege),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add My College'),
                          ),
                        ),
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
                        child: const SectionHeader(
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared icon-badge + text banner treatment used across the home screen's
/// informational strips (quota notice, platform announcement) so they read
/// as one consistent visual family instead of ad hoc gradient containers.
class _HomeInfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Widget child;

  const _HomeInfoBanner({
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(tokens.buttonRadius * 0.7),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _QuotaNoticeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return _HomeInfoBanner(
      icon: Icons.cloud_off_rounded,
      color: AppTheme.warningColor,
      child: Text(
        'Offline data • Live sync resumes automatically.',
        style: AppFonts.plusJakarta(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: tokens.textSecondary,
          height: 1.35,
        ),
      ),
    );
  }
}

class _PlatformAnnouncementBanner extends ConsumerWidget {
  const _PlatformAnnouncementBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(platformAnnouncementProvider);
    final bannerUrl = ref.watch(platformHomeBannerUrlProvider);
    if (text.isEmpty && bannerUrl.isEmpty) return const SizedBox.shrink();

    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        children: [
          if (text.isNotEmpty)
            _HomeInfoBanner(
              icon: Icons.campaign_outlined,
              color: primary,
              child: Text(
                text,
                style: AppFonts.plusJakarta(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          if (bannerUrl.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              child: Image.network(
                bannerUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomePromoAdsStrip extends ConsumerWidget {
  const _HomePromoAdsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(activeHomeAdsProvider);
    return adsAsync.maybeWhen(
      data: (ads) {
        if (ads.isEmpty) return const SizedBox.shrink();
        final ad = ads.first;
        final tokens = context.tokens;
        final primary = Theme.of(context).colorScheme.primary;
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: PremiumCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            onTap: ad.ctaUrl.isEmpty
                ? null
                : () async {
                    final uri = Uri.tryParse(ad.ctaUrl);
                    if (uri == null) return;
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  },
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(tokens.buttonRadius * 0.65),
                  ),
                  child: Icon(
                    Icons.local_offer_outlined,
                    size: 20,
                    color: primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ad.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.plusJakarta(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                      if (ad.body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          ad.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.plusJakarta(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: tokens.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (ad.ctaUrl.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    ad.ctaLabel,
                    style: AppFonts.plusJakarta(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: tokens.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
