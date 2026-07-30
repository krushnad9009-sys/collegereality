import 'package:college_reality_india/features/auth/screens/login_screen.dart';
import 'package:college_reality_india/features/auth/screens/onboarding_screen.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/providers/college_provider.dart';
import 'package:college_reality_india/features/colleges/screens/college_search_screen.dart';
import 'package:college_reality_india/features/ecosystem/screens/request_college_screen.dart';
import 'package:college_reality_india/features/reviews/screens/write_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

CollegeModel _college() {
  return CollegeModel(
    id: 'c1',
    name: 'Flow Test College',
    nameLower: 'flow test college',
    slug: 'c1',
    city: 'Pune',
    cityLower: 'pune',
    district: 'Pune',
    districtLower: 'pune',
    state: 'Maharashtra',
    stateLower: 'maharashtra',
    address: 'Pune',
    type: 'private',
    courses: const ['B.Tech'],
    fees: const CollegeFees(tuitionMin: 1, tuitionMax: 2, hostelAnnual: 1),
    placements: const CollegePlacements(
      highestPackageLpa: 10,
      averagePackageLpa: 5,
      placementPercentage: 70,
    ),
    accreditation: const CollegeAccreditation(),
    aggregatedRatings: const CollegeRatings(
      overall: 4,
      faculty: 4,
      infrastructure: 4,
      placements: 4,
      campusLife: 4,
    ),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Future<void> _resetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'critical flow: launch, onboarding, login, search, details, review, add college',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1) App launch
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('College Reality'))),
    );
    expect(find.text('College Reality'), findsOneWidget);
    await _resetTree(tester);

    // 2) Onboarding
    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const OnboardingScreen(),
    );
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await _resetTree(tester);

    // 3) Login
    final auth = FakeAuthService();
    await pumpRouterApp(
      tester,
      initialLocation: '/login',
      overrides: testAuthOverrides(authService: auth),
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/signup',
          builder: (_, _) => const Scaffold(body: Text('SIGNUP')),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const Scaffold(body: Text('FORGOT')),
        ),
      ],
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'student@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'College1');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    await _resetTree(tester);

    // 4) Search colleges
    await pumpRouterApp(
      tester,
      initialLocation: '/college-search',
      overrides: [
        ...testAuthOverrides(),
        collegeDirectoryMetaProvider.overrideWith(
          (ref) async => const CollegeDirectoryMeta(totalColleges: 1),
        ),
        indianStatesProvider.overrideWith((ref) async => <String>['Maharashtra']),
        indianCoursesProvider.overrideWith((ref) async => <String>['B.Tech']),
        collegeSearchPageProvider.overrideWith(
          (ref, params) async => CollegeSearchPage(colleges: [_college()]),
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
    await _resetTree(tester);

    // 5) College details
    await pumpScreen(
      tester,
      overrides: [
        ...testAuthOverrides(),
        collegeByIdProvider.overrideWith((ref, id) async => _college()),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final async = ref.watch(collegeByIdProvider('c1'));
          return async.when(
            data: (c) => Scaffold(body: Text(c?.name ?? 'missing')),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('$e'),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flow Test College'), findsOneWidget);
    await _resetTree(tester);

    // 6) Submit review (auth gate)
    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const WriteReviewScreen(
        collegeId: 'c1',
        collegeName: 'Flow Test College',
      ),
    );
    expect(find.textContaining('Please log in to write a review'), findsOneWidget);
    await _resetTree(tester);

    // 7) Add My College (auth gate)
    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const RequestCollegeScreen(),
    );
    expect(find.textContaining('Sign in to add your college'), findsOneWidget);
  });
}
