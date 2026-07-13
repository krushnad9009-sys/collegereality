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

class InternshipsScreen extends ConsumerStatefulWidget {
  const InternshipsScreen({super.key});

  @override
  ConsumerState<InternshipsScreen> createState() => _InternshipsScreenState();
}

class _InternshipsScreenState extends ConsumerState<InternshipsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedInternshipsProvider.notifier).loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageState = ref.watch(paginatedInternshipsProvider);
    final filters = ref.watch(internshipFilterProvider);
    final savedIds = ref.watch(savedInternshipIdsProvider).valueOrNull ?? {};
    final resume = ref.watch(studentResumeProvider).valueOrNull;

    final items = filterInternships(
      items: pageState.items,
      searchQuery: filters.searchQuery,
      city: filters.city,
      company: filters.company,
      payType: filters.payType,
      workFromHome: filters.workFromHome ? true : null,
      minStipend: filters.minStipend,
      durationBucket: filters.durationBucket,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Internships'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search internships...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (q) => ref.read(internshipFilterProvider.notifier).update(
                  filters.copyWith(searchQuery: q),
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: filters.payType == null,
                  onSelected: (_) => ref.read(internshipFilterProvider.notifier).update(
                        filters.copyWith(clearPayType: true),
                      ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Paid'),
                  selected: filters.payType == CareersConstants.payTypePaid,
                  onSelected: (_) => ref.read(internshipFilterProvider.notifier).update(
                        filters.copyWith(payType: CareersConstants.payTypePaid),
                      ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('WFH'),
                  selected: filters.workFromHome,
                  onSelected: (v) => ref.read(internshipFilterProvider.notifier).update(
                        filters.copyWith(workFromHome: v),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Filter by city',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => ref.read(internshipFilterProvider.notifier).update(
                  filters.copyWith(city: v.isEmpty ? null : v, clearCity: v.isEmpty),
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Min stipend (₹/month)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => ref.read(internshipFilterProvider.notifier).update(
                  filters.copyWith(
                    minStipend: int.tryParse(v),
                    clearStipend: v.isEmpty,
                  ),
                ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Duration',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            value: filters.durationBucket,
            items: const [
              DropdownMenuItem(value: null, child: Text('Any duration')),
              DropdownMenuItem(value: 'short', child: Text('Short (≤ 8 weeks)')),
              DropdownMenuItem(value: 'medium', child: Text('Medium (9–16 weeks)')),
              DropdownMenuItem(value: 'long', child: Text('Long (> 16 weeks)')),
            ],
            onChanged: (v) => ref.read(internshipFilterProvider.notifier).update(
                  filters.copyWith(durationBucket: v, clearDuration: v == null),
                ),
          ),
          const SizedBox(height: 16),
          if (pageState.isLoading && items.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (items.isEmpty)
            const Center(child: Text('No internships found'))
          else
            ...items.map((i) => _InternshipCard(
                  internship: i,
                  isSaved: savedIds.contains(i.id),
                  onSave: () => _toggleSave(ref, context, i.id, savedIds.contains(i.id)),
                  onApply: () => _apply(ref, context, i, resume?.downloadUrl),
                )),
          if (pageState.hasMore) ...[
            const SizedBox(height: 12),
            Center(
              child: pageState.isLoading
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: () =>
                          ref.read(paginatedInternshipsProvider.notifier).loadMore(),
                      child: const Text('Load more'),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleSave(
    WidgetRef ref,
    BuildContext context,
    String id,
    bool isSaved,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final repo = ref.read(careersRepositoryProvider);
    try {
      if (isSaved) {
        await repo.unsaveInternship(user.uid, id);
      } else {
        await repo.saveInternship(user.uid, id);
      }
    } catch (e) {
      if (context.mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }

  Future<void> _apply(
    WidgetRef ref,
    BuildContext context,
    InternshipModel internship,
    String? resumeUrl,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(careersRepositoryProvider).applyInternship(
            userId: user.uid,
            internshipId: internship.id,
            companyId: internship.companyId,
            applicantName: user.displayName ?? 'Student',
            resumeUrl: resumeUrl,
          );
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Application submitted');
        if (internship.applyUrl.isNotEmpty) launchUrl(Uri.parse(internship.applyUrl));
      }
    } catch (e) {
      if (context.mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }
}

class _InternshipCard extends StatelessWidget {
  final InternshipModel internship;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onApply;

  const _InternshipCard({
    required this.internship,
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
                  child: Text(internship.title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                IconButton(
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
                  onPressed: onSave,
                ),
              ],
            ),
            Text('${internship.companyName} · ${internship.city}',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500)),
            const SizedBox(height: 8),
            Text(
              internship.isPaid ? 'Paid · ${internship.stipend}' : 'Unpaid · ${internship.stipend}',
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.accentColor),
            ),
            Text(
              '${internship.workType}${internship.isRemote ? ' · Work from home' : ''}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
            ),
            if (internship.duration.isNotEmpty)
              Text('Duration: ${internship.duration}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600)),
            if (internship.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(internship.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(onPressed: onApply, child: const Text('Apply')),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.push(
                    RouteNames.careersCompanyDetailPath(internship.companyId),
                  ),
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
