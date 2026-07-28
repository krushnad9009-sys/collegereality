import '../../../core/constants/college_constants.dart';

class CollegeSuggestionUtils {
  CollegeSuggestionUtils._();

  static const List<String> popularCities = [
    'Bangalore',
    'Beed',
    'Chennai',
    'Delhi',
    'Hyderabad',
    'Mumbai',
    'Nagpur',
    'Nashik',
    'Pune',
    'Thane',
  ];

  static const List<String> popularUniversities = [
    'University of Mumbai',
    'Savitribai Phule Pune University',
    'Dr. Babasaheb Ambedkar Marathwada University',
    'Vasantrao Naik Marathwada Krishi Vidyapeeth',
    'Rashtrasant Tukadoji Maharaj Nagpur University',
    'Shivaji University',
    'University of Delhi',
    'Visvesvaraya Technological University',
    'Bangalore University',
    'University of Calcutta',
  ];

  static const List<String> popularSearchSuggestions = [
    'MBA',
    'Engineering',
    'Medical',
    'Food Technology',
    'Computer Science',
    'Bangalore',
    'Pune',
    'Mumbai',
    'Delhi',
    'Beed',
  ];

  static List<String> stateSuggestions(String query) {
    return filterSuggestions(query, CollegeConstants.indianStates);
  }

  static List<String> citySuggestions(String query) {
    return filterSuggestions(query, popularCities);
  }

  static List<String> universitySuggestions(String query) {
    return filterSuggestions(query, popularUniversities, limit: 8);
  }

  static List<String> courseSuggestions(String query) {
    return filterSuggestions(query, CollegeConstants.popularCourses);
  }

  static List<String> typeSuggestions(String query) {
    final normalized = CollegeConstants.collegeTypes
        .map(_titleCaseWords)
        .toList(growable: false);
    return filterSuggestions(query, normalized);
  }

  static List<String> searchSuggestions(String query) {
    final corpus = <String>[
      ...popularSearchSuggestions,
      ...CollegeConstants.popularCourses,
      ...popularCities,
      ...CollegeConstants.indianStates,
      ...popularUniversities,
    ];
    return filterSuggestions(query, corpus, limit: 10);
  }

  static List<String> filterSuggestions(
    String query,
    List<String> values, {
    int limit = 6,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return _dedupe(values).take(limit).toList();
    }

    final normalizedQuery = _normalize(trimmed);
    final scored = <({String value, int score})>[];

    for (final rawValue in _dedupe(values)) {
      final value = rawValue.trim();
      if (value.isEmpty) continue;
      final normalizedValue = _normalize(value);
      final score = _score(normalizedQuery, normalizedValue);
      if (score > 0) {
        scored.add((value: value, score: score));
      }
    }

    scored.sort((a, b) {
      if (a.score != b.score) return b.score.compareTo(a.score);
      return a.value.toLowerCase().compareTo(b.value.toLowerCase());
    });

    return scored.take(limit).map((item) => item.value).toList();
  }

  static Iterable<String> _dedupe(List<String> values) sync* {
    final seen = <String>{};
    for (final value in values) {
      final normalized = _normalize(value);
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      yield value.trim();
    }
  }

  static int _score(String query, String value) {
    if (value == query) return 1000;
    if (value.startsWith(query)) return 900;

    final words = value.split(' ');
    if (words.any((word) => word.startsWith(query))) return 750;
    if (value.contains(query)) return 600;

    final compactValue = value.replaceAll(' ', '');
    final compactQuery = query.replaceAll(' ', '');
    if (compactValue.startsWith(compactQuery)) return 500;
    if (compactValue.contains(compactQuery)) return 400;

    return 0;
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String _titleCaseWords(String value) {
    return value
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }
}
