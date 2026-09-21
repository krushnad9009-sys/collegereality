import '../models/public_guide_profile.dart';

/// Search + ordering for the Guides directory: find guides by COLLEGE or
/// STREAM, and put the ones who can help right now first.
abstract final class GuideSearchMatcher {
  /// Course words (dots removed, so "B.Tech" is `btech`) that place a guide
  /// in a stream. A guide whose course is just "B.Tech" is still an
  /// "Engineering" guide for someone typing "engineering".
  static const Map<String, Set<String>> _streamWords = {
    'Engineering': {
      'engineering',
      'btech',
      'be',
      'mtech',
      'cse',
      'mechanical',
      'civil',
      'electrical',
      'electronics',
      'computer',
      'ece',
      'eee',
      'aerospace',
    },
    'Medical': {'medical', 'mbbs', 'bds', 'medicine', 'md', 'ayush', 'bams'},
    'MBA': {'mba', 'bba', 'management', 'pgdm'},
    'Law': {'law', 'llb', 'llm', 'legal'},
    'Pharmacy': {'pharmacy', 'pharma', 'bpharm', 'mpharm', 'dpharm'},
    'Arts': {'arts', 'ba', 'ma', 'humanities', 'psychology', 'journalism'},
    'Commerce': {'commerce', 'bcom', 'mcom', 'accounting', 'finance'},
    'Science': {'science', 'bsc', 'msc', 'physics', 'chemistry', 'maths'},
    'Nursing': {'nursing', 'gnm', 'anm'},
    'Architecture': {'architecture', 'barch'},
    'Agriculture': {'agriculture', 'agri'},
    'Polytechnic': {'polytechnic', 'diploma'},
  };

  /// Lower-case word tokens; dots vanish ("B.Tech" -> "btech") and every
  /// other punctuation run separates words.
  static List<String> tokens(String text) => text
      .toLowerCase()
      .replaceAll('.', '')
      .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
      .where((t) => t.isNotEmpty)
      .toList();

  /// The streams a course belongs to (possibly none, possibly several --
  /// "Computer Science" reads as both Engineering and Science).
  static Set<String> streamsOf(String? course) {
    if (course == null || course.trim().isEmpty) return const {};
    final words = tokens(course).toSet();
    return {
      for (final entry in _streamWords.entries)
        if (entry.value.any(words.contains)) entry.key,
    };
  }

  /// Whether [guide] matches [query]: EVERY typed word must start a word of
  /// the guide's college, course, stream or name. Blank query matches all.
  static bool matches(PublicGuideProfile guide, String query) {
    final wanted = tokens(query);
    if (wanted.isEmpty) return true;

    final haystack = <String>{
      ...tokens(guide.collegeName ?? ''),
      ...tokens(guide.course ?? ''),
      ...tokens(guide.displayName),
      for (final stream in streamsOf(guide.course)) ...tokens(stream),
    };
    return wanted.every((w) => haystack.any((h) => h.startsWith(w)));
  }

  static List<PublicGuideProfile> filter(
    Iterable<PublicGuideProfile> guides,
    String query,
  ) => [
    for (final guide in guides)
      if (matches(guide, query)) guide,
  ];

  /// Guides who can help right now first (online), then better rated, then
  /// by name so the order is stable.
  static List<PublicGuideProfile> sortByAvailability(
    Iterable<PublicGuideProfile> guides,
  ) {
    final sorted = [...guides];
    sorted.sort((a, b) {
      final onlineA = a.presence.isLiveOnline ? 1 : 0;
      final onlineB = b.presence.isLiveOnline ? 1 : 0;
      if (onlineA != onlineB) return onlineB.compareTo(onlineA);
      if (a.stats.overallRating != b.stats.overallRating) {
        return b.stats.overallRating.compareTo(a.stats.overallRating);
      }
      if (a.stats.totalRatings != b.stats.totalRatings) {
        return b.stats.totalRatings.compareTo(a.stats.totalRatings);
      }
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return sorted;
  }
}
