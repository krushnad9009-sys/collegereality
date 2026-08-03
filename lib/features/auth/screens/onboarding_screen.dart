import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_elevation.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/widgets/premium_auth_background.dart';
import '../widgets/onboarding/onboarding_controls.dart';
import '../widgets/onboarding/onboarding_illustrations.dart';
import '../widgets/onboarding/onboarding_page_content.dart';
import '../widgets/onboarding/onboarding_palette.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _breatheController;

  int _currentPage = 0;

  static const List<OnboardingPageData> _pages = [
    OnboardingPageData(
      pageIndex: 0,
      title: 'Real reviews.\nReal students.',
      subtitle: 'TRUST BEFORE YOU CHOOSE',
      description:
          'Discover honest college experiences from verified students — before you commit to your future.',
      scene: OnboardingScene.reviews,
    ),
    OnboardingPageData(
      pageIndex: 1,
      title: 'Compare colleges\nwith AI power.',
      subtitle: 'SMARTER SIDE-BY-SIDE',
      description:
          'Let intelligent insights cut through the noise and help you weigh colleges with clarity.',
      scene: OnboardingScene.aiCompare,
    ),
    OnboardingPageData(
      pageIndex: 2,
      title: 'Ask verified\nseniors anything.',
      subtitle: 'ANSWERS YOU CAN TRUST',
      description:
          'Get straight answers from students who actually studied there — no fluff, no marketing.',
      scene: OnboardingScene.verifiedQA,
    ),
    OnboardingPageData(
      pageIndex: 3,
      title: 'Decide with\npure confidence.',
      subtitle: 'YOUR ADMISSION MOMENT',
      description:
          'Walk into applications knowing exactly which college fits you — and why.',
      scene: OnboardingScene.confidentDecision,
    ),
  ];

  /// Reserve space for fixed bottom controls so PageView content never overlaps.
  double _bottomControlsHeight(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    const indicatorHeight = 8.0;
    const indicatorGap = AppSpacing.section;
    const buttonHeight = 52.0;
    const createAccountHeight = 44.0;
    const verticalPadding = AppSpacing.lg + AppSpacing.xl;

    var height = verticalPadding + indicatorHeight + indicatorGap + buttonHeight;
    if (isLastPage) height += createAccountHeight + AppSpacing.md;
    if (_currentPage > 0) {
      // Back button row uses same height; no extra space needed.
    }
    return height;
  }

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding({required String route}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) context.go(route);
  }

  Future<void> _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      await _pageController.nextPage(
        duration: AppMotion.slow,
        curve: AppMotion.easeOut,
      );
      return;
    }
    await _completeOnboarding(route: RouteNames.login);
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: AppMotion.slow,
      curve: AppMotion.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 900;
        final maxContentWidth = isMobile ? double.infinity : (isTablet ? 560.0 : 520.0);
        final horizontalPadding = isMobile ? AppSpacing.xxl : AppSpacing.section;
        final bottomInset = MediaQuery.of(context).padding.bottom;
        final controlsHeight = _bottomControlsHeight(context);
        final pageColors = OnboardingPalette.pageBackgroundFor(_currentPage);

        return Scaffold(
          backgroundColor: OnboardingPalette.warmWhite,
          body: PremiumAuthBackground(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: pageColors,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -80,
                  right: -60,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: OnboardingPalette.accentFor(_currentPage).withValues(alpha: 0.07),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _breatheController,
                  builder: (context, _) {
                    return PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            var pageOffset = 0.0;
                            if (_pageController.position.haveDimensions) {
                              pageOffset =
                                  (_pageController.page ?? index.toDouble()) - index;
                            }

                            return OnboardingPageContent(
                              key: ValueKey(index),
                              page: _pages[index],
                              pageOffset: pageOffset,
                              animationValue: _breatheController.value,
                              maxContentWidth: maxContentWidth,
                              bottomInset: bottomInset,
                              bottomControlsHeight: controlsHeight,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                  left: horizontalPadding,
                  right: horizontalPadding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Row(
                        children: [
                          Text(
                            'College Reality',
                            style: AppTypography.label('College Reality').copyWith(
                                  color: OnboardingPalette.ink,
                                  fontSize: 12,
                                  letterSpacing: 0.4,
                                ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _completeOnboarding(
                              route: RouteNames.login,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: OnboardingPalette.inkMuted,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                            ),
                            child: Text(
                              'Skip',
                              style: AppTypography.button('Skip').copyWith(
                                    color: OnboardingPalette.inkMuted,
                                    fontSize: 13,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          OnboardingPalette.warmWhite.withValues(alpha: 0),
                          OnboardingPalette.warmWhite.withValues(alpha: 0.92),
                          OnboardingPalette.warmWhite,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxContentWidth),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              AppSpacing.lg,
                              horizontalPadding,
                              AppSpacing.xl,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OnboardingPageIndicator(
                                  count: _pages.length,
                                  pageController: _pageController,
                                  currentPage: _currentPage,
                                ),
                                const SizedBox(height: AppSpacing.section),
                                Row(
                                  children: [
                                    if (_currentPage > 0) ...[
                                      Expanded(
                                        child: OnboardingGhostButton(
                                          label: 'Back',
                                          onPressed: _previousPage,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.lg),
                                    ],
                                    Expanded(
                                      child: OnboardingGradientButton(
                                        label: _currentPage == _pages.length - 1
                                            ? 'Get Started'
                                            : 'Next',
                                        pageIndex: _currentPage,
                                        onPressed: _nextPage,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_currentPage == _pages.length - 1)
                                  Padding(
                                    padding: const EdgeInsets.only(top: AppSpacing.md),
                                    child: TextButton(
                                      onPressed: () => context.go(RouteNames.signup),
                                      style: TextButton.styleFrom(
                                        foregroundColor: OnboardingPalette.royalBlue,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                          vertical: AppSpacing.sm,
                                        ),
                                      ),
                                      child: Text(
                                        'Create Account',
                                        style: AppTypography.button('Create Account').copyWith(
                                              color: OnboardingPalette.royalBlue,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Kept for backward compatibility if referenced elsewhere.
class OnboardingPage {
  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.illustration,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String description;
  final OnboardingIllustrationType illustration;
  final Color color;
}

enum OnboardingIllustrationType { welcome, search, share, decide }

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    required this.type,
    this.size = 220,
    super.key,
  });

  final OnboardingIllustrationType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scene = switch (type) {
      OnboardingIllustrationType.welcome => OnboardingScene.reviews,
      OnboardingIllustrationType.search => OnboardingScene.aiCompare,
      OnboardingIllustrationType.share => OnboardingScene.verifiedQA,
      OnboardingIllustrationType.decide => OnboardingScene.confidentDecision,
    };

    return OnboardingAnimatedIllustration(
      scene: scene,
      animationValue: 0,
      pageOffset: 0,
      size: size,
    );
  }
}
