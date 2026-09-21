import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/utils/college_name_matcher.dart';
import 'package:college_reality_india/features/colleges/utils/college_suggestion_utils.dart';
import 'package:flutter_test/flutter_test.dart';

CollegeModel college(
  String name, {
  String city = '',
  String state = '',
  String district = '',
  String? id,
}) {
  return CollegeModel.createDraft(id: id ?? name).copyWith(
    name: name,
    nameLower: name.toLowerCase(),
    city: city,
    state: state,
    district: district,
  );
}

List<String> names(List<CollegeModel> colleges) =>
    colleges.map((c) => c.name).toList();

void main() {
  group('CollegeNameMatcher.score', () {
    test('ranks exact > prefix > word-start > initials > mid-word', () {
      final exact = CollegeNameMatcher.score('jain', 'Jain');
      final prefix = CollegeNameMatcher.score('jain', 'Jain College');
      final word = CollegeNameMatcher.score('jain', 'Shri Jain College');
      final initials = CollegeNameMatcher.score(
        'jcs',
        'Jain College of Science',
      );
      final mid = CollegeNameMatcher.score('ain', 'Jain College');
      expect(exact, greaterThan(prefix));
      expect(prefix, greaterThan(word));
      expect(word, greaterThan(initials));
      expect(initials, greaterThan(mid));
      expect(mid, greaterThan(0));
    });

    test('is 0 when the name does not match', () {
      expect(CollegeNameMatcher.score('xyz', 'Jain College'), 0);
      expect(CollegeNameMatcher.score('', 'Jain College'), 0);
      expect(CollegeNameMatcher.score('ja', ''), 0);
    });

    test('ignores case, punctuation and apostrophes', () {
      expect(
        CollegeNameMatcher.score('st xaviers', "St. Xavier's College"),
        greaterThan(0),
      );
      expect(
        CollegeNameMatcher.score('XAVIER', "St. Xavier's College"),
        greaterThan(0),
      );
      expect(
        CollegeNameMatcher.score('st. xavier', "St Xavier's College"),
        greaterThan(0),
      );
    });

    test('a mid-word hit needs 3+ letters (2 letters is just noise)', () {
      // "ja" sits inside "Rajaram" and "Maharaja" but starts no word.
      expect(CollegeNameMatcher.score('ja', 'Rajaram College'), 0);
      expect(CollegeNameMatcher.score('ja', 'Maharaja Institute'), 0);
      expect(
        CollegeNameMatcher.score('jar', 'Rajaram College'),
        greaterThan(0),
      );
    });

    test('several words match in any order', () {
      const name = 'Jawaharlal Nehru Engineering College';
      expect(CollegeNameMatcher.score('nehru eng', name), greaterThan(0));
      expect(
        CollegeNameMatcher.score('engineering jawaharlal', name),
        greaterThan(0),
      );
      expect(CollegeNameMatcher.score('nehru medical', name), 0);
    });

    test('matches the initials of a name, skipping filler words', () {
      expect(
        CollegeNameMatcher.score(
          'iit',
          'Indian Institute of Technology Bombay',
        ),
        greaterThan(0),
      );
      expect(
        CollegeNameMatcher.score(
          'jnec',
          'Jawaharlal Nehru Engineering College',
        ),
        greaterThan(0),
      );
    });

    test('works with non-Latin names', () {
      expect(CollegeNameMatcher.score('दिल्ली', 'दिल्ली विश्वविद्यालय'), 900);
    });
  });

  group('CollegeNameMatcher.rank', () {
    test('typing "ja": college NAMES beat colleges that merely sit in a '
        'matching city or state', () {
      final results = CollegeNameMatcher.rank('ja', [
        // Sits in Jaipur / Jharkhand but the NAME has nothing to do with "ja".
        college(
          'Rajasthan Technical Institute',
          city: 'Jaipur',
          state: 'Rajasthan',
        ),
        college('Ranchi Polytechnic', city: 'Ranchi', state: 'Jharkhand'),
        college(
          'Institute of Science',
          city: 'Jammu',
          state: 'Jammu and Kashmir',
        ),
        // Real name matches.
        college(
          'Jawaharlal Nehru Engineering College',
          city: 'Aurangabad',
          state: 'Maharashtra',
        ),
        college(
          'Jain College of Commerce',
          city: 'Bengaluru',
          state: 'Karnataka',
        ),
      ]);

      expect(names(results), [
        'Jain College of Commerce',
        'Jawaharlal Nehru Engineering College',
      ]);
    });

    test('name-prefix matches come before a later-word match', () {
      final results = CollegeNameMatcher.rank('ja', [
        college('Government College, Jaipur'), // "ja" starts the LAST word
        college('Jadavpur University'), // name starts with "ja"
        college('Shri Jain Polytechnic'), // "ja" starts a middle word
      ]);
      expect(names(results).first, 'Jadavpur University');
      expect(names(results).toSet(), {
        'Jadavpur University',
        'Government College, Jaipur',
        'Shri Jain Polytechnic',
      });
    });

    test('an exact name beats a longer prefix match', () {
      final results = CollegeNameMatcher.rank('jain', [
        college('Jain College of Science'),
        college('Jain'),
      ]);
      expect(names(results), ['Jain', 'Jain College of Science']);
    });

    test('ties: earlier match, then shorter name, then alphabetical', () {
      final results = CollegeNameMatcher.rank('ja', [
        college('Jabalpur Engineering College'),
        college('Jaipur College'),
        college('Jain University'),
      ]);
      // Same score and position; shortest first, then alphabetical.
      expect(names(results), [
        'Jaipur College',
        'Jain University',
        'Jabalpur Engineering College',
      ]);
    });

    test('is stable regardless of input order', () {
      final input = [
        college('Jain University'),
        college('Jaipur College'),
        college('Jadavpur University'),
      ];
      final a = names(CollegeNameMatcher.rank('ja', input));
      final b = names(CollegeNameMatcher.rank('ja', input.reversed));
      expect(a, b);
    });

    test('honours the limit and de-duplicates by id', () {
      final many = [
        for (var i = 0; i < 20; i++) college('Jain College $i', id: 'id$i'),
        college('Jain College 0 (dup)', id: 'id0'),
      ];
      final results = CollegeNameMatcher.rank('jain', many, limit: 5);
      expect(results, hasLength(5));
      expect(results.map((c) => c.id).toSet(), hasLength(5));
    });

    test('a blank query lists nothing', () {
      expect(
        CollegeNameMatcher.rank('   ', [college('Jain College')]),
        isEmpty,
      );
    });

    test('narrowing the query only ever removes rows (safe to re-rank a '
        'stale list as the user types)', () {
      final all = [
        college('Jadavpur University'),
        college('Jain College'),
        college('Jaipur College'),
        college('Jawaharlal Nehru Engineering College'),
      ];
      final ja = names(CollegeNameMatcher.rank('ja', all)).toSet();
      final jai = names(CollegeNameMatcher.rank('jai', all)).toSet();
      final jaip = names(CollegeNameMatcher.rank('jaip', all)).toSet();
      expect(ja.containsAll(jai), isTrue);
      expect(jai.containsAll(jaip), isTrue);
      expect(jaip, {'Jaipur College'});
    });
  });

  group('CollegeNameMatcher.locationLabel', () {
    test('is "City, State"', () {
      expect(
        CollegeNameMatcher.locationLabel(
          college('X', city: 'Aurangabad', state: 'Maharashtra'),
        ),
        'Aurangabad, Maharashtra',
      );
    });

    test('falls back to the district, and copes with missing parts', () {
      expect(
        CollegeNameMatcher.locationLabel(
          college('X', district: 'Beed', state: 'Maharashtra'),
        ),
        'Beed, Maharashtra',
      );
      expect(
        CollegeNameMatcher.locationLabel(college('X', state: 'Goa')),
        'Goa',
      );
      expect(CollegeNameMatcher.locationLabel(college('X')), '');
    });
  });

  group('CollegeSuggestionUtils.placeSuggestions (the fallback)', () {
    test('matches states', () {
      final r = CollegeSuggestionUtils.placeSuggestions('jamm');
      expect(
        r.first,
        const PlaceSuggestion('Jammu and Kashmir', SuggestionKind.state),
      );
    });

    test('matches both states and cities, best first', () {
      final r = CollegeSuggestionUtils.placeSuggestions('pun');
      expect(
        r,
        contains(const PlaceSuggestion('Punjab', SuggestionKind.state)),
      );
      expect(r, contains(const PlaceSuggestion('Pune', SuggestionKind.city)));
    });

    test('a place that is both a state and a city is listed once', () {
      final r = CollegeSuggestionUtils.placeSuggestions('delhi');
      expect(r.where((p) => p.label == 'Delhi'), hasLength(1));
    });

    test('with no state/city match it falls back to topics like "MBA"', () {
      final r = CollegeSuggestionUtils.placeSuggestions('mba');
      expect(r, isNotEmpty);
      expect(r.every((p) => p.kind == SuggestionKind.topic), isTrue);
      expect(r.map((p) => p.label), contains('MBA'));
    });

    test('nothing matches -> empty; blank query -> empty', () {
      expect(CollegeSuggestionUtils.placeSuggestions('qqqzzz'), isEmpty);
      expect(CollegeSuggestionUtils.placeSuggestions('  '), isEmpty);
    });
  });
}
