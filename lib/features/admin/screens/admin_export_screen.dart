import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../providers/admin_dashboard_provider.dart';
import '../utils/admin_export_utils.dart';

class AdminExportScreen extends ConsumerWidget {
  const AdminExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final analyticsAsync = ref.watch(adminAnalyticsDataProvider);
    final reportsAsync = ref.watch(adminOpenReportsProvider);
    final collegesAsync = ref.watch(adminCollegeStatsExportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Export Center',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Copy exports to clipboard. Excel-compatible tab format available for reports.',
            style: GoogleFonts.poppins(color: AppTheme.gray600),
          ),
          const SizedBox(height: 24),
          _ExportTile(
            title: 'Dashboard KPIs (CSV)',
            subtitle: 'Total colleges, users, reviews, reports, DAU/MAU',
            onExport: statsAsync.maybeWhen(
              data: (stats) => () => _copy(context, exportDashboardStatsCsv(stats)),
              orElse: () => null,
            ),
          ),
          _ExportTile(
            title: 'Analytics (CSV)',
            subtitle: 'Growth series and top college metrics',
            onExport: analyticsAsync.maybeWhen(
              data: (data) => () => _copy(context, exportAnalyticsCsv(data)),
              orElse: () => null,
            ),
          ),
          _ExportTile(
            title: 'Reports (Excel-compatible)',
            subtitle: 'Open moderation reports as tab-separated values',
            onExport: reportsAsync.maybeWhen(
              data: (reports) =>
                  () => _copy(context, toExcelCompatible(exportReportsCsv(reports))),
              orElse: () => null,
            ),
          ),
          _ExportTile(
            title: 'College Statistics (CSV)',
            subtitle: 'Ratings, review counts, and activity flags',
            onExport: collegesAsync.maybeWhen(
              data: (rows) => () => _copy(context, exportCollegeStatsCsv(rows)),
              orElse: () => null,
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onExport;

  const _ExportTile({
    required this.title,
    required this.subtitle,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.download_outlined),
          onPressed: onExport,
        ),
      ),
    );
  }
}
