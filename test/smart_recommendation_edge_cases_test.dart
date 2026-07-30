import 'package:college_reality_india/core/constants/ranking_constants.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/ranking/models/ranking_models.dart';
import 'package:college_reality_india/features/ranking/utils/smart_recommendation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

CollegeModel _college({
  required String id,
  required String name,
  String city = 'Pune',
  String state = 'Maharashtra',
  int feeMax = 200000,
  int placementPct = 85,
  String type = 'private',
  bool isActive = true,
  bool hostel = true,
  List<String> courses = const ['B.Tech', 'Computer Science'],
}) {
  return CollegeModel(
    id: id,
    name: name,
    nameLower: name.toLowerCase(),
    slug: id,
    city: city,
    state: state,
    address: 'Test',
    type: type,
    courses: courses,
    fees: CollegeFees(tuitionMin: feeMax ~/ 2, tuitionMax: feeMax, hostelAnnual: 50000),
    placements: CollegePlacements(
      highestPackageLpa: 18,
      averagePackageLpa: 7,
      placementPercentage: placementPct,
    ),
    hostel: CollegeHostel(available: hostel),
    aggregatedRatings: const CollegeRatings(
      overall: 4.2,
      faculty: 4.0,
      infrastructure: 4.0,
      placements: 4.5,
      campusLife: 4.1,
      teaching: 4.2,
    ),
    reviewCount: 50,
    isActive: isActive,
  );
}

void main() {
  group('SmartRecommendationEngine edge cases', () {
    test('skips inactive colleges', () {
      final results = recommendColleges(
        colleges: [
          _college(id: '1', name: 'Inactive', isActive: false),
          _college(id: '2', name: 'Active'),
        ],
        criteria: const SmartRecommendationCriteria(examScore: 90),
      );
      expect(results.every((r) => r.college.isActive), isTrue);
      expect(results.any((r) => r.college.id == '1'), isFalse);
    });

    test('JEE top rank tier boosts government colleges', () {
      final gov = _college(id: 'gov', name: 'Gov Institute', type: 'government');
      final results = recommendColleges(
        colleges: [gov],
        criteria: const SmartRecommendationCriteria(
          examType: RankingConstants.examJee,
          examScore: 3000,
        ),
      );
      expect(results, isNotEmpty);
      expect(
        results.first.reasons.any((r) => r.contains('Government college')),
        isTrue,
      );
    });

    test('NEET score tiers affect match score', () {
      final high = recommendColleges(
        colleges: [_college(id: '1', name: 'Med')],
        criteria: const SmartRecommendationCriteria(
          examType: RankingConstants.examNeet,
          examScore: 4000,
        ),
      );
      final low = recommendColleges(
        colleges: [_college(id: '1', name: 'Med')],
        criteria: const SmartRecommendationCriteria(
          examType: RankingConstants.examNeet,
          examScore: 90000,
        ),
      );
      expect(high.first.matchScore, greaterThan(low.first.matchScore));
    });

    test('CET percentile tiers affect match score', () {
      final high = recommendColleges(
        colleges: [_college(id: '1', name: 'Eng')],
        criteria: const SmartRecommendationCriteria(
          examType: RankingConstants.examCet,
          examScore: 96,
        ),
      );
      final low = recommendColleges(
        colleges: [_college(id: '1', name: 'Eng')],
        criteria: const SmartRecommendationCriteria(
          examType: RankingConstants.examCet,
          examScore: 50,
        ),
      );
      expect(high.first.matchScore, greaterThan(low.first.matchScore));
    });

    test('requireHostel penalizes colleges without hostel', () {
      final withHostel = recommendColleges(
        colleges: [_college(id: '1', name: 'With Hostel', hostel: true)],
        criteria: const SmartRecommendationCriteria(requireHostel: true, examScore: 80),
      );
      final withoutHostel = recommendColleges(
        colleges: [_college(id: '2', name: 'No Hostel', hostel: false)],
        criteria: const SmartRecommendationCriteria(requireHostel: true, examScore: 80),
      );
      expect(withHostel.first.matchScore, greaterThan(withoutHostel.first.matchScore));
    });

    test('branchPreference boosts matching courses', () {
      final results = recommendColleges(
        colleges: [_college(id: '1', name: 'CSE College')],
        criteria: const SmartRecommendationCriteria(
          branchPreference: 'Computer',
          examScore: 80,
        ),
      );
      expect(
        results.first.reasons.any((r) => r.contains('Computer')),
        isTrue,
      );
    });

    test('preferred city adds location reason', () {
      final results = recommendColleges(
        colleges: [_college(id: '1', name: 'Pune College', city: 'Pune')],
        criteria: const SmartRecommendationCriteria(
          preferredCity: 'Pune',
          examScore: 80,
        ),
      );
      expect(
        results.first.reasons.any((r) => r.contains('Pune')),
        isTrue,
      );
    });

    test('reservation category SC adds bonus over General', () {
      final sc = recommendColleges(
        colleges: [_college(id: '1', name: 'Test')],
        criteria: const SmartRecommendationCriteria(
          reservationCategory: 'SC',
          examScore: 80,
        ),
      );
      final general = recommendColleges(
        colleges: [_college(id: '1', name: 'Test')],
        criteria: const SmartRecommendationCriteria(
          reservationCategory: 'General',
          examScore: 80,
        ),
      );
      expect(sc.first.matchScore, greaterThan(general.first.matchScore));
    });

    test('zero exam score still returns baseline matches', () {
      final results = recommendColleges(
        colleges: [_college(id: '1', name: 'Baseline')],
        criteria: const SmartRecommendationCriteria(examScore: 0),
      );
      expect(results, isNotEmpty);
    });

    test('respects recommendation limit', () {
      final colleges = List.generate(
        20,
        (i) => _college(id: '$i', name: 'College $i'),
      );
      final results = recommendColleges(
        colleges: colleges,
        criteria: const SmartRecommendationCriteria(examScore: 90),
        limit: 3,
      );
      expect(results.length, 3);
    });

    test('excludes colleges above max budget', () {
      final results = recommendColleges(
        colleges: [
          _college(id: '1', name: 'Too Expensive', feeMax: 800000),
          _college(id: '2', name: 'Affordable', feeMax: 150000),
        ],
        criteria: const SmartRecommendationCriteria(maxBudget: 200000, examScore: 80),
      );
      expect(results.any((r) => r.college.id == '2'), isTrue);
      expect(results.any((r) => r.college.id == '1'), isFalse);
    });
  });
}
