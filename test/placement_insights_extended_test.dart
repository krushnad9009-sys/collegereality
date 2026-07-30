import 'package:college_reality_india/features/placements/models/verified_placement_stats.dart';
import 'package:college_reality_india/features/placements/services/placement_insights_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PlacementInsightsService service;

  setUp(() {
    service = PlacementInsightsService();
  });

  group('PlacementInsightsService.buildInsights', () {
    test('returns placeholder when no approved data', () {
      final insights = service.buildInsights(const VerifiedPlacementStats());
      expect(insights.length, 1);
      expect(insights.first, contains('No admin-approved placement records'));
    });

    test('includes approved count and package statistics', () {
      const stats = VerifiedPlacementStats(
        approvedCount: 25,
        averagePackageLpa: 8.5,
        medianPackageLpa: 7.5,
        highestPackageLpa: 18.0,
        placementPercentage: 72,
        internshipPercentage: 20,
      );

      final insights = service.buildInsights(stats);
      expect(insights.any((i) => i.contains('25 admin-approved')), isTrue);
      expect(insights.any((i) => i.contains('8.5 LPA')), isTrue);
      expect(insights.any((i) => i.contains('72% full-time')), isTrue);
      expect(insights.any((i) => i.contains('20% internships')), isTrue);
    });

    test('includes top recruiters when present', () {
      const stats = VerifiedPlacementStats(
        approvedCount: 10,
        averagePackageLpa: 6.0,
        topRecruiters: ['TCS', 'Infosys', 'Wipro', 'Accenture', 'Capgemini', 'Cognizant'],
      );

      final insights = service.buildInsights(stats);
      expect(
        insights.any((i) => i.contains('Top recruiting companies') && i.contains('TCS')),
        isTrue,
      );
    });

    test('includes branch-wise highest package insight', () {
      const stats = VerifiedPlacementStats(
        approvedCount: 15,
        averagePackageLpa: 7.0,
        branchWise: [
          BranchPlacementStat(branch: 'CSE', count: 8, avgPackageLpa: 10.5),
          BranchPlacementStat(branch: 'ECE', count: 4, avgPackageLpa: 7.0),
        ],
      );

      final insights = service.buildInsights(stats);
      expect(insights.any((i) => i.contains('CSE') && i.contains('10.5 LPA')), isTrue);
    });

    test('includes year-wise trend when two or more years', () {
      const stats = VerifiedPlacementStats(
        approvedCount: 30,
        averagePackageLpa: 8.0,
        yearWise: [
          YearPlacementTrend(year: 2023, avgPackageLpa: 6.5, count: 10),
          YearPlacementTrend(year: 2024, avgPackageLpa: 8.2, count: 12),
        ],
      );

      final insights = service.buildInsights(stats);
      expect(insights.any((i) => i.contains('Year-wise trend')), isTrue);
      expect(insights.any((i) => i.contains('increased')), isTrue);
    });

    test('always ends with verified-data disclaimer', () {
      const stats = VerifiedPlacementStats(
        approvedCount: 5,
        averagePackageLpa: 5.0,
      );
      final insights = service.buildInsights(stats);
      expect(insights.last, contains('computed from approved student submissions'));
    });

    test('singular record uses singular grammar', () {
      const stats = VerifiedPlacementStats(
        approvedCount: 1,
        averagePackageLpa: 6.0,
        branchWise: [
          BranchPlacementStat(branch: 'IT', count: 1, avgPackageLpa: 6.0),
        ],
      );
      final insights = service.buildInsights(stats);
      expect(insights.any((i) => i.contains('placement record.')), isTrue);
      expect(insights.any((i) => i.contains('verified report')), isTrue);
    });
  });
}
