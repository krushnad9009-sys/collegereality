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
import '../widgets/explore_by_city_section.dart';
import '../widgets/explore_category_section.dart';
import '../widgets/home_college_discovery_card.dart';
import '../widgets/home_compare_section.dart';
import '../widgets/home_hero_panel.dart';
import '../widgets/home_more_section.dart';
import '../widgets/home_trust_section.dart';

/// Home screen information hierarchy — one purpose per section, no
/// conceptual duplication:
///   1. Hero        → greeting + dominant search + quick discovery chips
///   2. Explore      → browse by stream
///   3. Discover     → the one college-recommendation carousel
///   4. Trust        → CR Score, real placement signal, one review, verified-student CTA
///   5. Compare      → the one comparison feature
///   6. City         → browse by location
///   7. More         → secondary, genuinely useful links only
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

    final displayName = userDetail?.effectivePublicDisplayName ??
        currentUser?.displayName ??
        'Student';

    final headerSubtitle = currentUser != null
        ? 'Real reviews & verified CR Scores, personalized for you'
        : 'Find the right college with real student information';

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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
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
                          // ── 1. Unified hero: greeting + search + chips ──
                          FadeInSection(
                            delayMs: 0,
                            child: HomeHeroPanel(
                              user: currentUser,
                              displayName: displayName,
                              subtitle: headerSubtitle,
                            ),
                          ),
                          const DeferredIncomingCallBanner(),
                          if (quotaBlocked) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _QuotaNoticeBanner(),
                          ],
                          const _PlatformAnnouncementBanner(),
                          const _HomePromoAdsStrip(),
                          const SizedBox(height: AppSpacing.sectionLg),

                          // ── 2. Explore Colleges ──────────────────────────
                          FadeInSection(
                            delayMs: 80,
                            child: SectionHeader(
                              title: 'Explore Colleges',
                              subtitle: 'Pick a stream to get started',
                              actionLabel: 'All categories',
                              onAction: () => context.go(RouteNames.collegeBrowse),
                            ),
                          ),
                          FadeInSection(
                            delayMs: 100,
                            child: const ExploreCategoryGrid(),
                          ),
                          const SizedBox(height: AppSpacing.sectionLg),

                          // ── 3. Featured / Recommended Colleges ───────────
                          FadeInSection(
                            delayMs: 140,
                            child: SectionHeader(
                              title: 'Recommended for You',
                              subtitle: 'Real colleges, real ratings — picked for you',
                              actionLabel: 'View all',
                              onAction: () => context.go(RouteNames.collegeSearch),
                            ),
                          ),
                          FadeInSection(
                            delayMs: 160,
                            child: const FeaturedCollegesSection(),
                          ),
                          const SizedBox(height: AppSpacing.sectionLg),

                          // ── 4. Trust: CR Score + placements + review + CTA
                          FadeInSection(
                            delayMs: 200,
                            child: const HomeTrustSection(),
                          ),
                          const SizedBox(height: AppSpacing.sectionLg),

                          // ── 5. Compare Colleges ──────────────────────────
                          FadeInSection(
                            delayMs: 240,
                            child: const HomeCompareSection(),
                          ),
                          const SizedBox(height: AppSpacing.sectionLg),

                          // ── 6. Explore by City ────────────────────────────
                          FadeInSection(
                            delayMs: 280,
                            child: const SectionHeader(
                              title: 'Explore by City',
                              subtitle: 'Find colleges near you',
                            ),
                          ),
                          FadeInSection(
                            delayMs: 300,
                            child: const ExploreCityCarousel(),
                          ),
                          const SizedBox(height: AppSpacing.sectionLg),

                          // ── 7. More to Explore ────────────────────────────
                          FadeInSection(
                            delayMs: 340,
                            child: const SectionHeader(
                              title: 'More to Explore',
                              subtitle: 'A few other ways to use College Reality',
                            ),
                          ),
                          FadeInSection(
                            delayMs: 360,
                            child: const HomeMoreSection(),
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
