import '../models/college_model.dart';
import 'college_search_utils.dart';

/// Ranks search results: exact city first, then nearby, then partial matches.
class CollegeSearchRanker {
  CollegeSearchRanker._();

  /// Higher score = better match.
  static int cityMatchScore(CollegeModel college, String? cityQuery) {
    if (cityQuery == null || cityQuery.trim().isEmpty) return 0;

    final q = CollegeSearchUtils.normalizeCity(cityQuery);
    if (q.isEmpty) return 0;

    final city = college.cityLower;
    final district = college.districtLower;
    final state = college.stateLower;

    if (city == q) return 1000;
    if (district == q) return 950;
    if (city.startsWith(q) || q.startsWith(city)) return 850;
    if (district.startsWith(q) || q.startsWith(district)) return 800;
    if (city.contains(q) || q.contains(city)) return 700;
    if (district.contains(q)) return 650;
    if (state.contains(q)) return 400;
    return 0;
  }

  static int queryMatchScore(CollegeModel college, String? query) {
    final q = query?.trim().toLowerCase() ?? '';
    if (q.isEmpty) return 0;

    final parsed = CollegeSearchUtils.parseCompoundQuery(q);
    var score = 0;

    if (parsed.course != null &&
        college.courses.any(
          (c) => c.toLowerCase().contains(parsed.course!.toLowerCase()),
        )) {
      score += 220;
    }

    for (final token in parsed.remainingTokens) {
      score += _tokenMatchScore(college, token);
    }

    if (score > 0) return score;

    if (college.nameLower == q) return 500;
    if (college.nameLower.startsWith(q)) return 450;
    if (college.nameLower.contains(q)) return 400;
    if (college.universityName != null &&
        CollegeSearchUtils.normalizeUniversity(college.universityName)
            .contains(q)) {
      return 350;
    }
    if (college.cityLower.contains(q)) return 300;
    if (college.stateLower.contains(q)) return 250;
    if (college.courses.any((c) => c.toLowerCase().contains(q))) return 200;
    if (college.category.toLowerCase().contains(q)) return 180;
    if (college.searchKeywords.any((k) => k.toLowerCase().contains(q))) {
      return 150;
    }
    return 0;
  }

  static int _tokenMatchScore(CollegeModel college, String token) {
    if (token.isEmpty) return 0;
    if (college.nameLower == token) return 500;
    if (college.nameLower.startsWith(token)) return 450;
    if (college.nameLower.contains(token)) return 400;
    if (college.cityLower.contains(token)) return 300;
    if (college.stateLower.contains(token)) return 250;
    if (college.courses.any((c) => c.toLowerCase().contains(token))) {
      return 200;
    }
    if (college.category.toLowerCase().contains(token)) return 180;
    if (college.searchKeywords.any((k) => k.toLowerCase().contains(token))) {
      return 150;
    }
    return 0;
  }

  static int filterMatchScore(
    CollegeModel college, {
    String? state,
    String? course,
    String? category,
  }) {
    var score = 0;
    if (state != null &&
        state.isNotEmpty &&
        college.state.toLowerCase() == state.toLowerCase()) {
      score += 100;
    }
    if (course != null &&
        course.isNotEmpty &&
        college.courses.contains(course)) {
      score += 80;
    }
    if (category != null &&
        category.isNotEmpty &&
        college.category.toLowerCase() == category.toLowerCase()) {
      score += 60;
    }
    return score;
  }

  static void rankResults(
    List<CollegeModel> colleges, {
    String? query,
    String? city,
    String? state,
    String? course,
    String? category,
  }) {
    final parsed = CollegeSearchUtils.parseCompoundQuery(query);
    final effectiveCity = city?.trim().isNotEmpty == true
        ? city
        : parsed.city ?? inferCityFromQuery(query);
    final effectiveCourse = course?.trim().isNotEmpty == true
        ? course
        : parsed.course;

    colleges.sort((a, b) {
      final cityA = cityMatchScore(a, effectiveCity);
      final cityB = cityMatchScore(b, effectiveCity);
      if (cityA != cityB) return cityB.compareTo(cityA);

      final queryA = queryMatchScore(a, query);
      final queryB = queryMatchScore(b, query);
      if (queryA != queryB) return queryB.compareTo(queryA);

      final filterA = filterMatchScore(
        a,
        state: state,
        course: effectiveCourse,
        category: category,
      );
      final filterB = filterMatchScore(
        b,
        state: state,
        course: effectiveCourse,
        category: category,
      );
      if (filterA != filterB) return filterB.compareTo(filterA);

      if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
      if (a.reviewCount != b.reviewCount) {
        return b.reviewCount.compareTo(a.reviewCount);
      }
      return a.nameLower.compareTo(b.nameLower);
    });
  }

  static String? inferCityFromQuery(String? query) {
    return CollegeSearchUtils.parseCompoundQuery(query).city;
  }
}
