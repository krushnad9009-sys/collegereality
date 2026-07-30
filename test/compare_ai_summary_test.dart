import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/compare/utils/compare_ai_summary_utils.dart';
import 'package:flutter_test/flutter_test.dart';

CollegeModel _college({
  required String id,
  required String name,
  double placementsRating = 4.0,
  double campusLife = 4.0,
  double teaching = 4.0,
  double faculty = 4.0,
  double infrastructure = 4.0,
  double safety = 4.0,
  int feeMax = 200000,
  int reviewCount = 50,
  double crScore = 0,
}) {
  return CollegeModel(
    id: id,
    name: name,
    nameLower: name.toLowerCase(),
    slug: id,
    city: 'Pune',
    state: 'Maharashtra',
    address: 'Test',
    type: 'private',
    courses: const ['B.Tech'],
    fees: CollegeFees(
      tuitionMin: feeMax ~/ 2,
      tuitionMax: feeMax,
      hostelAnnual: 50000,
    ),
    placements: const CollegePlacements(
      highestPackageLpa: 20,
      averagePackageLpa: 8,
      placementPercentage: 85,
    ),
    aggregatedRatings: CollegeRatings(
      overall: 4.0,
      faculty: faculty,
      infrastructure: infrastructure,
      placements: placementsRating,
      campusLife: campusLife,
      teaching: teaching,
      labs: 4.0,
      safety: safety,
      hostel: 4.0,
      sports: 4.0,
      food: 4.0,
      attendance: 4.0,
    ),
    reviewCount: reviewCount,
    crScore: crScore,
  );
}

void main() {
  group('CompareAiSummaryUtils.build', () {
    test('returns empty summary for fewer than 2 colleges', () {
      final summary = CompareAiSummaryUtils.build([
        _college(id: '1', name: 'Solo College'),
      ]);
      expect(summary.bestOverall, isNull);
      expect(summary.bestForPlacements, isNull);
      expect(summary.bestForCampusLife, isNull);
      expect(summary.bestValueForMoney, isNull);
    });

    test('picks best overall from effective CR score', () {
      final summary = CompareAiSummaryUtils.build([
        _college(id: 'a', name: 'Alpha', reviewCount: 100, teaching: 3.5),
        _college(id: 'b', name: 'Beta', reviewCount: 100, teaching: 5.0, faculty: 5.0),
      ]);
      expect(summary.bestOverall, isNotNull);
    });

    test('picks best for placements by category score', () {
      final summary = CompareAiSummaryUtils.build([
        _college(id: 'a', name: 'Low Placements', placementsRating: 3.0),
        _college(id: 'b', name: 'High Placements', placementsRating: 5.0),
      ]);
      expect(summary.bestForPlacements, 'High Placements');
    });

    test('picks best for campus life', () {
      final summary = CompareAiSummaryUtils.build([
        _college(id: 'a', name: 'Urban', campusLife: 3.5),
        _college(id: 'b', name: 'Green Campus', campusLife: 4.9),
      ]);
      expect(summary.bestForCampusLife, 'Green Campus');
    });

    test('picks best value for money (CR per lakh fee)', () {
      final summary = CompareAiSummaryUtils.build([
        _college(id: 'a', name: 'Expensive', feeMax: 500000, reviewCount: 80, teaching: 4.5),
        _college(id: 'b', name: 'Affordable', feeMax: 100000, reviewCount: 80, teaching: 4.5),
      ]);
      expect(summary.bestValueForMoney, 'Affordable');
    });

    test('uses stored crScore in effectiveScore comparison', () {
      final summary = CompareAiSummaryUtils.build([
        _college(id: 'a', name: 'Computed', reviewCount: 50, crScore: 0),
        _college(id: 'b', name: 'Stored High', reviewCount: 50, crScore: 95),
      ]);
      expect(summary.bestOverall, 'Stored High');
    });

    test('handles three or more colleges', () {
      final summary = CompareAiSummaryUtils.build([
        _college(id: '1', name: 'C1', placementsRating: 3.0),
        _college(id: '2', name: 'C2', placementsRating: 4.5),
        _college(id: '3', name: 'C3', placementsRating: 5.0),
      ]);
      expect(summary.bestForPlacements, 'C3');
      expect(summary.bestOverall, isNotNull);
    });
  });
}
