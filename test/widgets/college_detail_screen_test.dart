import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/providers/college_provider.dart';
import 'package:college_reality_india/features/colleges/screens/college_detail_screen.dart';
import 'package:college_reality_india/features/questions/providers/question_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

CollegeModel _sampleCollege() {
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
    fees: const CollegeFees(
      tuitionMin: 100000,
      tuitionMax: 200000,
      hostelAnnual: 50000,
    ),
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
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void setTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('CollegeDetailScreen renders college from provider override',
      (tester) async {
    setTallSurface(tester);
    final college = _sampleCollege();

    await pumpScreen(
      tester,
      overrides: [
        ...testAuthOverrides(),
        collegeSeedProvider.overrideWith((ref) async => true),
        collegeByIdProvider.overrideWith((ref, id) async => college),
        unansweredQuestionsProvider.overrideWith((ref, id) async => []),
      ],
      child: const CollegeDetailScreen(collegeId: 'c1'),
    );

    expect(find.text('Test Engineering College'), findsWidgets);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
}