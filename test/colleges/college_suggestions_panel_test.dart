import 'dart:async';

import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:college_reality_india/config/theme/app_theme.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/providers/college_name_suggestion_provider.dart';
import 'package:college_reality_india/features/colleges/utils/college_suggestion_utils.dart';
import 'package:college_reality_india/features/colleges/widgets/college_suggestions_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CollegeModel college(
  String name, {
  String city = '',
  String state = '',
  String? id,
}) {
  return CollegeModel.createDraft(id: id ?? name).copyWith(
    name: name,
    nameLower: name.toLowerCase(),
    city: city,
    state: state,
  );
}

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
final jaipur = college(
  'Jaipur National University',
  city: 'Jaipur',
  state: 'Rajasthan',
);
// Sits in a "ja…" city but its NAME does not match "ja".
final cityOnly = college(
  'Rajasthan Technical Institute',
  city: 'Jaipur',
  state: 'Rajasthan',
);

void main() {
  setUpAll(() => AppFonts.useSystemFallback = true);

  group('NameSuggestionsNotifier', () {
    test('fetches for the trimmed query and publishes the answer', () async {
      final asked = <String>[];
      final notifier = NameSuggestionsNotifier((q) async {
        asked.add(q);
        return [jnec];
      });

      await notifier.setQuery('  ja ');
      expect(asked, ['ja']);
      expect(notifier.state.query, 'ja');
      expect(notifier.state.colleges, [jnec]);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.failed, isFalse);
    });

    test('does not refetch a query it already answered', () async {
      var calls = 0;
      final notifier = NameSuggestionsNotifier((q) async {
        calls++;
        return [jnec];
      });
      await notifier.setQuery('ja');
      await notifier.setQuery('ja');
      expect(calls, 1);
    });

    test('keeps the previous answer visible while a new query loads', () async {
      final pending = Completer<List<CollegeModel>>();
      var first = true;
      final notifier = NameSuggestionsNotifier((q) {
        if (first) {
          first = false;
          return Future.value([jnec, jain]);
        }
        return pending.future;
      });

      await notifier.setQuery('ja');
      final inFlight = notifier.setQuery('jaw');
      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.query, 'jaw');
      expect(notifier.state.colleges, [jnec, jain], reason: 'stale, not empty');

      pending.complete([jnec]);
      await inFlight;
      expect(notifier.state.colleges, [jnec]);
      expect(notifier.state.isLoading, isFalse);
    });

    test('ignores a slow response that arrives after a newer query', () async {
      final slow = Completer<List<CollegeModel>>();
      final notifier = NameSuggestionsNotifier((q) {
        return q == 'ja' ? slow.future : Future.value([jnec]);
      });

      final first = notifier.setQuery('ja'); // slow
      await notifier.setQuery('jaw'); // fast, newer
      slow.complete([jain]); // old answer lands late
      await first;

      expect(notifier.state.query, 'jaw');
      expect(notifier.state.colleges, [jnec]);
    });

    test('a failed lookup is reported, with no colleges', () async {
      final notifier = NameSuggestionsNotifier(
        (q) async => throw StateError('x'),
      );
      await notifier.setQuery('ja');
      expect(notifier.state.failed, isTrue);
      expect(notifier.state.colleges, isEmpty);
      expect(notifier.state.isLoading, isFalse);
    });

    test('clearing the query resets everything', () async {
      final notifier = NameSuggestionsNotifier((q) async => [jnec]);
      await notifier.setQuery('ja');
      await notifier.setQuery('');
      expect(notifier.state.query, '');
      expect(notifier.state.colleges, isEmpty);
    });
  });

  group('CollegeSuggestionsPanel', () {
    late ProviderContainer container;
    late CollegeNameFetcher fetch;
    List<CollegeModel>? tappedColleges;
    List<PlaceSuggestion>? tappedPlaces;

    Future<void> pumpPanel(WidgetTester tester, String query) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CollegeSuggestionsPanel(
                query: query,
                onCollegeTap: (c) => tappedColleges!.add(c),
                onPlaceTap: (p) => tappedPlaces!.add(p),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> ask(WidgetTester tester, String query) async {
      await container
          .read(collegeNameSuggestionsProvider.notifier)
          .setQuery(query);
      await tester.pump();
    }

    setUp(() {
      tappedColleges = [];
      tappedPlaces = [];
      fetch = (q) async => [];
      container = ProviderContainer(
        overrides: [
          collegeNameSuggestionsProvider.overrideWith(
            (ref) => NameSuggestionsNotifier((q) => fetch(q)),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    Finder collegeRow(CollegeModel c) =>
        find.byKey(ValueKey('college-suggestion-${c.id}'));
    Finder placeRow(String label) =>
        find.byKey(ValueKey('place-suggestion-$label'));

    testWidgets('typing "ja": matching college NAMES are listed, best first, '
        'each with "City, State" underneath in smaller text', (tester) async {
      fetch = (q) async => [jain, jnec, jaipur, cityOnly];
      await pumpPanel(tester, 'ja');
      await ask(tester, 'ja');

      // Names that match are shown; the city-only college is not.
      expect(collegeRow(jain), findsOneWidget);
      expect(collegeRow(jnec), findsOneWidget);
      expect(collegeRow(jaipur), findsOneWidget);
      expect(collegeRow(cityOnly), findsNothing);

      // Best first: shortest of the equal "starts with ja" names leads.
      final ys = [
        jain,
        jaipur,
        jnec,
      ].map((c) => tester.getTopLeft(collegeRow(c)).dy).toList();
      expect(ys, orderedEquals([...ys]..sort()));

      // The location is beneath the name, and smaller.
      final title = find.descendant(
        of: collegeRow(jnec),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.textSpan != null &&
              w.textSpan!.toPlainText() == jnec.name,
        ),
      );
      final location = find.descendant(
        of: collegeRow(jnec),
        matching: find.text('Aurangabad, Maharashtra'),
      );
      expect(title, findsOneWidget);
      expect(location, findsOneWidget);
      expect(
        tester.getTopLeft(location).dy,
        greaterThan(tester.getBottomLeft(title).dy - 1),
      );
      final titleSize = tester.widget<Text>(title).textSpan!.style!.fontSize!;
      final locationSize = tester.widget<Text>(location).style!.fontSize!;
      expect(locationSize, lessThan(titleSize));

      // No state/city fallback rows while names match.
      expect(find.text('State'), findsNothing);
      expect(find.text('City'), findsNothing);
      expect(find.byIcon(Icons.map_outlined), findsNothing);
    });

    testWidgets('the matched letters are bold', (tester) async {
      fetch = (q) async => [jnec];
      await pumpPanel(tester, 'jaw');
      await ask(tester, 'jaw');

      final title = tester.widget<Text>(
        find.descendant(
          of: collegeRow(jnec),
          matching: find.byWidgetPredicate(
            (w) => w is Text && w.textSpan?.toPlainText() == jnec.name,
          ),
        ),
      );
      final spans = (title.textSpan! as TextSpan).children!.cast<TextSpan>();
      final bold = spans.where((s) => s.style?.fontWeight == FontWeight.w800);
      expect(bold.map((s) => s.text), ['Jaw']);
    });

    testWidgets('if NO college name matches, it falls back to matching '
        'states and cities', (tester) async {
      fetch = (q) async => [];
      await pumpPanel(tester, 'jamm');
      await ask(tester, 'jamm');

      expect(placeRow('Jammu and Kashmir'), findsOneWidget);
      expect(
        find.descendant(
          of: placeRow('Jammu and Kashmir'),
          matching: find.text('State'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.school_rounded), findsNothing);
    });

    testWidgets('colleges returned for the wrong reason (only their city '
        'matches) do not count as name matches -> fallback', (tester) async {
      fetch = (q) async => [cityOnly];
      await pumpPanel(tester, 'jamm');
      await ask(tester, 'jamm');

      expect(collegeRow(cityOnly), findsNothing);
      expect(placeRow('Jammu and Kashmir'), findsOneWidget);
    });

    testWidgets('when a name matches, states/cities are NOT shown even if '
        'they would match too', (tester) async {
      final dtu = college(
        'Delhi Technological University',
        city: 'Delhi',
        state: 'Delhi',
      );
      fetch = (q) async => [dtu];
      await pumpPanel(tester, 'delhi');
      await ask(tester, 'delhi');

      expect(collegeRow(dtu), findsOneWidget);
      expect(placeRow('Delhi'), findsNothing);
    });

    testWidgets('while the lookup is still running it shows nothing rather '
        'than flashing places that names might replace', (tester) async {
      final pending = Completer<List<CollegeModel>>();
      fetch = (q) => pending.future;
      await pumpPanel(tester, 'jamm');
      final inFlight = container
          .read(collegeNameSuggestionsProvider.notifier)
          .setQuery('jamm');
      await tester.pump();

      expect(placeRow('Jammu and Kashmir'), findsNothing);
      expect(find.byType(ListView), findsNothing);

      pending.complete([]);
      await inFlight;
      await tester.pump();
      expect(placeRow('Jammu and Kashmir'), findsOneWidget);
    });

    testWidgets('typing another letter narrows the list immediately, before '
        'the new lookup returns', (tester) async {
      fetch = (q) async => [jain, jnec, jaipur];
      await pumpPanel(tester, 'ja');
      await ask(tester, 'ja');
      expect(collegeRow(jain), findsOneWidget);

      // "jaip": lookup pending, but the stale list is narrowed locally.
      final pending = Completer<List<CollegeModel>>();
      fetch = (q) => pending.future;
      await pumpPanel(tester, 'jaip');
      final inFlight = container
          .read(collegeNameSuggestionsProvider.notifier)
          .setQuery('jaip');
      await tester.pump();

      expect(collegeRow(jaipur), findsOneWidget);
      expect(collegeRow(jain), findsNothing);
      expect(collegeRow(jnec), findsNothing);

      pending.complete([jaipur]);
      await inFlight;
    });

    testWidgets('tapping a row reports the college / place', (tester) async {
      fetch = (q) async => [jnec];
      await pumpPanel(tester, 'jaw');
      await ask(tester, 'jaw');
      await tester.tap(collegeRow(jnec));
      expect(tappedColleges, [jnec]);

      fetch = (q) async => [];
      await pumpPanel(tester, 'jamm');
      await ask(tester, 'jamm');
      await tester.tap(placeRow('Jammu and Kashmir'));
      expect(tappedPlaces, [
        const PlaceSuggestion('Jammu and Kashmir', SuggestionKind.state),
      ]);
    });

    testWidgets('an empty query draws nothing', (tester) async {
      fetch = (q) async => [jnec];
      await pumpPanel(tester, '   ');
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('a failed lookup falls back to places instead of an error', (
      tester,
    ) async {
      fetch = (q) async => throw StateError('offline');
      await pumpPanel(tester, 'jamm');
      await ask(tester, 'jamm');
      expect(placeRow('Jammu and Kashmir'), findsOneWidget);
    });

    test('highlightRange finds the literal match, case-insensitively', () {
      expect(CollegeSuggestionsPanel.highlightRange('Jain College', 'JAI'), (
        start: 0,
        end: 3,
      ));
      expect(
        CollegeSuggestionsPanel.highlightRange('Shri Jain College', 'jain'),
        (start: 5, end: 9),
      );
      // Initials / out-of-order matches have nothing literal to bold.
      expect(
        CollegeSuggestionsPanel.highlightRange(
          'Indian Institute of Technology',
          'iit',
        ),
        isNull,
      );
      expect(CollegeSuggestionsPanel.highlightRange('Jain', ' '), isNull);
    });
  });
}
