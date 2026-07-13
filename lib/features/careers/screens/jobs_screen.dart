import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/careers_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/careers_models.dart';
import '../providers/careers_provider.dart';
import '../utils/careers_filter_utils.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedJobsProvider.notifier).loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageState = ref.watch(paginatedJobsProvider);
    final filters = ref.watch(jobFilterProvider);
    final savedIds = ref.watch(savedJobIdsProvider).valueOrNull ?? {};
    final resume = ref.watch(studentResumeProvider).valueOrNull;

    final items = filterJobs(
      items: pageState.items,
      searchQuery: filters.searchQuery,
      location: filters.location,
      jobLevel: filters.jobLevel,
      workType: filters.workType,
      minSalaryLpa: filters.minSalaryLpa,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Jobs'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search jobs...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (q) => ref.read(jobFilterProvider.notifier).update(
                  filters.copyWith(searchQuery: q),
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('All', filters.jobLevel == null, () {
                  ref.read(jobFilterProvider.notifier).update(filters.copyWith(clearLevel: true));
                }),
                _chip('Fresher', filters.jobLevel == CareersConstants.jobLevelFresher, () {
                  ref.read(jobFilterProvider.notifier).update(
                        filters.copyWith(jobLevel: CareersConstants.jobLevelFresher),
                      );
                }),
                _chip('Experienced', filters.jobLevel == CareersConstants.jobLevelExperienced, () {
                  ref.read(jobFilterProvider.notifier).update(
                        filters.copyWith(jobLevel: CareersConstants.jobLevelExperienced),
                      );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Remote', filters.workType == CareersConstants.workTypeRemote, () {
                  ref.read(jobFilterProvider.notifier).update(
                        filters.copyWith(workType: CareersConstants.workTypeRemote),
                      );
                }),
                _chip('Hybrid', filters.workType == CareersConstants.workTypeHybrid, () {
                  ref.read(jobFilterProvider.notifier).update(
                        filters.copyWith(workType: CareersConstants.workTypeHybrid),
                      );
                }),
                _chip('Office', filters.workType == CareersConstants.workTypeOffice, () {
                  ref.read(jobFilterProvider.notifier).update(
                        filters.copyWith(workType: CareersConstants.workTypeOffice),
                      );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Filter by location',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => ref.read(jobFilterProvider.notifier).update(
                  filters.copyWith(location: v.isEmpty ? null : v, clearLocation: v.isEmpty),
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Min salary (LPA)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => ref.read(jobFilterProvider.notifier).update(
                  filters.copyWith(
                    minSalaryLpa: double.tryParse(v),
                    clearSalary: v.isEmpty,
                  ),
                ),
          ),
          const SizedBox(height: 16),
          if (pageState.isLoading && items.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (items.isEmpty)
            const Center(child: Text('No jobs found'))
          else
            ...items.map((j) => _JobCard(
                  job: j,
                  isSaved: savedIds.contains(j.id),
                  onSave: () => _toggleSave(ref, context, j.id, savedIds.contains(j.id)),
                  onApply: () => _apply(ref, context, j, resume?.downloadUrl),
                )),
          if (pageState.hasMore) ...[
            const SizedBox(height: 12),
            Center(
              child: pageState.isLoading
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: () => ref.read(paginatedJobsProvider.notifier).loadMore(),
                      child: const Text('Load more'),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }

  Future<void> _toggleSave(WidgetRef ref, BuildContext context, String id, bool saved) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final repo = ref.read(careersRepositoryProvider);
    try {
      if (saved) {
        await repo.unsaveJob(user.uid, id);
      } else {
        await repo.saveJob(user.uid, id);
      }
    } catch (e) {
      if (context.mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }

  Future<void> _apply(
    WidgetRef ref,
    BuildContext context,
    JobModel job,
    String? resumeUrl,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(careersRepositoryProvider).applyJob(
            userId: user.uid,
            jobId: job.id,
            companyId: job.companyId,
            applicantName: user.displayName ?? 'Student',
            resumeUrl: resumeUrl,
          );
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Application submitted');
        if (job.applyUrl.isNotEmpty) launchUrl(Uri.parse(job.applyUrl));
      }
    } catch (e) {
      if (context.mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onApply;

  const _JobCard({
    required this.job,
    required this.isSaved,
    required this.onSave,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(job.title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                IconButton(
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
                  onPressed: onSave,
                ),
              ],
            ),
            Text('${job.companyName} · ${job.location}',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500)),
            const SizedBox(height: 8),
            Text(job.salaryRange,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(
              '${job.jobLevel == CareersConstants.jobLevelFresher ? 'Fresher' : 'Experienced'} · ${job.workType}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
            ),
            if (job.eligibility.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Eligibility: ${job.eligibility}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(onPressed: onApply, child: const Text('Apply')),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.push(RouteNames.careersCompanyDetailPath(job.companyId)),
                  child: const Text('Company'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
