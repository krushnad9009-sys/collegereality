import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../providers/admin_dashboard_provider.dart';
import '../widgets/admin_chart_widgets.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminAnalyticsDataProvider),
          ),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load analytics: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionTitle('Review Growth (14 days)'),
            AdminLineChart(points: data.reviewGrowth, color: AppTheme.secondaryColor),
            const SizedBox(height: 20),
            _SectionTitle('User Growth (14 days)'),
            AdminLineChart(points: data.userGrowth, color: AppTheme.primaryColor),
            const SizedBox(height: 20),
            _SectionTitle('College Growth (14 days)'),
            AdminLineChart(points: data.collegeGrowth, color: Colors.teal),
            const SizedBox(height: 24),
            _SectionTitle('Most Viewed Colleges'),
            AdminBarChart(metrics: data.mostViewed, color: AppTheme.primaryColor),
            _MetricList(data.mostViewed),
            const SizedBox(height: 20),
            _SectionTitle('Most Searched Colleges'),
            AdminBarChart(metrics: data.mostSearched, color: Colors.orange),
            _MetricList(data.mostSearched),
            const SizedBox(height: 20),
            _SectionTitle('Most Bookmarked Colleges'),
            AdminBarChart(metrics: data.mostBookmarked, color: Colors.purple),
            _MetricList(data.mostBookmarked),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MetricList extends StatelessWidget {
  final List metrics;
  const _MetricList(this.metrics);

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    return Column(
      children: metrics.map<Widget>((m) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(m.collegeName, style: GoogleFonts.poppins(fontSize: 13)),
          trailing: Text('${m.value}'),
        );
      }).toList(),
    );
  }
}
