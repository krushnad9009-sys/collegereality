import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/utils/college_search_utils.dart';
import 'package:college_reality_india/features/colleges/utils/college_suggestion_utils.dart';

CollegeModel _college({
  required String id,
  required String name,
  required String city,
  required String state,
  required List<String> courses,
  String? university,
  String type = 'private',
  String category = 'General',
}) {
  return CollegeModel.createDraft(id: id).copyWith(
    name: name,
    nameLower: name.toLowerCase(),
    slug: CollegeSearchUtils.buildSlug(name, city),
    city: city,
    state: state,
    address: '$city, $state',
    courses: courses,
    universityName: university,
    type: type,
    category: category,
    searchKeywords: [city, state, ...courses],
    searchTokens: CollegeSearchUtils.buildSearchTokens(
      name: name,
      city: city,
      state: state,
      university: university ?? '',
      courses: courses,
      keywords: [city, state],
    ),
  );
}

void main() {
  group('CollegeSuggestionUtils', () {
    test('city suggestions match prefixes', () {
      expect(CollegeSuggestionUtils.citySuggestions('Bee'), contains('Beed'));
      expect(CollegeSuggestionUtils.citySuggestions('Pun'), contains('Pune'));
    });

    test('university suggestions match prefixes', () {
      expect(
        CollegeSuggestionUtils.universitySuggestions('Vasan'),
        contains('Vasantrao Naik Marathwada Krishi Vidyapeeth'),
      );
    });

    test('search suggestions include popular quick terms', () {
      final suggestions = CollegeSuggestionUtils.searchSuggestions('Comp');
      expect(suggestions, contains('Computer Science'));
    });
  });

  group('CollegeSearchUtils.matchesQuery', () {
    final bangaloreMbaCollege = _college(
      id: '1',
      name: 'Alliance School of Business',
      city: 'Bangalore',
      state: 'Karnataka',
      courses: const ['MBA', 'BBA'],
      university: 'Bangalore University',
      category: 'MBA',
    );

    final punjabCollege = _college(
      id: '2',
      name: 'Punjab Engineering College',
      city: 'Chandigarh',
      state: 'Punjab',
      courses: const ['B.Tech'],
      university: 'Punjab University',
      category: 'Engineering',
    );

    test('requires both location and course for compound query', () {
      expect(
        CollegeSearchUtils.matchesQuery(bangaloreMbaCollege, 'MBA Bangalore'),
        isTrue,
      );
      expect(
        CollegeSearchUtils.matchesQuery(punjabCollege, 'MBA Bangalore'),
        isFalse,
      );
    });

    test('matches city-only and university-only searches', () {
      expect(
        CollegeSearchUtils.matchesQuery(bangaloreMbaCollege, 'Bangalore'),
        isTrue,
      );
      expect(
        CollegeSearchUtils.matchesQuery(
          bangaloreMbaCollege,
          'Bangalore University',
        ),
        isTrue,
      );
    });
  });
}
