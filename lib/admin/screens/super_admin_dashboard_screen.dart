import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_theme.dart';
import '../../core/widgets/premium_components.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../features/admin/widgets/admin_chart_widgets.dart';
import '../../features/admin/widgets/admin_shell_layout.dart';
import '../../features/admin/providers/admin_dashboard_provider.dart';
import '../providers/super_admin_dashboard_provider.dart';
import '../router/super_admin_route_names.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final bundleAsync = ref.watch(superAdminDashboardBundleProvider);
    final width = MediaQuery.sizeOf(context).width;
    final statColumns = width >= 1400 ? 5 : width >= 1100 ? 4 : width >= 720 ? 3 : 2;

    return AdminShellLayout(
      title: 'Dashboard',
      showBack: false,
      isAdminUser: true,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(superAdminDashboardBundleProvider);
          ref.invalidate(adminDashboardStatsProvider);
          ref.invalidate(adminAnalyticsDataProvider);
        },
        child: bundleAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: const [DashboardSkeleton()],
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text('Failed to load dashboard: $e', style: GoogleFonts.inter(color: tokens.textSecondary)),
            ],
          ),
          data: (bundle) {
            final stats = bundle.stats;
            final extended = bundle.extended;
            final analytics = bundle.analytics;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Platform Overview',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Real-time metrics across users, colleges, content, and engagement.',
                  style: GoogleFonts.inter(fontSize: 14, color: tokens.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxl),
                GridView.count(
                  crossAxisCount: statColumns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: width >= 900 ? 1.6 : 1.9,
                  children: [
                    _StatCard(label: 'Total Users', value: '${stats.totalUsers}', icon: Icons.people, color: Colors.blue),
                    _StatCard(
                      label: "Today's Registrations",
                      value: '${extended.todayRegistrations}',
                      icon: Icons.person_add_alt_1,
                      color: Colors.green,
                    ),
                    _StatCard(
                      label: 'Active Users (DAU)',
                      value: '${extended.activeUsers}',
                      icon: Icons.online_prediction,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      label: 'Monthly Active',
                      value: '${stats.monthlyActiveUsers}',
                      icon: Icons.calendar_month,
                      color: Colors.deepOrange,
                    ),
                    _StatCard(
                      label: 'Verified Students',
                      value: '${stats.verifiedStudents}',
                      icon: Icons.verified_user,
                      color: Colors.teal,
                    ),
                    _StatCard(
                      label: 'Verified Alumni',
                      value: '${stats.verifiedAlumni}',
                      icon: Icons.school,
                      color: Colors.cyan,
                    ),
                    _StatCard(
                      label: 'Total Colleges',
                      value: '${stats.totalColleges}',
                      icon: Icons.account_balance,
                      color: AppTheme.primaryColor,
                    ),
                    _StatCard(
                      label: 'Total Reviews',
                      value: '${stats.totalReviews}',
                      icon: Icons.rate_review,
                      color: AppTheme.secondaryColor,
                    ),
                    _StatCard(
                      label: 'Questions',
                      value: '${stats.totalQuestions}',
                      icon: Icons.quiz,
                      color: Colors.indigo,
                    ),
                    _StatCard(
                      label: 'Community Posts',
                      value: '${stats.communityPosts}',
                      icon: Icons.forum,
                      color: Colors.green,
                    ),
                    _StatCard(
                      label: 'Open Reports',
                      value: '${stats.totalReports}',
                      icon: Icons.flag,
                      color: Colors.redAccent,
                    ),
                    _StatCard(
                      label: 'AI Usage',
                      value: extended.aiUsageSessions > 0 ? '${extended.aiUsageSessions}' : '—',
                      icon: Icons.smart_toy_outlined,
                      color: Colors.purple,
                      subtitle: extended.aiUsageSessions > 0 ? null : 'Telemetry pending',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.section),
                Text(
                  'Growth Trends',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                if (width >= 900)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _ChartCard(title: 'User Registrations', child: AdminLineChart(points: analytics.userGrowth, color: AppTheme.primaryColor))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _ChartCard(title: 'Review Growth', child: AdminLineChart(points: analytics.reviewGrowth, color: AppTheme.secondaryColor))),
                    ],
                  )
                else ...[
                  _ChartCard(title: 'User Registrations', child: AdminLineChart(points: analytics.userGrowth, color: AppTheme.primaryColor)),
                  const SizedBox(height: AppSpacing.md),
                  _ChartCard(title: 'Review Growth', child: AdminLineChart(points: analytics.reviewGrowth, color: AppTheme.secondaryColor)),
                ],
                const SizedBox(height: AppSpacing.section),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ActionChipButton(
                      label: 'Manage Users',
                      icon: Icons.people_outline,
                      route: SuperAdminRouteNames.users,
                    ),
                    _ActionChipButton(
                      label: 'Colleges',
                      icon: Icons.school_outlined,
                      route: SuperAdminRouteNames.colleges,
                    ),
                    _ActionChipButton(
                      label: 'Moderation',
                      icon: Icons.shield_outlined,
                      route: SuperAdminRouteNames.moderation,
                    ),
                    _ActionChipButton(
                      label: 'Broadcast',
                      icon: Icons.campaign_outlined,
                      route: SuperAdminRouteNames.notifications,
                    ),
                    _ActionChipButton(
                      label: 'Analytics',
                      icon: Icons.analytics_outlined,
                      route: SuperAdminRouteNames.analytics,
                    ),
                    _ActionChipButton(
                      label: 'Settings',
                      icon: Icons.settings_outlined,
                      route: SuperAdminRouteNames.settings,
                    ),
                  ],
                ),
              ],
            );
          },
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
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: tokens.textSecondary)),
          if (subtitle != null)
            Text(subtitle!, style: GoogleFonts.inter(fontSize: 10, color: tokens.textSecondary)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: tokens.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;

  const _ActionChipButton({required this.label, required this.icon, required this.route});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppTheme.primaryColor),
      label: Text(label),
      onPressed: () => context.go(route),
    );
  }
}
