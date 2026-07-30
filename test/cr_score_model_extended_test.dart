import 'package:college_reality_india/core/constants/cr_score_constants.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/ranking/models/cr_score_model.dart';
import 'package:college_reality_india/features/ranking/utils/cr_score_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CollegeModel sampleCollege({
    double teaching = 4.5,
    double faculty = 4.0,
    double placements = 4.8,
    double campusLife = 4.2,
    double infrastructure = 4.0,
    double safety = 4.5,
    int reviewCount = 120,
    double crScore = 0,
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
      crScore: crScore,
    );
  }

  group('CrScoreCategories', () {
    test('scoreFor returns category values', () {
      const cats = CrScoreCategories(
        education: 80,
        placements: 90,
        campusLife: 70,
        infrastructure: 60,
        safety: 85,
      );
      expect(cats.scoreFor(CrScoreConstants.categoryEducation), 80);
      expect(cats.scoreFor(CrScoreConstants.categoryPlacements), 90);
      expect(cats.scoreFor('unknown'), 0);
    });

    test('fromJson/toJson round-trip', () {
      const original = CrScoreCategories(
        education: 75,
        placements: 82,
        campusLife: 68,
        infrastructure: 71,
        safety: 77,
      );
      final restored = CrScoreCategories.fromJson(original.toJson());
      expect(restored.education, 75);
      expect(restored.placements, 82);
      expect(restored.safety, 77);
    });

    test('fromJson null returns empty categories', () {
      expect(CrScoreCategories.fromJson(null), const CrScoreCategories());
    });
  });

  group('CrScoreSnapshot', () {
    test('grade and confidenceLabel derive from score and review count', () {
      final snapshot = CrScoreEngine.compute(sampleCollege(reviewCount: 1500));
      expect(snapshot.grade, isIn(['A+', 'A', 'A-', 'B+', 'B']));
      expect(snapshot.confidenceLabel, 'Very High Confidence');
      expect(snapshot.hasEnoughData, isTrue);
    });

    test('low review count yields Not enough data confidence', () {
      final snapshot = CrScoreEngine.compute(sampleCollege(reviewCount: 5));
      expect(snapshot.confidenceLabel, 'Not enough data');
      expect(snapshot.hasEnoughData, isFalse);
    });

    test('fromCollege uses stored college cr fields', () {
      final college = sampleCollege(reviewCount: 200, crScore: 88.0).copyWith(
        crScoreCategories: const CrScoreCategories(placements: 95),
      );
      final snapshot = CrScoreSnapshot.fromCollege(college);
      expect(snapshot.score, 88.0);
      expect(snapshot.categories.placements, 95);
      expect(snapshot.verifiedReviewCount, 200);
    });
  });

  group('CrScoreEngine', () {
    test('effectiveScore prefers stored crScore when positive', () {
      final college = sampleCollege(crScore: 91.2, reviewCount: 50);
      expect(CrScoreEngine.effectiveScore(college), 91.2);
    });

    test('effectiveScore computes when crScore is zero', () {
      final college = sampleCollege(reviewCount: 100);
      final computed = CrScoreEngine.compute(college).score;
      expect(CrScoreEngine.effectiveScore(college), computed);
      expect(computed, greaterThan(0));
    });

    test('firestorePayload includes score, categories, and timestamp', () {
      final snapshot = CrScoreEngine.compute(sampleCollege());
      final payload = CrScoreEngine.firestorePayload(snapshot);
      expect(payload['crScore'], snapshot.score);
      expect(payload['crScoreCategories'], isA<Map<String, dynamic>>());
      expect(payload['crScoreUpdatedAt'], isA<String>());
    });

    test('compute returns zero score without reviews', () {
      final snapshot = CrScoreEngine.compute(sampleCollege(reviewCount: 0));
      expect(snapshot.score, 0);
      expect(snapshot.categories, const CrScoreCategories());
    });
  });
}
