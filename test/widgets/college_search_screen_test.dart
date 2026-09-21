import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/providers/college_provider.dart';
import 'package:college_reality_india/features/colleges/screens/college_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

Future<void> _pumpSearch(WidgetTester tester, {bool showFilters = false}) {
  return pumpRouterApp(
    tester,
    initialLocation: '/college-search',
    overrides: [
      ...testAuthOverrides(),
      collegeDirectoryMetaProvider.overrideWith(
        (ref) async => const CollegeDirectoryMeta(totalColleges: 0),
      ),
      indianStatesProvider.overrideWith((ref) async => <String>[]),
      indianCoursesProvider.overrideWith((ref) async => <String>[]),
      collegeSearchPageProvider.overrideWith(
        (ref, params) async => const CollegeSearchPage(colleges: []),
      ),
    ],
    routes: [
      GoRoute(
        path: '/college-search',
        builder: (_, _) => CollegeSearchScreen(initialShowFilters: showFilters),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CollegeSearchScreen shows search chrome', (tester) async {
    await pumpRouterApp(
      tester,
      initialLocation: '/college-search',
      overrides: [
        ...testAuthOverrides(),
        collegeDirectoryMetaProvider.overrideWith(
          (ref) async => const CollegeDirectoryMeta(totalColleges: 0),
        ),
        indianStatesProvider.overrideWith((ref) async => <String>[]),
        indianCoursesProvider.overrideWith((ref) async => <String>[]),
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

  testWidgets('the filter panel is closed by default', (tester) async {
    await _pumpSearch(tester);
    expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.filter_alt), findsNothing);
  });

  testWidgets('initialShowFilters opens the filter panel (the Home header '
      'Filter button) without starting a search', (tester) async {
    await _pumpSearch(tester, showFilters: true);
    // The toggle shows its "open" state...
    expect(find.byIcon(Icons.filter_alt), findsOneWidget);
    // ...and no search ran, so no results header/empty state appeared.
    expect(find.text('No colleges found'), findsNothing);
  });
}
