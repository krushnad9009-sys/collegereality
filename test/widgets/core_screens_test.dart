import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/providers/college_provider.dart';
import 'package:college_reality_india/features/colleges/screens/college_search_screen.dart';
import 'package:college_reality_india/features/profile/screens/profile_screen.dart';
import 'package:college_reality_india/features/ecosystem/screens/request_college_screen.dart';
import 'package:college_reality_india/features/community/screens/community_hub_screen.dart';
import 'package:college_reality_india/features/reviews/screens/write_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ProfileScreen asks guests to log in', (tester) async {
    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const ProfileScreen(),
    );
    expect(find.text('Please log in to view your profile'), findsOneWidget);
  });

  testWidgets('RequestCollegeScreen asks guests to sign in', (tester) async {
    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const RequestCollegeScreen(),
    );
    expect(find.textContaining('Sign in to add your college'), findsOneWidget);
  });

  testWidgets('WriteReviewScreen asks guests to log in', (tester) async {
    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const WriteReviewScreen(collegeId: 'c1', collegeName: 'Test College'),
    );
    expect(find.textContaining('Please log in to write a review'), findsOneWidget);
  });

  testWidgets('CommunityHubScreen renders community hero', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const CommunityHubScreen(),
    );
    expect(find.text('Student Community'), findsOneWidget);
    expect(find.text('Ask Seniors'), findsOneWidget);
  });

  testWidgets('CollegeSearchScreen renders with mocked directory meta',
      (tester) async {
    await pumpRouterApp(
      tester,
      initialLocation: '/college-search',
      overrides: [
        ...testAuthOverrides(),
        collegeDirectoryMetaProvider.overrideWith(
          (ref) async => const CollegeDirectoryMeta(totalColleges: 0),
        ),
        indianStatesProvider.overrideWith((ref) async => <String>['Maharashtra']),
        indianCoursesProvider.overrideWith((ref) async => <String>['B.Tech']),
        collegeSearchPageProvider.overrideWith(
          (ref, params) async => const CollegeSearchPage(colleges: []),
        ),
      ],
      routes: [
        GoRoute(
          path: '/college-search',
          builder: (_, _) => const CollegeSearchScreen(),
        ),
      ],
    );

    expect(find.text('Search Colleges'), findsWidgets);
  });
}