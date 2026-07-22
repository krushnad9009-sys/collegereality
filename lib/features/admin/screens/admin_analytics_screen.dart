import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../models/admin_models.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_chart_widgets.dart';
import '../widgets/admin_shell_layout.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsDataProvider);
    final isAdminUser = ref.watch(isAdminUserProvider).maybeWhen(data: (v) => v, orElse: () => false);

    return AdminShellLayout(
      title: 'Analytics',
      isAdminUser: isAdminUser,
      child: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load analytics: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminAnalyticsDataProvider),
          child: ListView(
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
              _SectionTitle('Most Searched Colleges'),
              AdminBarChart(metrics: data.mostSearched, color: Colors.orange),
              _MetricList(data.mostSearched),
              const SizedBox(height: 20),
              _SectionTitle('Most Active Colleges'),
              AdminBarChart(metrics: data.mostActiveColleges, color: Colors.green),
              _MetricList(data.mostActiveColleges),
              const SizedBox(height: 20),
              _SectionTitle('Trending Colleges'),
              AdminBarChart(metrics: data.trendingColleges, color: Colors.redAccent),
              _MetricList(data.trendingColleges),
              const SizedBox(height: 20),
              _SectionTitle('Top Reviewed Colleges'),
              AdminBarChart(metrics: data.topReviewed, color: Colors.purple),
              _MetricList(data.topReviewed),
              const SizedBox(height: 20),
              _SectionTitle('Most Viewed Colleges'),
              AdminBarChart(metrics: data.mostViewed, color: AppTheme.primaryColor),
              _MetricList(data.mostViewed),
              const SizedBox(height: 20),
              _SectionTitle('Most Bookmarked Colleges'),
              AdminBarChart(metrics: data.mostBookmarked, color: Colors.blueGrey),
              _MetricList(data.mostBookmarked),
              const SizedBox(height: 24),
              _SectionTitle('Top Contributors'),
              _ContributorsList(data.topContributors),
            ],
          ),
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
  final List<AdminTopCollegeMetric> metrics;
  const _MetricList(this.metrics);

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    return Column(
      children: metrics.map((m) {
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

class _ContributorsList extends StatelessWidget {
  final List<AdminTopContributor> contributors;
  const _ContributorsList(this.contributors);

  @override
  Widget build(BuildContext context) {
    if (contributors.isEmpty) {
      return Text('No contributor data yet.', style: GoogleFonts.poppins(color: AppTheme.gray600));
    }
    return Column(
      children: contributors.map((c) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(c.displayName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          subtitle: Text('${c.reviewCount} reviews · ${c.answerCount} answers · ${c.postCount} posts'),
          trailing: Text('${c.totalActivity}'),
        );
      }).toList(),
    );
  }
}
