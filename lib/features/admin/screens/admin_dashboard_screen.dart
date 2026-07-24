import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_provider.dart';
import '../utils/admin_permissions.dart';
import '../widgets/admin_shell_layout.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final isAdminUser = ref.watch(isAdminUserProvider).maybeWhen(data: (v) => v, orElse: () => false);
    final userType = ref.watch(currentUserModelProvider).maybeWhen(data: (u) => u?.userType, orElse: () => null);
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1200 ? 5 : width >= 960 ? 4 : width >= 600 ? 2 : 1;

    return AdminShellLayout(
      title: 'Dashboard',
      showBack: false,
      isAdminUser: isAdminUser,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              'College Reality Admin',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Platform overview and moderation tools.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            statsAsync.when(
              loading: () => const DashboardSkeleton(),
              error: (e, _) => Text(
                'Failed to load stats: $e',
                style: GoogleFonts.poppins(color: tokens.textSecondary),
              ),
              data: (stats) => GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: width >= 600 ? 1.55 : 2.1,
                children: [
                  _StatTile(label: 'Total Colleges', value: '${stats.totalColleges}', icon: Icons.school, color: AppTheme.primaryColor),
                  _StatTile(label: 'Total Users', value: '${stats.totalUsers}', icon: Icons.people, color: Colors.blue),
                  _StatTile(label: 'Verified Students', value: '${stats.verifiedStudents}', icon: Icons.verified_user, color: Colors.teal),
                  _StatTile(label: 'Verified Alumni', value: '${stats.verifiedAlumni}', icon: Icons.school_outlined, color: Colors.cyan),
                  _StatTile(label: 'Total Reviews', value: '${stats.totalReviews}', icon: Icons.rate_review, color: AppTheme.secondaryColor),
                  _StatTile(label: 'Questions Asked', value: '${stats.totalQuestions}', icon: Icons.quiz, color: Colors.indigo),
                  _StatTile(label: 'Answers Posted', value: '${stats.totalAnswers}', icon: Icons.question_answer, color: Colors.deepPurple),
                  _StatTile(label: 'Community Posts', value: '${stats.communityPosts}', icon: Icons.forum, color: Colors.green),
                  _StatTile(label: 'Daily Active Users', value: '${stats.dailyActiveUsers}', icon: Icons.today, color: Colors.orange),
                  _StatTile(label: 'Pending Verifications', value: '${stats.pendingVerifications}', icon: Icons.pending_actions, color: Colors.amber),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (AdminPermissions.canViewAnalytics(userType))
              _AdminMenuTile(
                icon: Icons.analytics_outlined,
                title: 'Analytics',
                subtitle: 'Trending colleges, top contributors, growth charts',
                onTap: () => context.go(RouteNames.adminAnalytics),
              ),
            if (AdminPermissions.canManageVerification(userType))
              _AdminMenuTile(
                icon: Icons.verified_user_outlined,
                title: 'Verification Management',
                subtitle: 'Approve or reject student and alumni verification',
                onTap: () => context.go(RouteNames.adminVerification),
              ),
            if (AdminPermissions.canModerateContent(userType)) ...[
              _AdminMenuTile(
                icon: Icons.rate_review_outlined,
                title: 'Review Moderation',
                subtitle: 'Delete fake reviews, hide abusive content',
                onTap: () => context.go(RouteNames.adminReviews),
              ),
              _AdminMenuTile(
                icon: Icons.forum_outlined,
                title: 'Community Moderation',
                subtitle: 'Remove posts, suspend users, issue warnings',
                onTap: () => context.go(RouteNames.adminCommunity),
              ),
              _AdminMenuTile(
                icon: Icons.flag_outlined,
                title: 'Reports Hub',
                subtitle: 'Unified moderation queue',
                onTap: () => context.go(RouteNames.adminReports),
              ),
            ],
            if (AdminPermissions.canManageColleges(userType))
              _AdminMenuTile(
                icon: Icons.calculate_outlined,
                title: 'Recalculate CR Score',
                subtitle: 'Rebuild verified review scores for all colleges',
                onTap: () => context.go(RouteNames.adminRecalculateCrScore),
              ),
            if (AdminPermissions.canManageColleges(userType)) ...[
              _AdminMenuTile(
                icon: Icons.school_outlined,
                title: 'College Management',
                subtitle: 'Edit, add, and upload official images',
                onTap: () => context.go(RouteNames.adminColleges),
              ),
              if (AdminPermissions.canMergeColleges(userType))
                _AdminMenuTile(
                  icon: Icons.merge_type,
                  title: 'Merge Duplicate Colleges',
                  subtitle: 'Consolidate duplicate listings',
                  onTap: () => context.go(RouteNames.adminMergeColleges),
                ),
            ],
            if (AdminPermissions.canManageUsers(userType))
              _AdminMenuTile(
                icon: Icons.people_outline,
                title: 'User Management',
                subtitle: 'Search, suspend, ban, and warn users',
                onTap: () => context.go(RouteNames.adminUsers),
              ),
            if (AdminPermissions.canBroadcast(userType))
              _AdminMenuTile(
                icon: Icons.campaign_outlined,
                title: 'Broadcast Notifications',
                subtitle: 'All users, by state, or by college',
                onTap: () => context.go(RouteNames.adminAnnouncements),
              ),
            if (AdminPermissions.canExportData(userType))
              _AdminMenuTile(
                icon: Icons.download_outlined,
                title: 'Export Reports',
                subtitle: 'Analytics, verification, and user reports (CSV)',
                onTap: () => context.go(RouteNames.adminExport),
              ),
            _AdminMenuTile(
              icon: Icons.hub_outlined,
              title: 'Ecosystem Approvals',
              subtitle: 'College requests, edits, claims, faculty',
              onTap: () => context.go(RouteNames.adminEcosystem),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tokens.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
