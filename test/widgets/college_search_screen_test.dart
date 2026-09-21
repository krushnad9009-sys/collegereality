import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/providers/college_name_suggestion_provider.dart';
import 'package:college_reality_india/features/colleges/providers/college_provider.dart';
import 'package:college_reality_india/features/colleges/screens/college_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

Future<void> _pumpSearch(
  WidgetTester tester, {
  bool showFilters = false,
  List<Override> extraOverrides = const [],
}) {
  // A phone-sized window tall enough for the field, the dropdown AND the
  // results area beneath it (the default test window is only 600px high).
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return pumpRouterApp(
    tester,
    initialLocation: '/college-search',
    overrides: [
      ...testAuthOverrides(),
      ...extraOverrides,
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

  group('search suggestions (typing in the search bar)', () {
    CollegeModel college(String name, {String city = '', String state = ''}) =>
        CollegeModel.createDraft(id: name).copyWith(
          name: name,
          nameLower: name.toLowerCase(),
          city: city,
          state: state,
        );

    final jnec = college(
      'Jawaharlal Nehru Engineering College',
      city: 'Aurangabad',
      state: 'Maharashtra',
    );
    final jain = college(
      'Jain College of Commerce',
      city: 'Bengaluru',
      state: 'Karnataka',
    );

    Override suggestionsFrom(
      Future<List<CollegeModel>> Function(String) fetch,
    ) => collegeNameSuggestionsProvider.overrideWith(
      (ref) => NameSuggestionsNotifier(fetch),
    );

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField).first, text);
      // Past the screen's 250ms debounce, then let the lookup resolve.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();
    }

    String fieldText(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField).first).controller!.text;

    testWidgets('"ja" lists college names first, with City, State beneath', (
      tester,
    ) async {
      await _pumpSearch(
        tester,
        extraOverrides: [
          suggestionsFrom((q) async => [jain, jnec]),
        ],
      );
      await type(tester, 'ja');

      expect(find.text('Aurangabad, Maharashtra'), findsOneWidget);
      expect(find.text('Bengaluru, Karnataka'), findsOneWidget);
      // Names, not the static state/city corpus ("Jammu and Kashmir", ...).
      expect(find.text('Jammu and Kashmir'), findsNothing);
      expect(find.byIcon(Icons.school_rounded), findsNWidgets(2));
    });

    testWidgets('with no college-name match it falls back to states/cities', (
      tester,
    ) async {
      await _pumpSearch(
        tester,
        extraOverrides: [suggestionsFrom((q) async => [])],
      );
      await type(tester, 'jamm');

      expect(find.text('Jammu and Kashmir'), findsOneWidget);
      expect(find.text('State'), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsNothing);
    });

    testWidgets('tapping a college fills the search bar with its name and '
        'closes the dropdown', (tester) async {
      await _pumpSearch(
        tester,
        extraOverrides: [
          suggestionsFrom((q) async => [jnec]),
        ],
      );
      await type(tester, 'jaw');
      expect(find.text('Aurangabad, Maharashtra'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fieldText(tester), 'Jawaharlal Nehru Engineering College');
      expect(find.text('Aurangabad, Maharashtra'), findsNothing);
    });

    testWidgets('clearing the text hides the dropdown', (tester) async {
      await _pumpSearch(
        tester,
        extraOverrides: [
          suggestionsFrom((q) async => [jnec]),
        ],
      );
      await type(tester, 'jaw');
      expect(find.text('Aurangabad, Maharashtra'), findsOneWidget);

      await type(tester, '');
      expect(find.text('Aurangabad, Maharashtra'), findsNothing);
    });
  });
}
