import 'package:college_reality_india/core/constants/college_constants.dart';
import 'package:college_reality_india/features/colleges/screens/college_search_screen.dart';
import 'package:college_reality_india/features/colleges/utils/college_search_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CollegeConstants filter safety', () {
    test('collegeCategories includes Nursing and browse categories', () {
      expect(CollegeConstants.collegeCategories, contains('Nursing'));
      expect(CollegeConstants.collegeCategories, contains('Polytechnic'));
      expect(CollegeConstants.collegeCategories, contains('Agriculture'));
      expect(CollegeConstants.collegeCategories, contains('Architecture'));
    });

    test('dedupePreserveOrder removes case-insensitive duplicates', () {
      final result = CollegeConstants.dedupePreserveOrder([
        'B.Tech',
        'b.tech',
        'MBA',
        'MBA',
        ' Nursing ',
      ]);
      expect(result, ['B.Tech', 'MBA', 'Nursing']);
    });

    test('clampToAllowed returns null for unknown values', () {
      expect(
        CollegeConstants.clampToAllowed(
          'Nursing',
          CollegeConstants.collegeCategories,
        ),
        'Nursing',
      );
      expect(
        CollegeConstants.clampToAllowed(
          'UnknownCat',
          CollegeConstants.collegeCategories,
        ),
        isNull,
      );
    });
  });

  group('CollegeSearchUtils state aliases', () {
    test('maps common misspellings to canonical forms', () {
      expect(
        CollegeSearchUtils.normalizeState('Chhatisgarh'),
        CollegeSearchUtils.normalizeState('Chhattisgarh'),
      );
      expect(
        CollegeSearchUtils.normalizeState('Uttrakhand'),
        CollegeSearchUtils.normalizeState('Uttarakhand'),
      );
      expect(
        CollegeSearchUtils.normalizeState('Orissa'),
        CollegeSearchUtils.normalizeState('Odisha'),
      );
    });
  });

  group('CollegeSearchScreen filter deep links', () {
    void setTallSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('Nursing category deep link does not crash dropdown',
        (tester) async {
      setTallSurface(tester);
      await pumpRouterApp(
        tester,
        initialLocation: '/college-search?category=Nursing',
        overrides: testAuthOverrides(),
        routes: [
          GoRoute(
            path: '/college-search',
            builder: (context, state) {
              final category = state.uri.queryParameters['category'];
              return CollegeSearchScreen(initialCategory: category);
            },
          ),
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Search Colleges'), findsAtLeastNWidgets(1));
      expect(find.text('Nursing'), findsAtLeastNWidgets(1));
    });
  });

  group('Browse vs search category parity', () {
    test('every browse category is searchable', () {
      const browse = [
        'Engineering',
        'Medical',
        'MBA',
        'Law',
        'Pharmacy',
        'Arts',
        'Commerce',
        'Science',
        'Polytechnic',
        'Nursing',
        'Agriculture',
        'Architecture',
      ];
      for (final label in browse) {
        expect(CollegeConstants.collegeCategories, contains(label));
      }
    });
  });
}