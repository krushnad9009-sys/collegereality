/// Builds Firestore-friendly search fields for 40k+ college prefix lookup.
class CollegeSearchUtils {
  CollegeSearchUtils._();

  static String normalizeName(String name) => name.trim().toLowerCase();

  static String buildSlug(String name, String city) {
    final base = '${name.trim()}-${city.trim()}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return base.isEmpty ? 'college' : base;
  }

  /// Prefix tokens for optional array-contains-any fallback (max 10 used in query).
  static List<String> buildSearchTokens({
    required String name,
    required String city,
    required String state,
    List<String> courses = const [],
  }) {
    final tokens = <String>{};
    final corpus = [
      name,
      city,
      state,
      ...courses,
    ].join(' ').toLowerCase();

    for (final word in corpus.split(RegExp(r'\W+'))) {
      if (word.length < 2) continue;
      tokens.add(word);
      for (var len = 3; len <= word.length && len <= 10; len++) {
        tokens.add(word.substring(0, len));
      }
    }
    return tokens.take(30).toList();
  }
}
