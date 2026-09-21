import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/engagement/providers/engagement_provider.dart';
import 'package:college_reality_india/features/home/widgets/home_personalized_sections.dart';
import 'package:college_reality_india/features/personalization/models/user_preferences.dart';
import 'package:college_reality_india/features/personalization/providers/personalized_colleges_provider.dart';
import 'package:college_reality_india/features/personalization/providers/user_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

Override _prefs(UserPreferences prefs) => userPreferencesProvider.overrideWith(
  (ref) => UserPreferencesNotifier(ref, prefs),
);

Override _recommended(PersonalizedFeed feed) =>
    recommendedCollegesProvider.overrideWith((ref) async => feed);

Override _nearYou(PersonalizedFeed feed) =>
    collegesNearYouProvider.overrideWith((ref) async => feed);

void main() {
  setUpAll(() => AppFonts.useSystemFallback = true);

  group('RecommendedCollegesSection', () {
    testWidgets(
      'personalized feed is titled for the user and names the stream',
      (tester) async {
        await pumpScreen(
          tester,
          overrides: [
            _prefs(const UserPreferences(preferredCategory: 'Arts')),
            _recommended(
              const PersonalizedFeed(
                colleges: [],
                isPersonalized: true,
                matchedOn: 'Arts',
              ),
            ),
          ],
          child: const Scaffold(body: RecommendedCollegesSection()),
        );

        expect(find.text('Recommended for You'), findsOneWidget);
        expect(
          find.text('Top-rated Arts colleges, picked for you'),
          findsOneWidget,
        );
        expect(find.text('Top Rated Colleges'), findsNothing);
      },
    );

    testWidgets('global fallback is labelled honestly, not as personalised', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        overrides: [
          _prefs(UserPreferences.empty),
          _recommended(const PersonalizedFeed(colleges: [])),
        ],
        child: const Scaffold(body: RecommendedCollegesSection()),
      );

      expect(find.text('Top Rated Colleges'), findsOneWidget);
      expect(find.text('Recommended for You'), findsNothing);
    });
  });

  group('CollegesNearYouSection', () {
    testWidgets('shows the state and its colleges when a feed exists', (
      tester,
    ) async {
      final college = CollegeModel.createDraft(id: 'c1').copyWith(
        name: 'Goa Institute of Testing',
        city: 'Panaji',
        state: 'Goa',
      );
      await pumpScreen(
        tester,
        overrides: [
          _prefs(const UserPreferences(preferredState: 'Goa')),
          _nearYou(
            PersonalizedFeed(
              colleges: [college],
              isPersonalized: true,
              matchedOn: 'Goa',
            ),
          ),
          favoriteCollegeIdsProvider.overrideWith(
            (ref) => Stream.value(<String>{}),
          ),
        ],
        child: const Scaffold(body: CollegesNearYouSection()),
      );

      expect(find.text('Colleges Near You'), findsOneWidget);
      expect(find.text('Top-rated colleges in Goa'), findsOneWidget);
      expect(find.text('Goa Institute of Testing'), findsOneWidget);
    });

    testWidgets('renders nothing when no state is known', (tester) async {
      await pumpScreen(
        tester,
        overrides: [
          _prefs(UserPreferences.empty),
          _nearYou(PersonalizedFeed.empty),
        ],
        child: const Scaffold(body: CollegesNearYouSection()),
      );

      expect(find.text('Colleges Near You'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders nothing when the state has no colleges', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        overrides: [
          _prefs(const UserPreferences(preferredState: 'Goa')),
          _nearYou(PersonalizedFeed.empty),
        ],
        child: const Scaffold(body: CollegesNearYouSection()),
      );

      expect(find.text('Colleges Near You'), findsNothing);
    });
  });
}
