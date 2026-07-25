/// Parsed tokens from compound queries like "B.Tech Pune" or "Pune B.Tech".
class ParsedSearchQuery {
  final String? city;
  final String? course;
  final List<String> remainingTokens;

  const ParsedSearchQuery({
    this.city,
    this.course,
    this.remainingTokens = const [],
  });
}

/// Builds Firestore-friendly search fields for 40k+ college prefix lookup.
class CollegeSearchUtils {
  CollegeSearchUtils._();

  static const List<String> knownSearchCities = [
    'pune',
    'mumbai',
    'delhi',
    'new delhi',
    'bangalore',
    'bengaluru',
    'hyderabad',
    'chennai',
    'kolkata',
    'ahmedabad',
    'jaipur',
    'lucknow',
    'nagpur',
    'indore',
    'bhopal',
    'surat',
    'vadodara',
    'coimbatore',
    'kochi',
    'thiruvananthapuram',
    'visakhapatnam',
  ];

  static String normalizeName(String name) => name.trim().toLowerCase();

  static String normalizeCity(String city) => city.trim().toLowerCase();

  static String normalizeDistrict(String district) => district.trim().toLowerCase();

  static String normalizeState(String state) => state.trim().toLowerCase();

  static String titleCaseCity(String city) {
    if (city.trim().isEmpty) return city;
    return city
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String normalizeUniversity(String? university) =>
      (university ?? '').trim().toLowerCase();

  static String buildSlug(String name, String city) {
    final base = '${name.trim()}-${city.trim()}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return base.isEmpty ? 'college' : base;
  }

  /// Splits a raw query into searchable words (handles dots and punctuation).
  static List<String> extractSearchWords(String rawQuery) {
    return rawQuery
        .trim()
        .toLowerCase()
        .split(RegExp(r'[\s,]+'))
        .expand((part) => part.split(RegExp(r'[^a-z0-9.]+')))
        .map((word) => word.trim())
        .where((word) => word.length >= 2)
        .toList();
  }

  /// Detects city and course tokens from compound queries.
  static ParsedSearchQuery parseCompoundQuery(String? rawQuery) {
    final query = rawQuery?.trim().toLowerCase() ?? '';
    if (query.isEmpty) {
      return const ParsedSearchQuery();
    }

    String? city;
    for (final knownCity in knownSearchCities) {
      final pattern = RegExp(
        r'(^|[\s,.]+)' + RegExp.escape(knownCity) + r'($|[\s,.]+)',
      );
      if (pattern.hasMatch(' $query ')) {
        city = knownCity;
        break;
      }
    }

    String? course;
    final normalizedQuery = query.replaceAll(RegExp(r'\s+'), ' ');
    const coursePatterns = <String, String>{
      'b.tech': 'b.tech',
      'btech': 'b.tech',
      'b.e.': 'b.e.',
      'be': 'b.e.',
      'bba': 'bba',
      'bca': 'bca',
      'b.com': 'b.com',
      'bcom': 'b.com',
      'b.sc': 'b.sc',
      'bsc': 'b.sc',
      'mba': 'mba',
      'm.tech': 'm.tech',
      'mtech': 'm.tech',
      'mbbs': 'mbbs',
      'b.pharm': 'b.pharm',
      'bpharm': 'b.pharm',
      'ba': 'ba',
      'b.arch': 'b.arch',
      'barch': 'b.arch',
      'llb': 'llb',
      'bds': 'bds',
      'mca': 'mca',
    };

    for (final entry in coursePatterns.entries) {
      final pattern = RegExp(
        r'(^|[\s,.]+)' + RegExp.escape(entry.key) + r'($|[\s,.]+)',
      );
      if (pattern.hasMatch(' $normalizedQuery ')) {
        course = entry.value;
        break;
      }
    }

    final words = extractSearchWords(query);
    final remaining = words.where((word) {
      if (city != null && (word == city || city.contains(word))) return false;
      if (course != null) {
        final compact = word.replaceAll('.', '');
        final courseCompact = course.replaceAll('.', '');
        if (compact == courseCompact) return false;
      }
      return true;
    }).toList();

    return ParsedSearchQuery(
      city: city,
      course: course,
      remainingTokens: remaining,
    );
  }

  /// Tokenizes query words for array-contains-any Firestore lookup.
  static List<String> queryTokens(String query) {
    final tokens = <String>{};
    for (final word in query.toLowerCase().split(RegExp(r'\W+'))) {
      if (word.length < 2) continue;
      tokens.add(word);
      for (var len = 3; len <= word.length && len <= 12; len++) {
        tokens.add(word.substring(0, len));
      }
    }
    return tokens.take(10).toList();
  }

  /// Prefix tokens for optional array-contains-any fallback (max 30 stored).
  static List<String> buildSearchTokens({
    required String name,
    required String city,
    required String state,
    String district = '',
    String university = '',
    List<String> courses = const [],
    List<String> keywords = const [],
  }) {
    final tokens = <String>{};
    final corpus = [
      name,
      city,
      district,
      state,
      university,
      ...courses,
      ...keywords,
    ].join(' ').toLowerCase();

    for (final word in corpus.split(RegExp(r'\W+'))) {
      if (word.length < 2) continue;
      tokens.add(word);
      for (var len = 3; len <= word.length && len <= 12; len++) {
        tokens.add(word.substring(0, len));
      }
    }
    return tokens.take(30).toList();
  }

  /// Case-insensitive partial match across all searchable college fields.
  static bool matchesQuery(CollegeModelLike college, String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final haystack = [
      college.name,
      college.city,
      college.district,
      college.state,
      college.universityName ?? '',
      college.category,
      ...college.courses,
      ...college.searchKeywords,
    ].join(' ').toLowerCase();

    if (haystack.contains(query)) return true;

    final acronym = _buildAcronym(college.name);
    if (query.length >= 2 && acronym.contains(query)) return true;

    final words = query
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return true;

    if (words.every(haystack.contains)) return true;

    final significant = words.where((w) => w.length >= 2).toList();
    if (significant.isNotEmpty && significant.any(haystack.contains)) {
      return true;
    }

    final tokens = college.searchTokens;
    if (tokens.isNotEmpty) {
      for (final word in significant) {
        if (tokens.contains(word)) return true;
      }
    }

    return false;
  }

  static String _buildAcronym(String name) {
    final parts = name.split(RegExp(r'[\s\-]+'));
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part.isEmpty) continue;
      final ch = part[0].toLowerCase();
      if (RegExp(r'[a-z0-9]').hasMatch(ch)) buffer.write(ch);
    }
    return buffer.toString();
  }
}

/// Minimal interface for search matching without importing the full model.
abstract class CollegeModelLike {
  String get name;
  String get city;
  String get district;
  String get state;
  String? get universityName;
  String get category;
  List<String> get courses;
  List<String> get searchKeywords;
  List<String> get searchTokens;
}
