import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/utils/college_search_ranker.dart';

CollegeModel sampleCollege({
  required String id,
  required String name,
  required String city,
  String state = 'Maharashtra',
  String district = '',
}) {
  final normalizedCity = city.toLowerCase();
  return CollegeModel(
    id: id,
    name: name,
    nameLower: name.toLowerCase(),
    slug: id,
    city: city,
    cityLower: normalizedCity,
    district: district.isEmpty ? city : district,
    districtLower: (district.isEmpty ? city : district).toLowerCase(),
    state: state,
    stateLower: state.toLowerCase(),
    address: 'Test address',
    type: 'private',
    courses: const ['B.Tech'],
    fees: const CollegeFees(tuitionMin: 100000, tuitionMax: 200000, hostelAnnual: 50000),
    placements: const CollegePlacements(
      highestPackageLpa: 12,
      averagePackageLpa: 6,
      placementPercentage: 80,
    ),
    accreditation: const CollegeAccreditation(),
    aggregatedRatings: const CollegeRatings(
      overall: 4,
      teaching: 4,
      placements: 4,
      faculty: 4,
      hostel: 4,
      food: 4,
      infrastructure: 4,
      campusLife: 4,
      attendance: 4,
      sports: 4,
      fees: 4,
    ),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('CollegeSearchRanker', () {
    test('prioritizes exact Pune city matches', () {
      final colleges = [
        sampleCollege(id: '1', name: 'Delhi Institute', city: 'Delhi'),
        sampleCollege(id: '2', name: 'COEP Pune', city: 'Pune'),
        sampleCollege(id: '3', name: 'Pune Suburban College', city: 'Pune'),
      ];

      CollegeSearchRanker.rankResults(colleges, city: 'Pune');

      expect(colleges.first.city, 'Pune');
      expect(colleges[1].city, 'Pune');
      expect(colleges.last.city, 'Delhi');
    });

    test('exact city ranks before partial city match', () {
      final colleges = [
        sampleCollege(id: '1', name: 'New Delhi College', city: 'New Delhi'),
        sampleCollege(id: '2', name: 'Delhi University College', city: 'Delhi'),
      ];

      CollegeSearchRanker.rankResults(colleges, city: 'Delhi');

      expect(colleges.first.city, 'Delhi');
    });

    test('query match boosts name prefix', () {
      final colleges = [
        sampleCollege(id: '1', name: 'National Institute', city: 'Mumbai'),
        sampleCollege(id: '2', name: 'MIT Pune', city: 'Pune'),
      ];

      CollegeSearchRanker.rankResults(colleges, query: 'MIT');

      expect(colleges.first.name, 'MIT Pune');
    });

    test('B.Tech Pune prioritizes Pune colleges over other cities', () {
      final colleges = [
        sampleCollege(id: '1', name: 'Delhi Tech Institute', city: 'Delhi'),
        sampleCollege(id: '2', name: 'Pune Engineering College', city: 'Pune'),
        sampleCollege(
          id: '3',
          name: 'Mumbai B.Tech Academy',
          city: 'Mumbai',
        ),
      ];

      CollegeSearchRanker.rankResults(colleges, query: 'B.Tech Pune');

      expect(colleges.first.city, 'Pune');
      expect(colleges.last.city, isNot('Pune'));
    });

    test('Pune B.Tech also prioritizes Pune colleges', () {
      final colleges = [
        sampleCollege(id: '1', name: 'Hyderabad Institute', city: 'Hyderabad'),
        sampleCollege(id: '2', name: 'COEP', city: 'Pune'),
      ];

      CollegeSearchRanker.rankResults(colleges, query: 'Pune B.Tech');

      expect(colleges.first.city, 'Pune');
    });
  });
}
