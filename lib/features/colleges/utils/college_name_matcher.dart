import '../models/college_model.dart';

/// Name-first matching for the search suggestion dropdown.
///
/// Unlike `CollegeSearchUtils.matchesQuery` (which matches a query against
/// name, city, district, state, university, courses and keywords all at once)
/// this looks at the college NAME only. That is the point: typing "ja" must
/// surface "Jawaharlal Nehru Engineering College" -- not every college that
/// merely sits in Jaipur or Jammu.
///
/// Pure and synchronous, so it is used both to pick candidates from the
/// database and to re-rank/narrow an already-fetched list on every keystroke.
abstract final class CollegeNameMatcher {
  // Scores, best first. Only their ORDER matters.
  static const int _exact = 1000;
  static const int _prefix = 900;
  static const int _wordPrefixes = 700;
  static const int _phraseAtWord = 650;
  static const int _initials = 600;
  static const int _midWord = 300;

  /// A mid-word hit ("ja" inside "Rajaram") is noise at one or two letters;
  /// only allow it once the query is specific enough.
  static const int _minMidWordChars = 3;

  static final RegExp _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
  static final RegExp _apostrophes = RegExp(r"['’`]");

  /// Lower-cases, drops apostrophes ("Xavier's" -> "xaviers") and turns every
  /// other punctuation run into a single space ("St. Xavier's" ->
  /// "st xaviers").
  static String normalize(String value) => value
      .toLowerCase()
      .replaceAll(_apostrophes, '')
      .replaceAll(_separators, ' ')
      .trim();

  /// How well [name] matches [query] (both raw); 0 means "not a name match".
  static int score(String query, String name) {
    final q = normalize(query);
    final n = normalize(name);
    if (q.isEmpty || n.isEmpty) return 0;

    if (n == q) return _exact;
    if (n.startsWith(q)) return _prefix;

    final nameWords = n.split(' ');
    final queryWords = q.split(' ');

    // Every typed word starts some word of the name, in any order:
    // "nehru eng" / "engineering jawaharlal" -> Jawaharlal Nehru Engineering.
    if (queryWords.every((qw) => nameWords.any((nw) => nw.startsWith(qw)))) {
      // Earlier matches read as a better hit (the name "starts with" the idea).
      final firstHit = nameWords.indexWhere((nw) => nw.startsWith(queryWords[0]));
      return _wordPrefixes - (firstHit < 0 ? 0 : firstHit.clamp(0, 50));
    }

    // The typed text as a phrase beginning at a word boundary.
    if (n.contains(' $q')) return _phraseAtWord;

    // "iit", "jnec": the initials of the name.
    if (q.length >= 2 && !q.contains(' ') && _initialsOf(nameWords).startsWith(q)) {
      return _initials;
    }

    if (q.length >= _minMidWordChars && n.contains(q)) return _midWord;
    return 0;
  }

  /// Filler words that don't count towards a name's initials, so "Indian
  /// Institute of Technology" is "iit" (not "iiot").
  static const Set<String> _fillerWords = {'of', 'and', 'for', 'the', 'in', 'at'};

  static String _initialsOf(List<String> words) => words
      .where((w) => w.isNotEmpty && !_fillerWords.contains(w))
      .map((w) => w[0])
      .join();

  static bool matches(String query, CollegeModel college) =>
      score(query, college.name) > 0;

  /// Colleges whose NAME matches [query], best match first, at most [limit].
  ///
  /// Ties break on where the match sits in the name, then shorter names, then
  /// alphabetically, so the list is stable between keystrokes.
  static List<CollegeModel> rank(
    String query,
    Iterable<CollegeModel> colleges, {
    int limit = 8,
  }) {
    final q = normalize(query);
    if (q.isEmpty) return const [];

    final scored = <({CollegeModel college, int score, int at, String key})>[];
    final seen = <String>{};
    for (final college in colleges) {
      if (!seen.add(college.id)) continue;
      final s = score(query, college.name);
      if (s <= 0) continue;
      final key = normalize(college.name);
      scored.add((college: college, score: s, at: key.indexOf(q), key: key));
    }

    scored.sort((a, b) {
      if (a.score != b.score) return b.score.compareTo(a.score);
      // -1 (no literal substring, e.g. acronym / any-order) sorts last.
      final atA = a.at < 0 ? 1 << 20 : a.at;
      final atB = b.at < 0 ? 1 << 20 : b.at;
      if (atA != atB) return atA.compareTo(atB);
      if (a.key.length != b.key.length) {
        return a.key.length.compareTo(b.key.length);
      }
      return a.key.compareTo(b.key);
    });

    return scored.take(limit).map((e) => e.college).toList(growable: false);
  }

  /// The muted second line under a college name: "City, State" (either part
  /// may be missing; falls back to the district when there is no city).
  static String locationLabel(CollegeModel college) {
    final place = college.city.trim().isNotEmpty
        ? college.city.trim()
        : college.district.trim();
    return [place, college.state.trim()].where((p) => p.isNotEmpty).join(', ');
  }
}
