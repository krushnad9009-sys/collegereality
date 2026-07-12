import '../models/verified_placement_stats.dart';

/// Template-based placement insights from verified Firestore records only.
class PlacementInsightsService {
  List<String> buildInsights(VerifiedPlacementStats stats) {
    if (!stats.hasData) {
      return [
        'No admin-approved placement records yet. Statistics appear only after '
        'verified students submit and admins approve placement details.',
      ];
    }

    final insights = <String>[
      'Based on ${stats.approvedCount} admin-approved, verified student '
      'placement record${stats.approvedCount == 1 ? '' : 's'} in Firestore.',
    ];

    if (stats.averagePackageLpa > 0) {
      insights.add(
        'Average verified package: ${stats.averagePackageLpa.toStringAsFixed(1)} LPA '
        '(median ${stats.medianPackageLpa.toStringAsFixed(1)} LPA, '
        'highest ${stats.highestPackageLpa.toStringAsFixed(1)} LPA).',
      );
    }

    if (stats.placementPercentage > 0 || stats.internshipPercentage > 0) {
      insights.add(
        'Among verified reports: '
        '${stats.placementPercentage.toStringAsFixed(0)}% full-time offers, '
        '${stats.internshipPercentage.toStringAsFixed(0)}% internships.',
      );
    }

    if (stats.topRecruiters.isNotEmpty) {
      insights.add(
        'Top recruiting companies (by verified report count): '
        '${stats.topRecruiters.take(5).join(', ')}.',
      );
    }

    if (stats.branchWise.isNotEmpty) {
      final best = stats.branchWise.first;
      if (best.avgPackageLpa > 0) {
        insights.add(
          'Highest average package by branch: ${best.branch} '
          'at ${best.avgPackageLpa.toStringAsFixed(1)} LPA '
          '(${best.count} verified report${best.count == 1 ? '' : 's'}).',
        );
      }
    }

    if (stats.yearWise.length >= 2) {
      final first = stats.yearWise.first;
      final last = stats.yearWise.last;
      if (first.avgPackageLpa > 0 && last.avgPackageLpa > 0) {
        final delta = last.avgPackageLpa - first.avgPackageLpa;
        final direction = delta >= 0 ? 'increased' : 'decreased';
        insights.add(
          'Year-wise trend: average package $direction from '
          '${first.avgPackageLpa.toStringAsFixed(1)} LPA (${first.year}) to '
          '${last.avgPackageLpa.toStringAsFixed(1)} LPA (${last.year}) '
          'across verified records.',
        );
      }
    }

    insights.add(
      'All figures are computed from approved Firestore submissions — '
      'nothing is estimated or generated.',
    );

    return insights;
  }
}
