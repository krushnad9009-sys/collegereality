import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:flutter_test/flutter_test.dart';

CollegeModel sampleCollege() {
  return CollegeModel(
    id: 'c1',
    name: 'Test Engineering College',
    nameLower: 'test engineering college',
    slug: 'c1',
    city: 'Pune',
    cityLower: 'pune',
    district: 'Pune',
    districtLower: 'pune',
    state: 'Maharashtra',
    stateLower: 'maharashtra',
    address: 'Test address',
    type: 'private',
    courses: const ['B.Tech'],
    fees: const CollegeFees(tuitionMin: 100000, tuitionMax: 200000, hostelAnnual: 50000),
    placements: const CollegePlacements(
      highestPackageLpa: 12,
      averagePackageLpa: 6,
      placementPercentage: 80,
    ),
    accreditation: const CollegeAccreditation(naacGrade: 'A+', aicteApproved: true),
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
    scholarships: const [
      CollegeScholarship(name: 'Merit', eligibility: '80%+', amount: '50000'),
    ],
    hostel: const CollegeHostel(available: true, annualFee: 60000),
    reviewCount: 10,
    isFeatured: true,
    officialLinks: const ['https://example.com'],
    universityName: 'SPPU',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  test('createDraft returns college shell', () {
    final draft = CollegeModel.createDraft(id: 'draft-1');
    expect(draft.id, 'draft-1');
    expect(draft.state, isNotEmpty);
  });

  test('fromJson/toJson round trip preserves core fields', () {
    final original = sampleCollege();
    final json = original.toJson();
    final restored = CollegeModel.fromJson(json, docId: 'c1');
    expect(restored.name, original.name);
    expect(restored.city, original.city);
    expect(restored.state, original.state);
    expect(restored.fees.tuitionMin, 100000);
    expect(restored.placements.averagePackageLpa, 6);
    expect(restored.accreditation.naacGrade, 'A+');
    expect(restored.aggregatedRatings.overall, 4);
    expect(restored.scholarships.first.name, 'Merit');
    expect(restored.hostel.available, isTrue);
    expect(restored.displayAdmissionLinks, isNotEmpty);
  });

  test('fromJson fills defaults for empty payload', () {
    final college = CollegeModel.fromJson({}, docId: 'x');
    expect(college.id, 'x');
    expect(college.type, 'private');
    expect(college.isActive, isTrue);
    expect(college.courses, isEmpty);
  });

  test('nested models serialize', () {
    const fees = CollegeFees(tuitionMin: 1, tuitionMax: 2, hostelAnnual: 3);
    expect(CollegeFees.fromJson(fees.toJson()).tuitionMax, 2);
    const ratings = CollegeRatings(
      overall: 1, faculty: 2, infrastructure: 3, placements: 4, campusLife: 5,
    );
    expect(CollegeRatings.fromJson(ratings.toJson()).faculty, 2);
  });
}