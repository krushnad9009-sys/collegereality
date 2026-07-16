import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/router/route_names.dart';
import '../../../core/bootstrap/startup_bootstrap.dart';
import '../../../core/cache/college_session_cache.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../widgets/deferred_incoming_call_banner.dart';
import '../widgets/featured_colleges_section.dart';
import '../widgets/home_header_widget.dart';
import '../../assistant/widgets/ai_search_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final currentUser = authState.user ?? FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.gray900
          : AppTheme.white,
      body: SafeArea(
        child: currentUser == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  CollegeSessionCache.clearFeatured();
                  ref.invalidate(collegeSeedProvider);
                  ref.invalidate(homeFeaturedCollegesProvider);
                  ref.invalidate(featuredCollegesProvider);
                  await ref.read(collegeSeedProvider.future);
                  await ref.read(homeFeaturedCollegesProvider.future);
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
                        const DeferredIncomingCallBanner(),
                        if (!currentUser.emailVerified) ...[
                          const SizedBox(height: 12),
                          _EmailVerificationBanner(userId: currentUser.uid),
                        ],
                        const SizedBox(height: 20),
                        _HeroBanner(
                          onExplore: () => context.go(RouteNames.collegeSearch),
                          onAi: () => context.go(RouteNames.assistant),
                        ),
                        const SizedBox(height: 24),
                        const AiSearchBar(),
                        const SizedBox(height: 12),
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
                                icon: Icons.leaderboard_rounded,
                                label: 'AI Rankings',
                                color: const Color(0xFF6366F1),
                                onTap: () => context.go(RouteNames.rankingHub),
                              ),
                              const SizedBox(width: 12),
                              _QuickAccessCard(
                                icon: Icons.groups_rounded,
                                label: 'Community',
                                color: const Color(0xFF7C3AED),
                                onTap: () => context.go(RouteNames.community),
                              ),
                              const SizedBox(width: 12),
                              _QuickAccessCard(
                                icon: Icons.school_rounded,
                                label: 'Admission',
                                color: const Color(0xFF0EA5E9),
                                onTap: () => context.go(RouteNames.admissionHub),
                              ),
                              const SizedBox(width: 12),
                              _QuickAccessCard(
                                icon: Icons.work_rounded,
                                label: 'Careers',
                                color: const Color(0xFF059669),
                                onTap: () => context.go(RouteNames.careersHub),
                              ),
                              const SizedBox(width: 12),
                              _QuickAccessCard(
                                icon: Icons.event_rounded,
                                label: 'Campus Life',
                                color: const Color(0xFFEA580C),
                                onTap: () => context.go(RouteNames.studentLifeHub),
                              ),
                              const SizedBox(width: 12),
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
                        const FeaturedCollegesSection(),
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
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 88),
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

class _HeroBanner extends StatelessWidget {
  final VoidCallback onExplore;
  final VoidCallback onAi;

  const _HeroBanner({
    required this.onExplore,
    required this.onAi,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.primaryDark, AppTheme.gray800]
              : [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover Your Perfect College',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore rankings, reviews, placements, and alumni guidance — all in one place.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.white.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  onPressed: onExplore,
                  child: Text(
                    'Explore Colleges',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.white.withValues(alpha: 0.2),
                  foregroundColor: AppTheme.white,
                ),
                onPressed: onAi,
                icon: const Icon(Icons.auto_awesome_rounded),
                tooltip: 'Ask AI',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmailVerificationBanner extends ConsumerStatefulWidget {
  final String userId;

  const _EmailVerificationBanner({required this.userId});

  @override
  ConsumerState<_EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<_EmailVerificationBanner> {
  bool _isSending = false;

  Future<void> _resend() async {
    setState(() => _isSending = true);
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: 'Verification email sent',
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  color: AppTheme.warningColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Verify your email to unlock reviews and community',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSending ? null : _resend,
                  child: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend Email'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => context.go(RouteNames.profile),
                  child: const Text('Verify Now'),
                ),
              ),
            ],
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
