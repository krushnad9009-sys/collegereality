import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/utils/college_search_utils.dart';
import 'package:flutter_test/flutter_test.dart';

CollegeModel _college({
  required String id,
  required String city,
  required String district,
  String state = 'Maharashtra',
  String cityLower = '',
}) {
  return CollegeModel(
    id: id,
    name: id,
    nameLower: id,
    slug: id,
    city: city,
    cityLower: cityLower.isEmpty ? city.toLowerCase() : cityLower,
    district: district,
    state: state,
    address: 'Test',
    type: 'private',
    category: 'Engineering',
    courses: const ['B.Tech'],
    fees: const CollegeFees(tuitionMin: 1, tuitionMax: 2, hostelAnnual: 1),
    placements: const CollegePlacements(
      highestPackageLpa: 1,
      averagePackageLpa: 1,
      placementPercentage: 1,
    ),
    aggregatedRatings: const CollegeRatings(
      overall: 4,
      faculty: 4,
      infrastructure: 4,
      placements: 4,
      campusLife: 4,
      hostel: 4,
      teaching: 4,
    ),
  );
}

void main() {
  group('unified cityMatchesCollege semantics', () {
    test('Mumbai filter matches Navi Mumbai and Mumbai Suburban district', () {
      final samples = [
        _college(id: '1', city: 'Mumbai', district: 'Mumbai'),
        _college(id: '2', city: 'Navi Mumbai', district: 'Thane'),
        _college(id: '3', city: 'Kharghar', district: 'Mumbai Suburban'),
        _college(id: '4', city: 'Pune', district: 'Pune'),
      ];
      final out = CollegeSearchUtils.applyFilters(samples, city: 'Mumbai');
      expect(out.map((c) => c.id), ['1', '2', '3']);
    });

    test('Bangalore filter matches bengaluru cityLower alias', () {
      final samples = [
        _college(id: 'a', city: 'Bengaluru', district: 'Bengaluru', cityLower: 'bengaluru'),
        _college(id: 'b', city: 'Bangalore', district: 'Bangalore', cityLower: 'bangalore'),
        _college(id: 'c', city: 'Mysuru', district: 'Mysuru'),
      ];
      final out = CollegeSearchUtils.applyFilters(samples, city: 'Bangalore');
      expect(out.map((c) => c.id), ['a', 'b']);
    });

    test('Chennai filter matches madras alias and district contains', () {
      final samples = [
        _college(id: '1', city: 'Chennai', district: 'Chennai'),
        _college(id: '2', city: 'Madras', district: 'Chennai'),
        _college(id: '3', city: 'Coimbatore', district: 'Coimbatore'),
      ];
      final out = CollegeSearchUtils.applyFilters(samples, city: 'Chennai');
      expect(out.map((c) => c.id), ['1', '2']);
    });

    test('Kolkata filter matches calcutta alias', () {
      final samples = [
        _college(id: '1', city: 'Kolkata', district: 'Kolkata'),
        _college(id: '2', city: 'Calcutta', district: 'Kolkata'),
      ];
      final out = CollegeSearchUtils.applyFilters(samples, city: 'Kolkata');
      expect(out.map((c) => c.id), ['1', '2']);
    });

    test('Delhi filter matches new delhi alias', () {
      final samples = [
        _college(id: '1', city: 'Delhi', district: 'Delhi'),
        _college(id: '2', city: 'New Delhi', district: 'Delhi'),
        _college(id: '3', city: 'Noida', district: 'Gautam Buddha Nagar'),
      ];
      final out = CollegeSearchUtils.applyFilters(samples, city: 'Delhi');
      expect(out.map((c) => c.id), ['1', '2']);
    });
  });
}
