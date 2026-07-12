import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/router/route_names.dart';
import '../../auth/providers/auth_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../communication/widgets/incoming_call_banner.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/college_card_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final collegesAsync = ref.watch(collegesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.gray900
          : AppTheme.white,
      body: SafeArea(
        child: currentUser == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(collegesProvider);
                  ref.invalidate(collegeSeederProvider);
                  await ref.read(collegesProvider.future);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HomeHeaderWidget(user: currentUser),
                        const IncomingCallBanner(),
                        if (!currentUser.emailVerified) ...[
                          const SizedBox(height: 12),
                          _EmailVerificationBanner(userId: currentUser.uid),
                        ],
                        const SizedBox(height: 24),
                        _SearchBar(onTap: () => context.go(RouteNames.collegeSearch)),
                        const SizedBox(height: 32),
                        Text(
                          'Quick Access',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _QuickAccessCard(
                                icon: Icons.support_agent_rounded,
                                label: 'Guides',
                                color: AppTheme.primaryColor,
                                onTap: () => context.go(RouteNames.guidesDirectory),
                              ),
                              const SizedBox(width: 12),
                              _QuickAccessCard(
                                icon: Icons.location_city_rounded,
                                label: 'By City',
                                color: AppTheme.primaryColor,
                                onTap: () => context.go(
                                  '${RouteNames.collegeSearch}?filter=city',
                                ),
                              ),
                              const SizedBox(width: 12),
                              _QuickAccessCard(
                                icon: Icons.map_rounded,
                                label: 'By State',
                                color: AppTheme.secondaryColor,
                                onTap: () => context.go(
                                  '${RouteNames.collegeSearch}?filter=state',
                                ),
                              ),
                              const SizedBox(width: 12),
                              _QuickAccessCard(
                                icon: Icons.star_rounded,
                                label: 'Top Rated',
                                color: AppTheme.accentColor,
                                onTap: () => context.go(RouteNames.collegeSearch),
                              ),
                              const SizedBox(width: 12),
                              _QuickAccessCard(
                                icon: Icons.trending_up_rounded,
                                label: 'All Colleges',
                                color: AppTheme.warningColor,
                                onTap: () => context.go(RouteNames.collegeSearch),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Featured Colleges',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go(RouteNames.collegeSearch),
                              child: Text(
                                'View All',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        collegesAsync.when(
                          loading: () => Column(
                            children: List.generate(
                              3,
                              (_) => const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: CollegeCardSkeleton(),
                              ),
                            ),
                          ),
                          error: (e, _) => Text('Failed to load colleges: $e'),
                          data: (colleges) {
                            final featured = colleges.take(6).toList();
                            return Column(
                              children: featured
                                  .map(
                                    (college) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: CollegeCardWidget(
                                        collegeId: college.id,
                                        collegeName: college.name,
                                        location: college.state,
                                        city: college.city,
                                        rating: college.aggregatedRatings.overall,
                                        reviewCount: college.reviewCount,
                                        imageUrl: college.coverPhotoUrl,
                                        onTap: () => context.go(
                                          RouteNames.collegeDetailsPath(college.id),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share Your Experience',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Help thousands of students by sharing your honest college review',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.white,
                                    foregroundColor: AppTheme.primaryColor,
                                  ),
                                  onPressed: () => context.go(RouteNames.collegeSearch),
                                  child: Text(
                                    'Write a Review',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.gray800
                : AppTheme.gray100,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.gray700
                  : AppTheme.gray200,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppTheme.gray500, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search colleges by name, city, or state...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray500,
                  ),
                ),
              ),
              const Icon(Icons.tune_rounded, color: AppTheme.primaryColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailVerificationBanner extends ConsumerWidget {
  final String userId;

  const _EmailVerificationBanner({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined, color: AppTheme.warningColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verify your email to unlock all features',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => context.go(RouteNames.profile),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
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
