import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/premium_home_theme.dart';
import '../../../core/bootstrap/startup_bootstrap.dart';
import '../../../core/cache/college_session_cache.dart';
import '../../../core/cache/firestore_quota_guard.dart';
import '../../../core/providers/firestore_quota_provider.dart';
import '../../../core/widgets/premium_components.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../../admin/providers/platform_settings_provider.dart';
import '../../admin/services/admin_ads_service.dart';
import '../../personalization/providers/personalized_colleges_provider.dart';
import '../providers/home_content_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/deferred_incoming_call_banner.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/explore_by_city_section.dart';
import '../widgets/explore_category_section.dart';
import '../widgets/home_core_features_grid.dart';
import '../widgets/home_hero_panel.dart';
import '../widgets/home_more_section.dart';
import '../widgets/home_personalized_sections.dart';
import '../widgets/home_trending_section.dart';

/// Home screen information hierarchy — one purpose per section, no
/// conceptual duplication:
///   1. Hero            → full-bleed royal-blue header: top bar (menu, title,
///                        search, filter, bell, avatar), greeting, search bar
///   2. Category chips  → one scrolling row of compact tinted pills
///   3. Explore by City → circular city badges
///   4. Core features   → Talk to a Verified Student · AI Assistant · Compare
///   5. Trending        → live carousel of the most searched/reviewed colleges
///   6. Recommended     → colleges in the user's most-searched stream
///                        (global top-rated until a stream is known)
///   7. Near You        → colleges in the user's state (hidden if unknown)
///   8. More            → secondary, genuinely useful links only
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
    ref.invalidate(recommendedCollegesProvider);
    ref.invalidate(collegesNearYouProvider);
    ref.invalidate(featuredCollegesProvider);
    ref.invalidate(trendingCollegesProvider);
    ref.invalidate(topRatedCollegesProvider);
    ref.invalidate(maharashtraCollegesProvider);
    ref.invalidate(homeRecentReviewsProvider);
    ref.invalidate(homeAlumniStoriesProvider);
    ref.invalidate(homePlacementHighlightsProvider);
    await ref.read(collegeSeedProvider.future);
    await ref.read(homeFeaturedCollegesProvider.future);
    await ref.read(recommendedCollegesProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(firestoreQuotaCoordinatorProvider);
    final quotaBlocked = ref.watch(firestoreQuotaBlockedProvider);
    final gutter = homeContentGutter(context);
    final authState = ref.watch(authProvider);
    final currentUser = authState.user ?? FirebaseAuth.instance.currentUser;
    final userDetail = ref.watch(currentUserDetailProvider).valueOrNull;

    final displayName =
        userDetail?.effectivePublicDisplayName ??
        currentUser?.displayName ??
        'Student';

    final headerSubtitle = currentUser != null
        ? 'Real reviews & verified CR Scores, personalized for you'
        : 'Find the right college with real student information';

    // The screen is one confident block of royal blue (the hero header, with
    // the top bar inside it) over an off-white page. Everything sits inside
    // [PremiumHomeTheme]; cards get their depth from a hairline border and a
    // soft shadow rather than a tinted wash.
    return PremiumHomeTheme(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // White status-bar icons: the hero is dark blue.
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          // Default background = the theme's canvas (off-white).
          body: Builder(
            builder: (context) {
              final tokens = context.tokens;
              final topInset = MediaQuery.paddingOf(context).top;
              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: tokens.heroColor,
                    edgeOffset: topInset + 8,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        // ── 1. Royal-blue hero header (full-bleed) ────────
                        SliverToBoxAdapter(
                          child: HomeHeroPanel(
                            user: currentUser,
                            displayName: displayName,
                            subtitle: headerSubtitle,
                            // `this.context` sits above this Scaffold, so
                            // Scaffold.of resolves to the app shell's
                            // scaffold, which owns the navigation drawer.
                            onMenuPressed: () =>
                                Scaffold.maybeOf(this.context)?.openDrawer(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SafeArea(
                            top: false,
                            bottom: false,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: AppSpacing.maxContentWidth,
                                ),
                                child: Padding(
                                  // 20px sides (see homeContentGutter), with
                                  // air above the first row and below the last.
                                  padding: EdgeInsets.fromLTRB(
                                    gutter,
                                    AppSpacing.xl,
                                    gutter,
                                    AppSpacing.lg,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Top of the page, directly under the
                                      // hero's hamburger menu bar -- renders
                                      // nothing for a non-guide.
                                      const GuideOnlineStatusBar(),
                                      const DeferredIncomingCallBanner(),
                                      if (quotaBlocked) ...[
                                        _QuotaNoticeBanner(),
                                        const SizedBox(height: AppSpacing.lg),
                                      ],

                                      // ── 2. Category chips: one compact,
                                      // horizontally scrolling row ─────────
                                      FadeInSection(
                                        delayMs: 40,
                                        child: const ExploreCategoryChips(),
                                      ),
                                      const SizedBox(
                                        height: AppSpacing.section,
                                      ),

                                      // ── 3. Explore by City ────────────────
                                      FadeInSection(
                                        delayMs: 80,
                                        child: SectionHeader(
                                          title: 'Explore by City',
                                          subtitle: 'Find colleges near you',
                                          actionLabel: 'All cities',
                                          onAction: () => context.go(
                                            RouteNames.collegeBrowse,
                                          ),
                                        ),
                                      ),
                                      FadeInSection(
                                        delayMs: 100,
                                        child: const ExploreCityCarousel(),
                                      ),

                                      // Announcement + promo strips (usually
                                      // empty) sit below the browse rows.
                                      const _PlatformAnnouncementBanner(),
                                      const _HomePromoAdsStrip(),
                                      const SizedBox(
                                        height: AppSpacing.sectionXl,
                                      ),

                                      // ── 4. Core features — the three
                                      // primary actions ────────────────────
                                      FadeInSection(
                                        delayMs: 140,
                                        child: const HomeCoreFeaturesGrid(),
                                      ),
                                      const SizedBox(
                                        height: AppSpacing.sectionXl,
                                      ),

                                      // ── 5. Trending colleges ──────────────
                                      FadeInSection(
                                        delayMs: 180,
                                        child: const HomeTrendingSection(),
                                      ),
                                      const SizedBox(
                                        height: AppSpacing.sectionXl,
                                      ),

                                      // ── 6. Recommended for You (by stream) ─
                                      // Owns its header + trailing gap: the
                                      // title flips between "Recommended for
                                      // You" and the honest "Top Rated
                                      // Colleges" fallback.
                                      FadeInSection(
                                        delayMs: 220,
                                        child:
                                            const RecommendedCollegesSection(),
                                      ),

                                      // ── 7. Colleges Near You (by state) ────
                                      // Collapses entirely when the state is
                                      // unknown.
                                      FadeInSection(
                                        delayMs: 240,
                                        child: const CollegesNearYouSection(),
                                      ),

                                      // ── 8. More to Explore ─────────────────
                                      FadeInSection(
                                        delayMs: 260,
                                        child: const SectionHeader(
                                          title: 'More to Explore',
                                          subtitle:
                                              'A few other ways to use College Reality',
                                        ),
                                      ),
                                      FadeInSection(
                                        delayMs: 280,
                                        child: const HomeMoreSection(),
                                      ),

                                      // The bottom bar is docked; this inset
                                      // already includes its height.
                                      SizedBox(
                                        height:
                                            MediaQuery.paddingOf(
                                              context,
                                            ).bottom +
                                            AppSpacing.xl,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Keeps the status bar sitting on blue (with its white
                  // icons) while the page scrolls underneath it.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topInset,
                    child: ColoredBox(color: tokens.heroColor),
                  ),
                ],
              );
            },
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
            radius: tokens.cardRadius,
            padding: const EdgeInsets.all(AppSpacing.md),
            onTap: ad.ctaUrl.isEmpty
                ? null
                : () async {
                    final uri = Uri.tryParse(ad.ctaUrl);
                    if (uri == null) return;
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      tokens.buttonRadius * 0.65,
                    ),
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
