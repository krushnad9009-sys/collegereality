import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../providers/careers_provider.dart';

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(companyAccountProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Company Dashboard'),
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (account) {
          if (account == null || !account.isVerified) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_outlined, size: 48, color: AppTheme.gray400),
                    const SizedBox(height: 16),
                    Text(
                      'Verified company account required',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contact admin to link your account to a verified company profile.',
                      style: GoogleFonts.poppins(color: AppTheme.gray600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(account.companyName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20)),
              Text('Verified company account',
                  style: GoogleFonts.poppins(color: AppTheme.accentColor, fontSize: 13)),
              const SizedBox(height: 24),
              _DashboardTile(
                icon: Icons.work_outline,
                title: 'Post Internship',
                subtitle: 'Create a new internship listing',
                onTap: () => context.push(RouteNames.careersPostInternship),
              ),
              _DashboardTile(
                icon: Icons.business_center_outlined,
                title: 'Post Job',
                subtitle: 'Create fresher or experienced role',
                onTap: () => context.push(RouteNames.careersPostJob),
              ),
              _DashboardTile(
                icon: Icons.people_outline,
                title: 'Manage Applicants',
                subtitle: 'Review internship & job applications',
                onTap: () => context.push(RouteNames.careersManageApplicants),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
