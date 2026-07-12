import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:college_reality_india/config/router/app_router.dart';
import 'package:college_reality_india/config/theme/app_theme.dart';
import 'package:college_reality_india/core/constants/rating_parameters.dart';
import 'package:college_reality_india/core/utils/college_image_helper.dart';
import 'package:college_reality_india/core/widgets/google_logo_icon.dart';
import 'package:college_reality_india/core/widgets/year_picker_field.dart';
import 'package:college_reality_india/features/reviews/models/review_model.dart';
import 'package:college_reality_india/features/reviews/providers/review_provider.dart';
import 'package:college_reality_india/main.dart';

void main() {
  testWidgets('App boots with MaterialApp router', (WidgetTester tester) async {
    final testRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('College Reality')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(testRouter),
        ],
        child: const CollegeRealityApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('College Reality'), findsOneWidget);
  });

  test('AppTheme exposes light and dark themes', () {
    expect(AppTheme.lightTheme.brightness, Brightness.light);
    expect(AppTheme.darkTheme.brightness, Brightness.dark);
  });

  test('RatingParameters defines 10 rating keys', () {
    expect(RatingParameters.allKeys.length, 10);
    expect(RatingParameters.emptyRatings().length, 10);
  });

  test('mergeReviews combines optimistic and stream reviews', () {
    final optimistic = [
      ReviewModel(
        id: 'new-1',
        collegeId: 'college_001',
        collegeName: 'Test College',
        userId: 'u1',
        anonymousAlias: 'Student #1',
        ratings: const {'overall': 4.0},
        createdAt: DateTime(2026, 1, 2),
        updatedAt: DateTime(2026, 1, 2),
      ),
    ];
    final stream = [
      ReviewModel(
        id: 'old-1',
        collegeId: 'college_001',
        collegeName: 'Test College',
        userId: 'u2',
        anonymousAlias: 'Student #2',
        ratings: const {'overall': 3.0},
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ];

    final merged = mergeReviews(streamReviews: stream, optimistic: optimistic);
    expect(merged.length, 2);
    expect(merged.first.id, 'new-1');
  });

  test('CollegeImageHelper returns null when cover is missing', () {
    expect(CollegeImageHelper.resolveCoverUrl(null), isNull);
    expect(CollegeImageHelper.resolveCoverUrl(''), isNull);
    expect(
      CollegeImageHelper.resolveCoverUrl('https://example.com/cover.jpg'),
      'https://example.com/cover.jpg',
    );
  });

  testWidgets('YearPickerField opens year dialog', (tester) async {
    int? selectedYear;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YearPickerField(
            label: 'Batch Year',
            value: null,
            onChanged: (year) => selectedYear = year,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(find.text('Select Batch Year'), findsOneWidget);
    final firstYearTile = find.byType(ListTile).first;
    final yearLabel = tester.widget<ListTile>(firstYearTile).title as Text;
    final pickedYear = int.parse(yearLabel.data!);
    await tester.tap(firstYearTile);
    await tester.pumpAndSettle();

    expect(selectedYear, pickedYear);
  });

  testWidgets('GoogleLogoIcon renders without asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GoogleLogoIcon(size: 24),
        ),
      ),
    );

    expect(find.byType(GoogleLogoIcon), findsOneWidget);
  });
}
