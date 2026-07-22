import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_provider.dart';
import '../utils/admin_export_utils.dart';
import '../utils/admin_permissions.dart';
import '../widgets/admin_shell_layout.dart';

class AdminExportScreen extends ConsumerWidget {
  const AdminExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final analyticsAsync = ref.watch(adminAnalyticsDataProvider);
    final reportsAsync = ref.watch(adminOpenReportsProvider);
    final collegesAsync = ref.watch(adminCollegeStatsExportProvider);
    final verificationAsync = ref.watch(adminVerificationExportProvider);
    final userReportsAsync = ref.watch(adminUserReportsExportProvider);
    final isAdminUser = ref.watch(isAdminUserProvider).maybeWhen(data: (v) => v, orElse: () => false);
    final userType = ref.watch(currentUserModelProvider).maybeWhen(data: (u) => u?.userType, orElse: () => null);
    final canExport = AdminPermissions.canExportData(userType);

    return AdminShellLayout(
      title: 'Export Data',
      isAdminUser: isAdminUser,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Export Center',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Copy exports to clipboard. Excel-compatible tab format available.',
            style: GoogleFonts.poppins(color: AppTheme.gray600),
          ),
          const SizedBox(height: 24),
          if (!canExport)
            const Card(
              child: ListTile(
                leading: Icon(Icons.lock_outline, color: Colors.orange),
                title: Text('Admin access required'),
                subtitle: Text('Only admins can export platform reports.'),
              ),
            )
          else ...[
            _ExportTile(
              title: 'Dashboard KPIs (CSV)',
              subtitle: 'Colleges, users, verifications, reviews, DAU',
              onExport: statsAsync.maybeWhen(
                data: (stats) => () => _copy(context, exportDashboardStatsCsv(stats)),
                orElse: () => null,
              ),
            ),
            _ExportTile(
              title: 'Analytics (CSV)',
              subtitle: 'Growth, trending, top reviewed, contributors',
              onExport: analyticsAsync.maybeWhen(
                data: (data) => () => _copy(context, exportAnalyticsCsv(data)),
                orElse: () => null,
              ),
            ),
            _ExportTile(
              title: 'Verification Reports (CSV)',
              subtitle: 'Student and alumni verification requests',
              onExport: verificationAsync.maybeWhen(
                data: (rows) => () => _copy(context, exportVerificationReportCsv(rows)),
                orElse: () => null,
              ),
            ),
            _ExportTile(
              title: 'User Reports (CSV)',
              subtitle: 'Communication and profile abuse reports',
              onExport: userReportsAsync.maybeWhen(
                data: (rows) => () => _copy(context, exportUserReportsCsv(rows)),
                orElse: () => null,
              ),
            ),
            _ExportTile(
              title: 'Moderation Reports (Excel-compatible)',
              subtitle: 'Open reports across all sources',
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
