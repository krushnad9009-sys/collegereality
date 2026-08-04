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
    'beed',
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

  /// Trim, lowercase, and collapse internal whitespace for exact duplicate keys.
  static String normalizeName(String name) => _normalizeExact(name);

  static String normalizeCity(String city) => _normalizeExact(city);

  /// Keys used for city matching (handles Bangalore/Bengaluru and similar).
  static Set<String> citySearchKeys(String city) {
    final normalized = normalizeCity(city);
    if (normalized == 'bangalore' || normalized == 'bengaluru') {
      return const {'bangalore', 'bengaluru'};
    }
    if (normalized == 'bombay' || normalized == 'mumbai') {
      return const {'mumbai', 'bombay'};
    }
    if (normalized == 'madras' || normalized == 'chennai') {
      return const {'chennai', 'madras'};
    }
    if (normalized == 'calcutta' || normalized == 'kolkata') {
      return const {'kolkata', 'calcutta'};
    }
    if (normalized == 'poona' || normalized == 'pune') {
      return const {'pune', 'poona'};
    }
    if (normalized == 'delhi' || normalized == 'new delhi') {
      return const {'delhi', 'new delhi'};
    }
    if (normalized == 'gurgaon' || normalized == 'gurugram') {
      return const {'gurgaon', 'gurugram'};
    }
    if (normalized.isEmpty) return const {};
    return {normalized};
  }

  /// True when alias cities are not covered by a single Firestore prefix range.
  static bool cityNeedsAliasMerge(String city) {
    final normalized = normalizeCity(city);
    final keys = citySearchKeys(city);
    if (keys.length <= 1) return false;
    return keys.any(
      (key) =>
          key != normalized &&
          !key.startsWith(normalized) &&
          !normalized.startsWith(key),
    );
  }

  static bool cityMatchesCollege({
    required String cityLower,
    required String districtLower,
    required String cityFilter,
  }) {
    final keys = citySearchKeys(cityFilter);
    if (keys.isEmpty) return true;
    return keys.any(
      (key) => cityLower.contains(key) || districtLower.contains(key),
    );
  }

  static String normalizeDistrict(String district) => _normalizeExact(district);

  /// Canonicalizes common misspellings so filters match seed/import data.
  static const Map<String, String> stateAliases = {
    'chhatisgarh': 'chhattisgarh',
    'chhattisgarh': 'chhattisgarh',
    'uttrakhand': 'uttarakhand',
    'uttarakhand': 'uttarakhand',
    'orissa': 'odisha',
    'pondicherry': 'puducherry',
    'nct of delhi': 'delhi',
    'delhi nct': 'delhi',
  };

  static String normalizeState(String state) {
    final normalized = _normalizeExact(state);
    return stateAliases[normalized] ?? normalized;
  }

  static String _normalizeExact(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

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
      _normalizeExact(university ?? '');

  /// Course equality tolerant of dots/spaces/case (B.Tech ≈ BTech ≈ b.tech).
  static String normalizeCourseKey(String course) =>
      course.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static bool courseMatches(List<String> courses, String? courseFilter) {
    if (courseFilter == null || courseFilter.trim().isEmpty) return true;
    final needle = normalizeCourseKey(courseFilter);
    if (needle.isEmpty) return true;
    return courses.any((c) {
      final key = normalizeCourseKey(c);
      if (key == needle) return true;
      // Short needles (BA) must not substring-match longer courses (MBA/BBA).
      if (needle.length <= 2 || key.length <= 2) return false;
      if (needle.length <= 3) {
        return key.startsWith(needle) || needle.startsWith(key);
      }
      return key.contains(needle) || needle.contains(key);
    });
  }

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

    final parsed = parseCompoundQuery(query);
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

    if (!_matchesParsedCourse(college, parsed.course)) return false;
    if (!_matchesParsedCity(college, parsed.city)) return false;

    final significant = parsed.remainingTokens.where((w) => w.length >= 2).toList();
    if (significant.isEmpty) {
      return parsed.city != null || parsed.course != null;
    }

    if (significant.every((word) => _containsToken(haystack, word))) return true;

    final tokens = college.searchTokens;
    if (tokens.isNotEmpty) {
      if (significant.every((word) => tokens.any((token) => token.startsWith(word)))) {
        return true;
      }
    }

    return false;
  }

  static bool _matchesParsedCourse(CollegeModelLike college, String? course) {
    if (course == null || course.isEmpty) return true;
    final normalizedCourse = course.replaceAll('.', '').toLowerCase();
    return college.courses.any(
          (c) => c.replaceAll('.', '').toLowerCase().contains(normalizedCourse),
        ) ||
        college.category.toLowerCase().contains(normalizedCourse);
  }

  static bool _matchesParsedCity(CollegeModelLike college, String? city) {
    if (city == null || city.isEmpty) return true;
    final normalizedCity = normalizeCity(city);
    return normalizeCity(college.city).contains(normalizedCity) ||
        normalizeDistrict(college.district).contains(normalizedCity);
  }

  static bool _containsToken(String haystack, String token) {
    if (haystack.contains(token)) return true;
    return haystack
        .split(RegExp(r'[\s,()/-]+'))
        .where((part) => part.isNotEmpty)
        .any((part) => part.startsWith(token));
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
