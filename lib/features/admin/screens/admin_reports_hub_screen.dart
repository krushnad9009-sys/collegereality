import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../core/constants/admin_constants.dart';
import '../providers/admin_dashboard_provider.dart';
import '../utils/admin_moderation_utils.dart';

class AdminReportsHubScreen extends ConsumerWidget {
  const AdminReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminOpenReportsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports & Moderation'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.go(RouteNames.admin),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Reviews'),
              Tab(text: 'Photos'),
              Tab(text: 'Spam/Abuse'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(adminOpenReportsProvider),
            ),
          ],
        ),
        body: reportsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load reports: $e')),
          data: (reports) => TabBarView(
            children: [
              _ReportList(reports: reports),
              _ReportList(reports: reports.where((r) => r.source == 'Review').toList()),
              _ReportList(
                reports: reports
                    .where((r) => r.reason.toLowerCase().contains('photo'))
                    .toList(),
              ),
              _ReportList(
                reports: reports
                    .where((r) =>
                        moderationLabel(reason: r.reason, source: r.source)
                            .startsWith('Likely'))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportList extends ConsumerWidget {
  final List reports;
  const _ReportList({required this.reports});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reports.isEmpty) {
      return const Center(child: Text('No open reports'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final report = reports[index];
        final label = moderationLabel(reason: report.reason, source: report.source);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(report.reason),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _resolve(
                        ref,
                        report,
                        AdminConstants.reportStatusReviewed,
                        context,
                      ),
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text('Approve'),
                    ),
                    TextButton.icon(
                      onPressed: () => _resolve(
                        ref,
                        report,
                        AdminConstants.reportStatusActionTaken,
                        context,
                      ),
                      icon: const Icon(Icons.block, color: Colors.red),
                      label: const Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _resolve(
    WidgetRef ref,
    dynamic report,
    String status,
    BuildContext context,
  ) async {
    final collection = reportCollectionForSource(report.source as String);
    await ref.read(adminAnalyticsServiceProvider).updateReportStatus(
          collection: collection,
          reportId: report.reportId as String,
          status: status,
        );
    ref.invalidate(adminOpenReportsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report marked as $status')),
      );
    }
  }
}
