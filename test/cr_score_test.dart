import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/cr_score_constants.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/ranking/utils/cr_score_engine.dart';

void main() {
  CollegeModel sampleCollege({
    double teaching = 4.5,
    double faculty = 4.0,
    double placements = 4.8,
    double campusLife = 4.2,
    double infrastructure = 4.0,
    double safety = 4.5,
    int reviewCount = 120,
  }) {
    return CollegeModel(
      id: 'c1',
      name: 'Test College',
      nameLower: 'test college',
      slug: 'test-college',
      city: 'Pune',
      state: 'Maharashtra',
      address: 'Test',
      type: 'private',
      courses: const ['B.Tech'],
      fees: const CollegeFees(tuitionMin: 100000, tuitionMax: 200000, hostelAnnual: 50000),
      placements: const CollegePlacements(
        highestPackageLpa: 20,
        averagePackageLpa: 8,
        placementPercentage: 85,
      ),
      aggregatedRatings: CollegeRatings(
        overall: 4.4,
        faculty: faculty,
        infrastructure: infrastructure,
        placements: placements,
        campusLife: campusLife,
        teaching: teaching,
        labs: 4.0,
        attendance: 4.0,
        safety: safety,
        hostel: 4.0,
        sports: 4.0,
        food: 4.0,
      ),
      reviewCount: reviewCount,
    );
  }

  group('CrScoreEngine', () {
    test('compute returns score between 0 and 100', () {
      final snapshot = CrScoreEngine.compute(sampleCollege());
      expect(snapshot.score, inInclusiveRange(0, 100));
    });

    test('compute returns zero when no verified reviews', () {
      final snapshot = CrScoreEngine.compute(sampleCollege(reviewCount: 0));
      expect(snapshot.score, 0);
    });

    test('category weights produce expected grade labels', () {
      final high = CrScoreEngine.compute(
        sampleCollege(
          teaching: 5,
          faculty: 5,
          placements: 5,
          campusLife: 5,
          infrastructure: 5,
          safety: 5,
          reviewCount: 1500,
        ).copyWith(
          aggregatedRatings: const CollegeRatings(
            overall: 5,
            faculty: 5,
            infrastructure: 5,
            placements: 5,
            campusLife: 5,
            teaching: 5,
            labs: 5,
            attendance: 5,
            safety: 5,
            hostel: 5,
            sports: 5,
            food: 5,
          ),
        ),
      );
      expect(high.score, greaterThanOrEqualTo(95));
      expect(high.grade, 'A+');
      expect(high.confidenceLabel, 'Very High Confidence');
    });

    test('confidence labels follow review count bands', () {
      expect(CrScoreConstants.confidenceLabel(5), 'Not enough data');
      expect(CrScoreConstants.confidenceLabel(25), 'Low Confidence');
      expect(CrScoreConstants.confidenceLabel(100), 'Medium Confidence');
      expect(CrScoreConstants.confidenceLabel(500), 'High Confidence');
      expect(CrScoreConstants.confidenceLabel(1200), 'Very High Confidence');
    });

    test('grade mapping matches specification', () {
      expect(CrScoreConstants.gradeForScore(96), 'A+');
      expect(CrScoreConstants.gradeForScore(92), 'A');
      expect(CrScoreConstants.gradeForScore(87), 'A-');
      expect(CrScoreConstants.gradeForScore(55), 'D');
      expect(CrScoreConstants.gradeForScore(40), 'F');
    });
  });
}
