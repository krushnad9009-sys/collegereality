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

  test('CollegeImageHelper returns fallback URL when cover is missing', () {
    final url = CollegeImageHelper.getCoverImageUrl('college-001');
    expect(url, startsWith('https://picsum.photos/seed/college'));
    expect(
      CollegeImageHelper.getCoverImageUrl(
        'college-001',
        coverPhotoUrl: 'https://example.com/cover.jpg',
      ),
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
