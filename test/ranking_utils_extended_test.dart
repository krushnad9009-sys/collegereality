import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/ranking/utils/college_ranking_utils.dart';
import 'package:flutter_test/flutter_test.dart';

CollegeModel sample({
  required String id,
  String city = 'Pune',
  String state = 'Maharashtra',
  String type = 'private',
  List<String> courses = const ['B.Tech'],
  double overall = 4,
  bool isActive = true,
}) {
  return CollegeModel(
    id: id,
    name: 'College $id',
    nameLower: 'college $id',
    slug: id,
    city: city,
    state: state,
    address: 'Addr',
    type: type,
    courses: courses,
    isActive: isActive,
    fees: const CollegeFees(tuitionMin: 100000, tuitionMax: 200000, hostelAnnual: 50000),
    placements: const CollegePlacements(highestPackageLpa: 20, averagePackageLpa: 8, placementPercentage: 80),
    aggregatedRatings: CollegeRatings(
      overall: overall,
      faculty: overall,
      infrastructure: overall,
      placements: overall,
      campusLife: overall,
      fees: overall,
      teaching: overall,
      hostel: overall,
    ),
    reviewCount: 20,
  );
}

void main() {
  test('rankColleges filters and scores categories', () {
    final colleges = [
      sample(id: '1', overall: 4.5),
      sample(id: '2', city: 'Mumbai', overall: 4.8),
      sample(id: '3', type: 'government', courses: const ['MBA'], overall: 3.5),
      sample(id: '4', isActive: false, overall: 5),
    ];

    final byState = rankByState(colleges, state: 'Maharashtra');
    expect(byState.every((e) => e.college.state == 'Maharashtra'), isTrue);

    final byCity = rankByDistrict(colleges, city: 'Pune');
    expect(byCity.every((e) => e.college.city == 'Pune'), isTrue);

    final byCourse = rankByCourse(colleges, course: 'MBA');
    expect(byCourse.length, 1);

    final byType = rankByType(colleges, collegeType: 'government');
    expect(byType.length, 1);

    final placements = rankColleges(colleges: colleges, category: 'placements');
    expect(placements, isNotEmpty);
    expect(categoryRatingScore(colleges.first, 'fees'), greaterThan(0));
    expect(categoryRatingScore(colleges.first, 'teaching'), greaterThan(0));
    expect(categoryRatingScore(colleges.first, 'hostel'), greaterThan(0));
    expect(categoryRatingScore(colleges.first, 'safety'), greaterThanOrEqualTo(0));
    expect(categoryRatingScore(colleges.first, 'unknown'), greaterThanOrEqualTo(0));
    expect(formatFees(colleges.first), isNotEmpty);
    expect(formatScore(12.34), '12.3');
    expect(computeRoiScore(colleges.first), greaterThanOrEqualTo(0));
    expect(crScoreGrade(80), isNotEmpty);
    expect(crScoreConfidence(20), isNotEmpty);
  });
}