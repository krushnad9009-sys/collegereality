import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/premium_auth_background.dart';
import '../../../core/widgets/premium_components.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Welcome to College Reality',
      subtitle: 'Discover authentic reviews from students like you',
      description:
          'Get unfiltered insights about colleges before making your admission decision. Real students, real experiences.',
      icon: Icons.rate_review_rounded,
      color: const Color(0xFF6366F1),
    ),
    OnboardingPage(
      title: 'Search Smart',
      subtitle: 'Find colleges by city, state, or preferences',
      description:
          'Browse through India\'s top colleges with detailed information about placements, fees, infrastructure, and more.',
      icon: Icons.search_rounded,
      color: const Color(0xFF0EA5E9),
    ),
    OnboardingPage(
      title: 'Share Your Truth',
      subtitle: 'Help others with your authentic feedback',
      description:
          'Leave verified reviews anonymously. Your honest opinion matters and helps thousands of students make better choices.',
      icon: Icons.feedback_rounded,
      color: const Color(0xFF10B981),
    ),
    OnboardingPage(
      title: 'Make Informed Decisions',
      subtitle: 'Know before you go',
      description:
          'Compare colleges, check placements, explore hostel facilities, and find scholarships all in one place.',
      icon: Icons.verified_user_rounded,
      color: const Color(0xFFF59E0B),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);

      if (mounted) {
        context.go(RouteNames.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumAuthBackground(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final page = pages[index];
                return OnboardingPageView(
                  key: ValueKey(index),
                  page: page,
                  isMobile: isMobile,
                );
              },
              itemCount: pages.length,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: pages.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor: AppTheme.primaryColor,
                            dotColor: tokens.borderSubtle,
                            dotHeight: 8,
                            dotWidth: 8,
                            expansionFactor: 3,
                            spacing: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Row(
                        children: [
                          if (_currentPage > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 450),
                                    curve: Curves.easeOutCubic,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(tokens.buttonRadius),
                                  ),
                                ),
                                child: const Text('Back'),
                              ),
                            ),
                          if (_currentPage > 0)
                            const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            flex: _currentPage > 0 ? 1 : 1,
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(tokens.buttonRadius),
                                ),
                              ),
                              child: Text(
                                _currentPage == pages.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_currentPage == pages.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: TextButton(
                            onPressed: () => context.go(RouteNames.signup),
                            child: Text(
                              'Create Account',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageView extends StatelessWidget {
  final OnboardingPage page;
  final bool isMobile;

  const OnboardingPageView({
    required this.page,
    required this.isMobile,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.tokens;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            page.color.withValues(alpha: 0.12),
            page.color.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.section,
            AppSpacing.xxl,
            180 + bottomInset,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInSection(
                delayMs: 80,
                child: Container(
                  width: isMobile ? 128 : 168,
                  height: isMobile ? 128 : 168,
                  decoration: BoxDecoration(
                    color: page.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(tokens.cardRadius + 8),
                    boxShadow: [
                      BoxShadow(
                        color: page.color.withValues(alpha: 0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    page.icon,
                    size: isMobile ? 56 : 72,
                    color: page.color,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.section + 8),
              FadeInSection(
                delayMs: 140,
                child: Text(
                  page.title,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeInSection(
                delayMs: 200,
                child: Text(
                  page.subtitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: page.color,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FadeInSection(
                delayMs: 260,
                child: Text(
                  page.description,
                  style: textTheme.bodyLarge?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
