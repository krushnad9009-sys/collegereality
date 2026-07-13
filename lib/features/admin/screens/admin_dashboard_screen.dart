import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../colleges/providers/college_provider.dart';
import '../../reviews/providers/review_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegeCountAsync = ref.watch(collegeCountProvider);
    final reviewsAsync = ref.watch(allReviewsAdminProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'College Reality Admin',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage colleges, reviews, and platform content.',
            style: GoogleFonts.poppins(color: AppTheme.gray600),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Colleges',
                  value: collegeCountAsync.maybeWhen(
                    data: (count) => '$count',
                    orElse: () => '...',
                  ),
                  icon: Icons.school,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Reviews',
                  value: reviewsAsync.maybeWhen(
                    data: (r) => '${r.length}',
                    orElse: () => '...',
                  ),
                  icon: Icons.rate_review,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _AdminMenuTile(
            icon: Icons.school_outlined,
            title: 'Manage Colleges',
            subtitle: 'View and edit college listings',
            onTap: () => context.go(RouteNames.adminColleges),
          ),
          _AdminMenuTile(
            icon: Icons.rate_review_outlined,
            title: 'Moderate Reviews',
            subtitle: 'Review flagged and recent submissions',
            onTap: () => context.go(RouteNames.adminReviews),
          ),
          _AdminMenuTile(
            icon: Icons.work_outline,
            title: 'Placement Approvals',
            subtitle: 'Review verified student placement submissions',
            onTap: () => context.go(RouteNames.adminPlacements),
          ),
          _AdminMenuTile(
            icon: Icons.people_outline,
            title: 'Users',
            subtitle: 'View registered students',
            onTap: () => context.go(RouteNames.adminUsers),
          ),
          _AdminMenuTile(
            icon: Icons.report_outlined,
            title: 'Communication Reports',
            subtitle: 'Moderate call and chat reports',
            onTap: () => context.go(RouteNames.adminCommunication),
          ),
          _AdminMenuTile(
            icon: Icons.verified_user_outlined,
            title: 'Student Verification',
            subtitle: 'Review flagged documents and approve badges',
            onTap: () => context.go(RouteNames.adminVerification),
          ),
          _AdminMenuTile(
            icon: Icons.forum_outlined,
            title: 'Community Moderation',
            subtitle: 'Review reported messages and content',
            onTap: () => context.go(RouteNames.adminCommunity),
          ),
          _AdminMenuTile(
            icon: Icons.quiz_outlined,
            title: 'Q&A Moderation',
            subtitle: 'Moderate college questions, answers, and reports',
            onTap: () => context.go(RouteNames.adminQuestions),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
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
