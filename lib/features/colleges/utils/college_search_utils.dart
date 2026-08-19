/// Parsed tokens from compound queries like "B.Tech Pune" or
/// "Engineering Maharashtra".
class ParsedSearchQuery {
  final String? city;
  final String? course;

  /// A recognized college-category label (e.g. "Engineering") found as a
  /// distinct segment of the query — not necessarily the whole query.
  final String? category;

  /// A recognized Indian state label (e.g. "Maharashtra") found as a
  /// distinct segment of the query — not necessarily the whole query.
  final String? state;

  final List<String> remainingTokens;

  const ParsedSearchQuery({
    this.city,
    this.course,
    this.category,
    this.state,
    this.remainingTokens = const [],
  });
}

/// Normalized search inputs after promoting free-text into structured filters.
class ResolvedSearchIntent {
  /// Free-text still used for name/token/university multi-field retrieval.
  final String? retrievalQuery;

  /// Original user text for ranking (may equal [retrievalQuery] or full input).
  final String? rankingQuery;

  final String? state;
  final String? city;
  final String? university;
  final String? course;
  final String? category;
  final String? type;

  const ResolvedSearchIntent({
    this.retrievalQuery,
    this.rankingQuery,
    this.state,
    this.city,
    this.university,
    this.course,
    this.category,
    this.type,
  });

  bool get hasCity => city != null && city!.trim().isNotEmpty;
  bool get hasRetrievalQuery =>
      retrievalQuery != null && retrievalQuery!.trim().isNotEmpty;
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

    // Category and state can each appear as their own segment of a compound
    // query (e.g. "Engineering Maharashtra") even though neither matches the
    // whole query string — detect them the same way city/course are above.
    String? category;
    for (final label in _categoryLabels) {
      final pattern = RegExp(
        r'(^|[\s,.]+)' + RegExp.escape(label.toLowerCase()) + r'($|[\s,.]+)',
      );
      if (pattern.hasMatch(' $query ')) {
        category = label;
        break;
      }
    }

    String? state;
    for (final label in _stateLabels) {
      final pattern = RegExp(
        r'(^|[\s,.]+)' + RegExp.escape(label.toLowerCase()) + r'($|[\s,.]+)',
      );
      if (pattern.hasMatch(' $query ')) {
        state = label;
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
      if (category != null &&
          category.toLowerCase().split(RegExp(r'\s+')).contains(word)) {
        return false;
      }
      if (state != null &&
          state.toLowerCase().split(RegExp(r'\s+')).contains(word)) {
        return false;
      }
      return true;
    }).toList();

