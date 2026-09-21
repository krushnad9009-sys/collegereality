import '../../../core/constants/college_constants.dart';

/// What a non-college dropdown row stands for.
enum SuggestionKind { state, city, topic }

/// A fallback suggestion: a state or city (or, last resort, a course /
/// stream / university topic) that matches what the user typed.
class PlaceSuggestion {
  final String label;
  final SuggestionKind kind;

  const PlaceSuggestion(this.label, this.kind);

  @override
  bool operator ==(Object other) =>
      other is PlaceSuggestion && other.label == label && other.kind == kind;

  @override
  int get hashCode => Object.hash(label, kind);

  @override
  String toString() => 'PlaceSuggestion($label, ${kind.name})';
}

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

  /// The fallback shown ONLY when no college name matches the query: matching
  /// states and cities, best match first. If neither matches, it falls back to
  /// the broader topic list (courses, streams, universities) so typing e.g.
  /// "mba" still suggests something.
  static List<PlaceSuggestion> placeSuggestions(String query, {int limit = 6}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final normalizedQuery = _normalize(trimmed);

    final scored = <({PlaceSuggestion suggestion, int score})>[];
    final seen = <String>{};
    void collect(Iterable<String> values, SuggestionKind kind) {
      for (final raw in values) {
        final value = raw.trim();
        if (value.isEmpty) continue;
        final normalized = _normalize(value);
        // A name that is both a state and a city (Delhi) is listed once.
        if (!seen.add(normalized)) continue;
        final score = _score(normalizedQuery, normalized);
        // Only names that START with the text (or a word of them does): a
        // stray substring ("mba" inside "Mumbai") is not a useful suggestion.
        if (score >= _wordStartScore) {
          scored.add((suggestion: PlaceSuggestion(value, kind), score: score));
        }
      }
    }

    collect(CollegeConstants.indianStates, SuggestionKind.state);
    collect(popularCities, SuggestionKind.city);

    scored.sort((a, b) {
      if (a.score != b.score) return b.score.compareTo(a.score);
      return a.suggestion.label.toLowerCase().compareTo(
        b.suggestion.label.toLowerCase(),
      );
    });

    if (scored.isNotEmpty) {
      return scored.take(limit).map((e) => e.suggestion).toList();
    }
    return searchSuggestions(trimmed)
        .take(limit)
        .map((label) => PlaceSuggestion(label, SuggestionKind.topic))
        .toList();
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

  /// `_score` of "some word of the value starts with the query" -- the
  /// weakest match still considered a real place suggestion.
  static const int _wordStartScore = 750;

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
