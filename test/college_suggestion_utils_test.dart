import 'package:college_reality_india/features/colleges/utils/college_suggestion_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CollegeSuggestionUtils.filterSuggestions', () {
    test('returns first N items for empty query', () {
      final results = CollegeSuggestionUtils.filterSuggestions('', ['Pune', 'Mumbai', 'Delhi']);
      expect(results.length, 3);
      expect(results.first, 'Pune');
    });

    test('prioritizes exact match', () {
      final results = CollegeSuggestionUtils.filterSuggestions(
        'pune',
        ['Mumbai', 'Pune', 'Pune University'],
      );
      expect(results.first, 'Pune');
    });

    test('matches prefix and contains', () {
      final results = CollegeSuggestionUtils.filterSuggestions(
        'eng',
        ['MBA', 'Engineering', 'Medical'],
      );
      expect(results, contains('Engineering'));
      expect(results, isNot(contains('MBA')));
    });

    test('deduplicates case-insensitive values', () {
      final results = CollegeSuggestionUtils.filterSuggestions(
        '',
        ['Pune', 'PUNE', 'pune', 'Mumbai'],
        limit: 10,
      );
      expect(results.where((v) => v.toLowerCase() == 'pune').length, 1);
    });

    test('respects limit parameter', () {
      final results = CollegeSuggestionUtils.filterSuggestions(
        '',
        List.generate(20, (i) => 'City $i'),
        limit: 4,
      );
      expect(results.length, 4);
    });

    test('word prefix match ranks higher than contains', () {
      final results = CollegeSuggestionUtils.filterSuggestions(
        'pun',
        ['Mumbai', 'Pune', 'Pune University Campus'],
      );
      expect(results.first, 'Pune');
    });
  });

  group('CollegeSuggestionUtils typed suggestions', () {
    test('stateSuggestions filters Indian states', () {
      final results = CollegeSuggestionUtils.stateSuggestions('maha');
      expect(results, isNotEmpty);
      expect(results.first.toLowerCase(), contains('maha'));
    });

    test('citySuggestions filters popular cities', () {
      final results = CollegeSuggestionUtils.citySuggestions('pun');
      expect(results, contains('Pune'));
    });

    test('universitySuggestions limits to 8', () {
      final results = CollegeSuggestionUtils.universitySuggestions('');
      expect(results.length, lessThanOrEqualTo(8));
      expect(results, isNotEmpty);
    });

    test('courseSuggestions filters popular courses', () {
      final results = CollegeSuggestionUtils.courseSuggestions('mba');
      expect(results.any((c) => c.toLowerCase().contains('mba')), isTrue);
    });

    test('typeSuggestions title-cases college types', () {
      final results = CollegeSuggestionUtils.typeSuggestions('gov');
      expect(results, isNotEmpty);
      expect(results.first[0], results.first[0].toUpperCase());
    });

    test('searchSuggestions merges corpus with limit 10', () {
      final results = CollegeSuggestionUtils.searchSuggestions('');
      expect(results.length, lessThanOrEqualTo(10));
      expect(results, isNotEmpty);
    });

    test('searchSuggestions finds MBA in merged corpus', () {
      final results = CollegeSuggestionUtils.searchSuggestions('mba');
      expect(results.any((s) => s.toLowerCase().contains('mba')), isTrue);
    });
  });
}
