import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
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
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView.fromError(e),
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
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppFonts.plusJakarta(fontSize: 16, fontWeight: FontWeight.w700, color: tokens.textPrimary),
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
    final tokens = context.tokens;
    return Column(
      children: metrics.map((m) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            m.collegeName,
            style: AppFonts.plusJakarta(fontSize: 13, color: tokens.textPrimary),
          ),
          trailing: Text(
            '${m.value}',
            style: AppFonts.plusJakarta(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
          ),
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
    final tokens = context.tokens;
    if (contributors.isEmpty) {
      return Text('No contributor data yet.', style: AppFonts.plusJakarta(color: tokens.textSecondary));
    }
    return Column(
      children: contributors.map((c) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            c.displayName,
            style: AppFonts.plusJakarta(fontWeight: FontWeight.w600, color: tokens.textPrimary),
          ),
          subtitle: Text(
            '${c.reviewCount} reviews · ${c.answerCount} answers · ${c.postCount} posts',
            style: AppFonts.plusJakarta(fontSize: 12.5, color: tokens.textSecondary),
          ),
          trailing: Text(
            '${c.totalActivity}',
            style: AppFonts.plusJakarta(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
          ),
        );
      }).toList(),
    );
  }
}
