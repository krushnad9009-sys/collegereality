import 'dart:async';

import 'package:college_reality_india/config/router/route_names.dart';
import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:college_reality_india/core/widgets/async_state_widgets.dart';
import 'package:college_reality_india/features/colleges/providers/city_category_counts_provider.dart';
import 'package:college_reality_india/features/colleges/providers/college_provider.dart';
import 'package:college_reality_india/features/colleges/repositories/college_repository.dart';
import 'package:college_reality_india/features/colleges/screens/college_browse_screen.dart';
import 'package:college_reality_india/features/home/widgets/explore_by_city_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_harness.dart';

class _MockRepo extends Mock implements CollegeRepository {}

/// All-India counts: deliberately huge and distinctive, so any leak of them
/// into a city view is unmistakable.
const _allIndia = {
  'Engineering': 4400,
  'Medical': 1400,
  'MBA': 2300,
  'Law': 800,
  'Pharmacy': 1200,
  'Arts': 1400,
};

/// What each city really has, by stream (missing = 0).
const _cityCounts = <String, Map<String, int>>{
  'pune': {'Engineering': 45, 'Medical': 12, 'MBA': 1, 'Pharmacy': 7},
  'bangalore': {'Engineering': 90, 'Law': 5},
  'mumbai': {'Arts': 3},
  'nowhere': {},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => AppFonts.useSystemFallback = true);

  late _MockRepo repo;
  late bool allIndiaRead;

  /// Pumps the Browse route exactly as the router builds it (`?city=` is
  /// read from the URL), plus stub search/browse destinations.
  Future<void> pumpBrowse(
    WidgetTester tester, {
    required String location,
    Future<int> Function(String city, String category)? count,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repo = _MockRepo();
    when(
      () => repo.countSearchMatches(
        city: any(named: 'city'),
        category: any(named: 'category'),
      ),
    ).thenAnswer((inv) {
      final city = inv.namedArguments[#city] as String;
      final category = inv.namedArguments[#category] as String;
      if (count != null) return count(city, category);
      return Future.value(_cityCounts[city.toLowerCase()]?[category] ?? 0);
    });
    allIndiaRead = false;

    await pumpRouterApp(
      tester,
      initialLocation: location,
      overrides: [
        ...testAuthOverrides(),
        collegeRepositoryProvider.overrideWithValue(repo),
        collegeDataReadyProvider.overrideWith((ref) async => true),
        collegeCategoryCountsProvider.overrideWith((ref) async {
          allIndiaRead = true;
          return _allIndia;
        }),
        collegeCountProvider.overrideWith((ref) async => 45020),
      ],
      routes: [
        GoRoute(
          path: RouteNames.collegeBrowse,
          builder: (_, state) =>
              CollegeBrowseScreen(city: state.uri.queryParameters['city']),
        ),
        GoRoute(
          path: RouteNames.collegeSearch,
          builder: (_, state) => Text(
            'SEARCH category=${state.uri.queryParameters['category']} '
            'city=${state.uri.queryParameters['city']}',
          ),
        ),
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      ],
    );
  }

  group('route helper', () {
    test('collegeBrowseForCity puts the city in the query string', () {
      expect(
        RouteNames.collegeBrowseForCity('Pune'),
        '/college-browse?city=Pune',
      );
    });

    test('round-trips names with spaces and trims', () {
      final uri = Uri.parse(RouteNames.collegeBrowseForCity('  Navi Mumbai '));
      expect(uri.path, RouteNames.collegeBrowse);
      expect(uri.queryParameters['city'], 'Navi Mumbai');
    });
  });

  group('Browse with a city', () {
    testWidgets('lists each stream with the exact count IN that city', (
      tester,
    ) async {
      await pumpBrowse(tester, location: '/college-browse?city=Pune');
      await tester.pumpAndSettle();

      expect(find.text('Colleges in Pune'), findsOneWidget);
      expect(find.text('45 colleges in Pune'), findsOneWidget);
      expect(find.text('12 colleges in Pune'), findsOneWidget);
      expect(find.text('7 colleges in Pune'), findsOneWidget);
      // Singular for exactly one.
      expect(find.text('1 college in Pune'), findsOneWidget);
      // Each number sits directly under its own stream's title.
      final engineeringY = tester.getCenter(find.text('Engineering')).dy;
      final subtitleY = tester.getCenter(find.text('45 colleges in Pune')).dy;
      expect(subtitleY - engineeringY, inInclusiveRange(0, 40));
    });

    testWidgets('streams with no college in the city are not listed', (
      tester,
    ) async {
      await pumpBrowse(tester, location: '/college-browse?city=Pune');
      await tester.pumpAndSettle();

      for (final absent in ['Law', 'Arts', 'Commerce', 'Science', 'Nursing']) {
        expect(find.text(absent), findsNothing, reason: absent);
      }
      for (final present in ['Engineering', 'Medical', 'MBA', 'Pharmacy']) {
        expect(find.text(present), findsOneWidget, reason: present);
      }
    });

    testWidgets('asks for exactly one in-city count per stream, and never '
        'uses the all-India counts', (tester) async {
      await pumpBrowse(tester, location: '/college-browse?city=Pune');
      await tester.pumpAndSettle();

      for (final label in kBrowseCategoryLabels) {
        verify(
          () => repo.countSearchMatches(city: 'pune', category: label),
        ).called(1);
      }
      verifyNoMoreInteractions(repo);
      expect(allIndiaRead, isFalse, reason: 'generic counts must not be read');
      // ...nor shown.
      for (final generic in ['4400', '1400', '2300', '45020', 'India']) {
        expect(find.textContaining(generic), findsNothing, reason: generic);
      }
    });

    testWidgets('a different city shows that city\'s own counts', (
      tester,
    ) async {
      await pumpBrowse(tester, location: '/college-browse?city=Bangalore');
      await tester.pumpAndSettle();

      expect(find.text('Colleges in Bangalore'), findsOneWidget);
      expect(find.text('90 colleges in Bangalore'), findsOneWidget);
      expect(find.text('5 colleges in Bangalore'), findsOneWidget);
      expect(find.text('Medical'), findsNothing);
    });

    testWidgets('the city name is tidied ("pune" -> "Pune")', (tester) async {
      await pumpBrowse(tester, location: '/college-browse?city=pune');
      await tester.pumpAndSettle();
      expect(find.text('Colleges in Pune'), findsOneWidget);
      expect(find.text('45 colleges in Pune'), findsOneWidget);
    });

    testWidgets('while loading it shows a skeleton -- no counts, and '
        'certainly not the all-India ones', (tester) async {
      final pending = Completer<int>();
      await pumpBrowse(
        tester,
        location: '/college-browse?city=Pune',
        count: (city, category) => pending.future,
      );
      await tester.pump();

      expect(find.byType(ListSkeletonLoader), findsOneWidget);
      expect(find.textContaining('colleges'), findsNothing);
      expect(find.textContaining('4400'), findsNothing);
      expect(allIndiaRead, isFalse);

      pending.complete(3);
      await tester.pumpAndSettle();
      expect(find.byType(ListSkeletonLoader), findsNothing);
    });

    testWidgets('if a count fails it shows an error with retry -- never '
        'partial or all-India numbers', (tester) async {
      await pumpBrowse(
        tester,
        location: '/college-browse?city=Pune',
        count: (city, category) async => category == 'Law'
            ? throw StateError('boom')
            : 5, // the other streams succeeded
      );
      await tester.pumpAndSettle();

      expect(find.byType(AsyncErrorView), findsOneWidget);
      expect(find.textContaining('colleges in'), findsNothing);
      expect(find.text('Engineering'), findsNothing);
      expect(find.textContaining('4400'), findsNothing);
      expect(allIndiaRead, isFalse);
    });

    testWidgets('an unsupported (-1) count is treated as a failure, not '
        'displayed', (tester) async {
      await pumpBrowse(
        tester,
        location: '/college-browse?city=Pune',
        count: (city, category) async => -1,
      );
      await tester.pumpAndSettle();
      expect(find.byType(AsyncErrorView), findsOneWidget);
      expect(find.textContaining('-1'), findsNothing);
    });

    testWidgets('a city with no colleges shows an empty state that leads back '
        'to all of India', (tester) async {
      await pumpBrowse(tester, location: '/college-browse?city=Nowhere');
      await tester.pumpAndSettle();

      expect(find.text('No colleges found in Nowhere'), findsOneWidget);
      expect(find.textContaining('colleges in Nowhere'), findsNothing);

      await tester.tap(find.text('Browse all colleges'));
      await tester.pumpAndSettle();
      // Now unfiltered: the all-India counts are the right thing to show.
      expect(find.text('Browse Colleges'), findsOneWidget);
      expect(find.text('4400 colleges'), findsOneWidget);
    });

    testWidgets('tapping a stream searches THAT stream IN that city', (
      tester,
    ) async {
      await pumpBrowse(tester, location: '/college-browse?city=Pune');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Engineering'));
      await tester.pumpAndSettle();
      expect(
        find.text('SEARCH category=Engineering city=Pune'),
        findsOneWidget,
      );
    });

    testWidgets('the city chip clears the filter back to all of India', (
      tester,
    ) async {
      await pumpBrowse(tester, location: '/college-browse?city=Pune');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Show all of India'), findsOneWidget);

      await tester.tap(find.byTooltip('Show all of India'));
      await tester.pumpAndSettle();

      expect(find.text('Browse Colleges'), findsOneWidget);
      expect(find.text('4400 colleges'), findsOneWidget);
      expect(find.textContaining('in Pune'), findsNothing);
    });

    testWidgets('a blank city is no filter at all', (tester) async {
      await pumpBrowse(tester, location: '/college-browse?city=%20%20');
      await tester.pumpAndSettle();
      expect(find.text('Browse Colleges'), findsOneWidget);
      expect(find.text('4400 colleges'), findsOneWidget);
      verifyZeroInteractions(repo);
    });
  });

  group('Browse without a city (unchanged)', () {
    testWidgets('shows the all-India count per stream', (tester) async {
      await pumpBrowse(tester, location: '/college-browse');
      await tester.pumpAndSettle();

      expect(find.text('Browse Colleges'), findsOneWidget);
      expect(find.text('4400 colleges'), findsOneWidget);
      expect(find.text('1400 colleges'), findsNWidgets(2)); // Medical + Arts
      verifyZeroInteractions(repo);
    });

    testWidgets('tapping a stream searches it across India', (tester) async {
      await pumpBrowse(tester, location: '/college-browse');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Law'));
      await tester.pumpAndSettle();
      expect(find.text('SEARCH category=Law city=null'), findsOneWidget);
    });
  });

  group('Home city badges', () {
    testWidgets('tapping a badge opens Browse with city=<that city>', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: Center(child: ExploreCityCarousel())),
          ),
          GoRoute(
            path: RouteNames.collegeBrowse,
            builder: (_, state) =>
                Text('BROWSE city=${state.uri.queryParameters['city']}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pune'));
      await tester.pumpAndSettle();
      expect(find.text('BROWSE city=Pune'), findsOneWidget);

      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mumbai'));
      await tester.pumpAndSettle();
      expect(find.text('BROWSE city=Mumbai'), findsOneWidget);
    });
  });
}
