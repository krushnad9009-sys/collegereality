import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/widgets/premium_auth_background.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/router/route_names.dart';

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
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // Mark onboarding as seen
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
              return OnboardingPageView(page: page, isMobile: isMobile);
            },
            itemCount: pages.length,
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: pages.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppTheme.primaryColor,
                        dotColor: AppTheme.gray300,
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Text('Back'),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _nextPage,
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
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton(
                        onPressed: () => context.go(RouteNames.signup),
                        child: const Text('Create Account'),
                      ),
                    ),
                ],
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            page.color.withValues(alpha: 0.1),
            page.color.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isMobile ? 120 : 160,
                height: isMobile ? 120 : 160,
                decoration: BoxDecoration(
                  color: page.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  page.icon,
                  size: isMobile ? 60 : 80,
                  color: page.color,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                page.title,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray900,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                page.subtitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: page.color,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                page.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray600,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
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
