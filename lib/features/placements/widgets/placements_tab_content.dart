import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../colleges/models/college_model.dart';
import '../providers/placement_provider.dart';
import 'branch_placement_chart.dart';
import 'placement_insights_panel.dart';
import 'salary_trend_chart.dart';

class PlacementsTabContent extends ConsumerWidget {
  final CollegeModel college;

  const PlacementsTabContent({required this.college, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync =
        ref.watch(collegeVerifiedPlacementStatsProvider(college.id));
    final verifiedAsync = ref.watch(isVerifiedForPlacementProvider);
    final isWide = MediaQuery.of(context).size.width >= 600;

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) {
        final hasVerified = stats.hasData;
        final official = college.placements;

        return ListView(
          padding: EdgeInsets.all(isWide ? 24 : 16),
          children: [
            verifiedAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (isVerified) {
                if (isVerified) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FilledButton.icon(
                      onPressed: () => context.go(
                        RouteNames.submitPlacementPath(college.id, college.name),
                      ),
                      icon: const Icon(Icons.add_chart_outlined),
                      label: Text(
                        'Submit Placement Details',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(RouteNames.verification),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Verify profile to submit placement'),
                  ),
                );
              },
            ),
            if (hasVerified) ...[
              _badge('Verified Student Data', AppTheme.accentColor),
              const SizedBox(height: 12),
              _statsGrid(
                isWide: isWide,
                stats: [
                  _Stat('Average Package',
                      '${stats.averagePackageLpa.toStringAsFixed(1)} LPA'),
                  _Stat('Highest Package',
                      '${stats.highestPackageLpa.toStringAsFixed(1)} LPA'),
                  _Stat('Median Package',
                      '${stats.medianPackageLpa.toStringAsFixed(1)} LPA'),
                  _Stat('Placement %',
                      '${stats.placementPercentage.toStringAsFixed(0)}%'),
                  _Stat('Internship %',
                      '${stats.internshipPercentage.toStringAsFixed(0)}%'),
                  _Stat('Verified Records', '${stats.approvedCount}'),
                ],
              ),
            ] else ...[
              _badge('Official College Data', AppTheme.secondaryColor),
              const SizedBox(height: 8),
              Text(
                'No verified student placement records approved yet. Showing '
                'official college data where available.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.gray500,
                ),
              ),
              const SizedBox(height: 12),
              _statsGrid(
                isWide: isWide,
                stats: [
                  _Stat('Average Package',
                      official.averagePackageLpa > 0
                          ? '${official.averagePackageLpa} LPA'
                          : '—'),
                  _Stat('Highest Package',
                      official.highestPackageLpa > 0
                          ? '${official.highestPackageLpa} LPA'
                          : '—'),
                  _Stat('Median Package', '—'),
                  _Stat('Placement %',
                      official.placementPercentage > 0
                          ? '${official.placementPercentage}%'
                          : '—'),
                  _Stat('Internship %', '—'),
                  _Stat('Verified Records', '0'),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Salary Graph',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SalaryTrendChart(trends: stats.yearWise),
            const SizedBox(height: 24),
            Text(
              'Branch-wise Placement Statistics',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            BranchPlacementChart(branches: stats.branchWise),
            const SizedBox(height: 24),
            Text(
              'Top Recruiting Companies',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (hasVerified
                      ? stats.topRecruiters
                      : official.topRecruiters)
                  .map(
                    (r) => Chip(
                      label: Text(r),
                      avatar: const Icon(Icons.business, size: 16),
                    ),
                  )
                  .toList(),
            ),
            if ((hasVerified ? stats.topRecruiters : official.topRecruiters)
                .isEmpty)
              Text(
                'No recruiter data available yet.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.gray500,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Year-wise Placement Trends',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (stats.yearWise.isEmpty)
              Text(
                'Trends appear after multiple years of verified approvals.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.gray500,
                ),
              )
            else
              ...stats.yearWise.map(
                (y) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppTheme.gray200),
                  ),
                  child: ListTile(
                    title: Text(
                      '${y.year}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Avg ${y.avgPackageLpa.toStringAsFixed(1)} LPA • '
                      'High ${y.highestPackageLpa.toStringAsFixed(1)} LPA • '
                      '${y.fullTimeRate.toStringAsFixed(0)}% full-time • '
                      '${y.count} records',
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            PlacementInsightsPanel(collegeId: college.id),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _statsGrid({required bool isWide, required List<_Stat> stats}) {
    return GridView.count(
      crossAxisCount: isWide ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isWide ? 2.2 : 1.8,
      children: stats
          .map(
            (s) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.gray500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  const _Stat(this.label, this.value);
}
