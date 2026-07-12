import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/placement_constants.dart';
import 'package:college_reality_india/features/placements/models/placement_submission_model.dart';
import 'package:college_reality_india/features/placements/models/verified_placement_stats.dart';
import 'package:college_reality_india/features/placements/services/placement_insights_service.dart';
import 'package:college_reality_india/features/placements/utils/placement_stats_calculator.dart';

void main() {
  group('PlacementStatsCalculator', () {
    PlacementSubmissionModel sample({
      required String id,
      required double package,
      required String type,
      required int year,
      required String branch,
      required String company,
    }) {
      return PlacementSubmissionModel(
        id: id,
        collegeId: 'c1',
        collegeName: 'Test College',
        userId: 'u1',
        companyName: company,
        jobRole: 'Engineer',
        packageLpa: package,
        employmentType: type,
        year: year,
        branch: branch,
        status: PlacementConstants.statusApproved,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
    }

    test('computes median and averages from approved records', () {
      final stats = PlacementStatsCalculator.compute([
        sample(id: '1', package: 6, type: PlacementConstants.typeFullTime, year: 2024, branch: 'CSE', company: 'TCS'),
        sample(id: '2', package: 8, type: PlacementConstants.typeFullTime, year: 2024, branch: 'CSE', company: 'Infosys'),
        sample(id: '3', package: 10, type: PlacementConstants.typeInternship, year: 2023, branch: 'ECE', company: 'Google'),
      ]);

      expect(stats.approvedCount, 3);
      expect(stats.medianPackageLpa, 8);
      expect(stats.averagePackageLpa, closeTo(8, 0.01));
      expect(stats.highestPackageLpa, 10);
      expect(stats.topRecruiters, contains('TCS'));
      expect(stats.branchWise, isNotEmpty);
      expect(stats.yearWise.length, 2);
    });

    test('returns empty stats for no records', () {
      final stats = PlacementStatsCalculator.compute([]);
      expect(stats.hasData, isFalse);
    });
  });

  group('PlacementInsightsService', () {
    test('does not hallucinate when no data', () {
      final service = PlacementInsightsService();
      final insights = service.buildInsights(const VerifiedPlacementStats());
      expect(insights.first, contains('No admin-approved'));
    });
  });
}
