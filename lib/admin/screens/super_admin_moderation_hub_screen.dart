import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_theme.dart';
import '../../features/admin/widgets/admin_shell_layout.dart';
import '../router/super_admin_route_names.dart';

class SuperAdminModerationHubScreen extends StatelessWidget {
  const SuperAdminModerationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShellLayout(
      title: 'Content Moderation',
      isAdminUser: true,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Review, approve, reject, or delete reported content across the platform.',
            style: GoogleFonts.inter(color: AppTheme.gray600),
          ),
          const SizedBox(height: 24),
          _ModerationTile(
            icon: Icons.flag_outlined,
            title: 'Reports Hub',
            subtitle: 'Unified queue for all open reports',
            route: SuperAdminRouteNames.reports,
            color: Colors.redAccent,
          ),
          _ModerationTile(
            icon: Icons.rate_review_outlined,
            title: 'Reviews',
            subtitle: 'Moderate college reviews',
            route: SuperAdminRouteNames.reviews,
            color: AppTheme.secondaryColor,
          ),
          _ModerationTile(
            icon: Icons.forum_outlined,
            title: 'Community Posts',
            subtitle: 'Campus feed and community messages',
            route: SuperAdminRouteNames.community,
            color: Colors.green,
          ),
          _ModerationTile(
            icon: Icons.quiz_outlined,
            title: 'Questions & Answers',
            subtitle: 'Q&A board moderation',
            route: SuperAdminRouteNames.questions,
            color: Colors.indigo,
          ),
          _ModerationTile(
            icon: Icons.verified_user_outlined,
            title: 'Verification Queue',
            subtitle: 'Approve student and alumni verification',
            route: SuperAdminRouteNames.verification,
            color: Colors.teal,
          ),
          _ModerationTile(
            icon: Icons.hub_outlined,
            title: 'Ecosystem Approvals',
            subtitle: 'College requests, edits, and claims',
            route: SuperAdminRouteNames.ecosystem,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _ModerationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;

  const _ModerationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(route),
      ),
    );
  }
}
