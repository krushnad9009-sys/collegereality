import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/compare_constants.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/compare/services/college_comparison_service.dart';

void main() {
  group('CollegeComparisonService', () {
    final service = CollegeComparisonService();

    CollegeModel sample({
      required String id,
      required String name,
      double overall = 4.0,
      double teaching = 4.0,
      double placements = 4.0,
      double faculty = 4.0,
      int reviewCount = 10,
      int feeMax = 200000,
      double avgPackage = 8.0,
      double highestPackage = 20.0,
      String? naacGrade,
      int? nirfRank,
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
        courses: const ['B.Tech', 'MBA'],
        fees: CollegeFees(
          tuitionMin: feeMax ~/ 2,
          tuitionMax: feeMax,
          hostelAnnual: 50000,
        ),
        placements: CollegePlacements(
          highestPackageLpa: highestPackage,
          averagePackageLpa: avgPackage,
          placementPercentage: 85,
        ),
        accreditation: CollegeAccreditation(
          naacGrade: naacGrade,
          nirfRank: nirfRank,
        ),
        aggregatedRatings: CollegeRatings(
          overall: overall,
          faculty: faculty,
          infrastructure: 4.0,
          placements: placements,
          campusLife: 4.0,
          teaching: teaching,
          labs: 4.0,
          library: 4.0,
          hostel: 4.0,
          food: 4.0,
          safety: 4.0,
        ),
        reviewCount: reviewCount,
      );
    }

    test('requires at least 2 colleges', () {
      final result = service.compare([
        sample(id: '1', name: 'College A'),
      ]);
      expect(result.rows, isEmpty);
      expect(result.summary, contains('2'));
    });

    test('limits to max 4 colleges', () {
      final colleges = List.generate(
        6,
        (i) => sample(id: '$i', name: 'College $i', overall: 3.0 + i * 0.2),
      );
      final result = service.compare(colleges);
      expect(result.colleges.length, CompareConstants.maxColleges);
    });

    test('includes premium comparison metrics', () {
      final result = service.compare([
        sample(id: '1', name: 'Alpha', overall: 4.5, naacGrade: 'A+', nirfRank: 45),
        sample(id: '2', name: 'Beta', overall: 3.8, naacGrade: 'A', nirfRank: 120),
      ]);
      final metrics = result.rows.map((r) => r.metric).toSet();
      expect(metrics, contains('CR Score'));
      expect(metrics, contains('Grade'));
      expect(metrics, contains('Confidence Level'));
      expect(metrics, contains('Total Verified Reviews'));
      expect(metrics, contains('Fees'));
      expect(metrics, contains('Average Package'));
      expect(metrics, contains('Highest Package'));
      expect(metrics, contains('Placement Rate'));
      expect(metrics, contains('Education Quality'));
      expect(metrics, contains('Campus Life'));
      expect(metrics, contains('Infrastructure'));
      expect(metrics, contains('Safety & Discipline'));
      expect(metrics, contains('Hostel'));
      expect(metrics, contains('Faculty'));
      expect(metrics, contains('Location'));
      expect(metrics, contains('Courses Offered'));
      expect(metrics, contains('NAAC Grade'));
      expect(metrics, contains('NIRF Rank'));
    });

    test('selects overall winner by CR Score', () {
      final result = service.compare([
        sample(id: '1', name: 'Alpha', overall: 4.8, reviewCount: 200),
        sample(id: '2', name: 'Beta', overall: 3.5, reviewCount: 20),
      ]);
      expect(result.overallWinnerIndex, 0);
      expect(result.aiSummary.bestOverall, 'Alpha');
    });

    test('generates AI summary categories', () {
      final result = service.compare([
        sample(id: '1', name: 'Alpha', avgPackage: 12, feeMax: 500000),
        sample(id: '2', name: 'Beta', avgPackage: 6, feeMax: 150000),
      ]);
      expect(result.aiSummary.hasAny, isTrue);
      expect(result.insights.length, 2);
    });
  });
}
