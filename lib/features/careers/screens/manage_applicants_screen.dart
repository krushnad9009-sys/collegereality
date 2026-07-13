import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/careers_constants.dart';
import '../models/careers_models.dart';
import '../providers/careers_provider.dart';

class ManageApplicantsScreen extends ConsumerWidget {
  const ManageApplicantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(companyAccountProvider).valueOrNull;
    if (account == null) {
      return const Scaffold(body: Center(child: Text('No company account')));
    }

    final internshipApps =
        ref.watch(_internshipAppsProvider(account.companyId));
    final jobApps = ref.watch(_jobAppsProvider(account.companyId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('Applicants'),
          bottom: const TabBar(tabs: [Tab(text: 'Internships'), Tab(text: 'Jobs')]),
        ),
        body: TabBarView(
          children: [
            _ApplicantsList(
              appsAsync: internshipApps,
              isInternship: true,
              companyId: account.companyId,
            ),
            _ApplicantsList(
              appsAsync: jobApps,
              isInternship: false,
              companyId: account.companyId,
            ),
          ],
        ),
      ),
    );
  }
}

final _internshipAppsProvider =
    StreamProvider.family<List<ApplicationModel>, String>((ref, companyId) {
  return ref.watch(careersRepositoryProvider).watchInternshipApplicationsForCompany(companyId);
});

final _jobAppsProvider = StreamProvider.family<List<ApplicationModel>, String>((ref, companyId) {
  return ref.watch(careersRepositoryProvider).watchJobApplicationsForCompany(companyId);
});

class _ApplicantsList extends ConsumerWidget {
  final AsyncValue<List<ApplicationModel>> appsAsync;
  final bool isInternship;
  final String companyId;

  const _ApplicantsList({
    required this.appsAsync,
    required this.isInternship,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return appsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (apps) {
        if (apps.isEmpty) return const Center(child: Text('No applications yet'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: apps.length,
          itemBuilder: (_, i) => _ApplicantCard(
            app: apps[i],
            isInternship: isInternship,
            onStatus: (status) => ref.read(careersRepositoryProvider).updateApplicationStatus(
                  applicationId: apps[i].id,
                  status: status,
                  isInternship: isInternship,
                ),
          ),
        );
      },
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicationModel app;
  final bool isInternship;
  final ValueChanged<String> onStatus;

  const _ApplicantCard({
    required this.app,
    required this.isInternship,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.applicantName.isNotEmpty ? app.applicantName : 'Applicant',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            Text(
              isInternship ? 'Internship: ${app.internshipId}' : 'Job: ${app.jobId}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
            ),
            if (app.coverNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(app.coverNote, style: GoogleFonts.poppins(fontSize: 12)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _statusChip(app.status),
                const Spacer(),
                if (app.resumeUrl != null)
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(app.resumeUrl!)),
                    child: const Text('Resume'),
                  ),
                PopupMenuButton<String>(
                  onSelected: onStatus,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: CareersConstants.applicationStatusUnderReview,
                      child: Text('Under review'),
                    ),
                    const PopupMenuItem(
                      value: CareersConstants.applicationStatusAccepted,
                      child: Text('Accept'),
                    ),
                    const PopupMenuItem(
                      value: CareersConstants.applicationStatusRejected,
                      child: Text('Reject'),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.replaceAll('_', ' '),
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
