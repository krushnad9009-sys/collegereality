import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../providers/admin_dashboard_provider.dart';

class AdminSystemMonitorScreen extends ConsumerWidget {
  const AdminSystemMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(adminSystemHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Monitoring'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminSystemHealthProvider),
          ),
        ],
      ),
      body: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load system health: $e')),
        data: (health) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Platform Health',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _MonitorTile(
              icon: Icons.cloud_outlined,
              label: 'Estimated Firestore Reads',
              value: '${health.estimatedFirestoreReads}',
              color: AppTheme.primaryColor,
            ),
            _MonitorTile(
              icon: Icons.storage_outlined,
              label: 'Storage Usage (MB)',
              value: '${health.estimatedStorageMb}',
              color: Colors.teal,
            ),
            _MonitorTile(
              icon: Icons.bug_report_outlined,
              label: 'Crashes (24h)',
              value: '${health.crashCount24h}',
              color: Colors.orange,
            ),
            _MonitorTile(
              icon: Icons.speed_outlined,
              label: 'Avg Response (ms)',
              value: health.avgResponseMs.toStringAsFixed(0),
              color: Colors.indigo,
            ),
            _MonitorTile(
              icon: Icons.error_outline,
              label: 'Error Logs',
              value: '${health.errorLogCount}',
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Performance',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.cached),
              title: Text('Admin session cache enabled (10 min TTL)'),
            ),
            const ListTile(
              leading: Icon(Icons.pages_outlined),
              title: Text('Paginated admin lists (24 items per page)'),
            ),
            const ListTile(
              leading: Icon(Icons.query_stats_outlined),
              title: Text('Firestore count() aggregations for KPIs'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonitorTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MonitorTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