    return ParsedSearchQuery(
      city: city,
      course: course,
      category: category,
      state: state,
      remainingTokens: remaining,
    );
  }

  /// Promotes free-text into city/course/category/state while keeping explicit filters.
  static ResolvedSearchIntent resolveSearchIntent({
    String? query,
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
    String? ownership,
  }) {
    final trimmed = query?.trim() ?? '';
    final parsed = parseCompoundQuery(trimmed.isEmpty ? null : trimmed);

    final effectiveCity = _firstNonEmpty(city) ??
        (parsed.city == null ? null : titleCaseCity(parsed.city!));
    final effectiveCourse =
        _firstNonEmpty(course) ?? _canonicalizeParsedCourse(parsed.course);
    final effectiveUniversity = _firstNonEmpty(university);

    var effectiveState = _firstNonEmpty(state);
    var effectiveCategory = _firstNonEmpty(category);
    // Ownership is empty in production DB — map to `type` (government/private/...).
    final effectiveType = _firstNonEmpty(type) ??
        _ownershipToType(_firstNonEmpty(ownership));

    // Whole-query exact match first (e.g. query is just "Engineering"),
    // then per-segment detection (e.g. "Engineering Maharashtra") — this is
    // the fix for compound category+state (or any mix of city/course/
    // category/state) queries returning 0 results: without this, a
    // two-field query like "Engineering Maharashtra" never gets promoted to
    // structured Firestore filters and falls into the free-text token path,
    // whose retrieval window is too small to reliably contain a match for
    // more than one criterion at once.
    if (effectiveCategory == null && trimmed.isNotEmpty) {
      effectiveCategory = matchCategoryLabel(trimmed) ?? parsed.category;
    }
    if (effectiveState == null && trimmed.isNotEmpty) {
      effectiveState = matchStateLabel(trimmed) ?? parsed.state;
    }

    String? retrievalQuery = trimmed.isEmpty ? null : trimmed;

    // Whether each parsed segment was cleanly promoted into a structured
    // filter (i.e. not already independently set by an explicit filter
    // field, which would mean the query text's copy of it is redundant but
    // not necessarily exhaustive).
    final consumedByCity = parsed.city != null && _firstNonEmpty(city) == null;
    final consumedByCourse =
        parsed.course != null && _firstNonEmpty(course) == null;
    final consumedByCategory =
        parsed.category != null && _firstNonEmpty(category) == null;
    final consumedByState = parsed.state != null && _firstNonEmpty(state) == null;

    // True once every recognizable segment of the query text has been
    // promoted to a structured filter and nothing free-text-worthy remains
    // — a free-text retrieval pass at that point would be redundant.
    final fullyConsumed = (consumedByCity ||
            consumedByCourse ||
            consumedByCategory ||
            consumedByState) &&
        parsed.remainingTokens.isEmpty &&
        (parsed.city == null || consumedByCity) &&
        (parsed.course == null || consumedByCourse) &&
        (parsed.category == null || consumedByCategory) &&
        (parsed.state == null || consumedByState);

    if (fullyConsumed) {
      retrievalQuery = null;
    }

    return ResolvedSearchIntent(
      retrievalQuery: retrievalQuery,
      rankingQuery: trimmed.isEmpty ? null : trimmed,
      state: effectiveState,
      city: effectiveCity,
      university: effectiveUniversity,
      course: effectiveCourse,
      category: effectiveCategory,
      type: effectiveType,
    );
  }

  static String? _ownershipToType(String? ownership) {
    if (ownership == null || ownership.isEmpty) return null;
    final key = ownership.trim().toLowerCase();
    const map = {
      'government': 'government',
      'govt': 'government',
      'gov': 'government',
      'public': 'government',
      'private': 'private',
      'deemed': 'deemed',
      'autonomous': 'autonomous',
    };
    return map[key] ?? key;
  }

  static const List<String> _categoryLabels = [
    'Engineering',
    'Medical',
    'MBA',
    'Law',
    'Pharmacy',
    'Arts',
    'Commerce',
    'Science',
    'General',
    'Polytechnic',
    'Nursing',
    'Agriculture',
    'Architecture',
    'Fashion',
  ];

  static const List<String> _stateLabels = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  static String? matchCategoryLabel(String raw) {
    final needle = normalizeName(raw);
    if (needle.isEmpty) return null;
    for (final category in _categoryLabels) {
      if (normalizeName(category) == needle) return category;
    }
    return null;
  }

  static String? matchStateLabel(String raw) {
    final needle = normalizeState(raw);
    if (needle.isEmpty) return null;
    for (final state in _stateLabels) {
      if (normalizeState(state) == needle) return state;
    }
    return null;
  }

  static String? _canonicalizeParsedCourse(String? parsed) {
    if (parsed == null || parsed.isEmpty) return null;
    const map = <String, String>{
      'b.tech': 'B.Tech',
      'b.e.': 'B.E.',
      'bba': 'BBA',
      'bca': 'BCA',
      'b.com': 'B.Com',
      'b.sc': 'B.Sc',
      'mba': 'MBA',
      'm.tech': 'M.Tech',
      'mbbs': 'MBBS',
      'b.pharm': 'B.Pharm',
      'ba': 'BA',
      'b.arch': 'B.Arch',
      'llb': 'LLB',
      'bds': 'BDS',
      'mca': 'MCA',
    };
    return map[parsed.toLowerCase()] ?? parsed;
  }

  static String? _firstNonEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Single client-side filter path used by Firestore + bundled search.
  static List<T> applyFilters<T extends CollegeModelLike>(
    List<T> colleges, {
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
    String? query,
  }) {
    var results = colleges;
    if (state != null && state.isNotEmpty) {
      final normalizedState = normalizeState(state);
      results = results
          .where((c) => normalizeState(c.state) == normalizedState)
          .toList();
    }
    if (city != null && city.isNotEmpty) {
      results = results
          .where(
            (c) => cityMatchesCollege(
              cityLower: c.cityLower.isNotEmpty
                  ? normalizeCity(c.cityLower)
                  : normalizeCity(c.city),
              districtLower: normalizeDistrict(c.district),
              cityFilter: city,
            ),
          )
          .toList();
    }
    if (university != null && university.isNotEmpty) {
      final normalizedUniversity = normalizeUniversity(university);
      results = results.where((c) {
        final uni = normalizeUniversity(c.universityName);
        if (uni.contains(normalizedUniversity)) return true;
        // Production data often lacks universityName — fall back to tokens/name.
        if (c.searchTokens.any(
          (t) =>
              t.contains(normalizedUniversity) ||
              normalizedUniversity.contains(t),
        )) {
          return true;
        }
        return matchesQuery(c, university);
      }).toList();
    }
    if (course != null && course.isNotEmpty) {
      results =
          results.where((c) => courseMatches(c.courses, course)).toList();
    }
    if (category != null && category.isNotEmpty) {
      final categoryLower = category.toLowerCase();
      results = results
          .where((c) => c.category.toLowerCase() == categoryLower)
          .toList();
    }
    if (type != null && type.isNotEmpty) {
      final typeLower = type.toLowerCase();
      results = results.where((c) {
        if (c.type.toLowerCase() == typeLower) return true;
        // ownership field is empty in production; keep type-compatible match.
        return false;
      }).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      results =
          results.where((c) => matchesQuery(c, query.trim())).toList();
    }
    return results;
  }

  /// Tokenizes query words for array-contains-any Firestore lookup.
  ///
  /// Allocates the 10-token budget round-robin across query words instead
  /// of filling it sequentially word-by-word — a single long word (e.g.
  /// "engineering", which alone generates 9 prefix tokens) would otherwise
  /// consume nearly the whole budget and crowd out every other word in a
  /// compound query (e.g. "maharashtra" in "engineering maharashtra"),
  /// leaving Firestore's arrayContainsAny retrieval with almost nothing to
  /// match the second term against.
  static List<String> queryTokens(String query) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((word) => word.length >= 2)
        .toList();
    if (words.isEmpty) return const [];

    final perWordTokens = words.map((word) {
      final list = <String>[word];
      for (var len = 3; len <= word.length && len <= 12; len++) {
        list.add(word.substring(0, len));
      }
      return list;
    }).toList();

    final tokens = <String>{};
    var round = 0;
    while (tokens.length < 10 &&
        perWordTokens.any((list) => round < list.length)) {
      for (final list in perWordTokens) {
        if (round < list.length) tokens.add(list[round]);
        if (tokens.length >= 10) break;
      }
      round++;
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
    return cityMatchesCollege(
      cityLower: college.cityLower.isNotEmpty
          ? normalizeCity(college.cityLower)
          : normalizeCity(college.city),
      districtLower: normalizeDistrict(college.district),
      cityFilter: city,
    );
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
  String get cityLower;
  String get district;
  String get state;
  String? get universityName;
  String get category;
  String get type;
  List<String> get courses;
  List<String> get searchKeywords;
  List<String> get searchTokens;
}
