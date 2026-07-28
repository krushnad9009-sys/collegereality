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
      score += 320;
    } else if (parsed.course != null) {
      score -= 500;
    }

    if (parsed.city != null) {
      final cityScore = cityMatchScore(college, parsed.city);
      if (cityScore == 0) {
        score -= 700;
      } else {
        score += cityScore;
      }
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
    if (college.nameLower == token) return 700;
    if (college.nameLower.startsWith(token)) return 550;
    if (college.nameLower.contains(token)) return 450;
    if (college.universityLower.startsWith(token)) return 430;
    if (college.universityLower.contains(token)) return 380;
    if (college.cityLower == token) return 360;
    if (college.cityLower.startsWith(token)) return 320;
    if (college.cityLower.contains(token)) return 260;
    if (college.stateLower == token) return 240;
    if (college.stateLower.contains(token)) return 200;
    if (college.courses.any((c) => c.toLowerCase().contains(token))) {
      return 260;
    }
    if (college.type.toLowerCase().contains(token)) return 200;
    if (college.category.toLowerCase().contains(token)) return 180;
    if (college.searchKeywords.any((k) => k.toLowerCase().contains(token))) {
      return 150;
    }
    return 0;
  }

  static int filterMatchScore(
    CollegeModel college, {
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
  }) {
    var score = 0;
    if (city != null && city.isNotEmpty) {
      score += cityMatchScore(college, city);
    }
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
    if (university != null &&
        university.isNotEmpty &&
        college.universityLower.contains(
          CollegeSearchUtils.normalizeUniversity(university),
        )) {
      score += 75;
    }
    if (category != null &&
        category.isNotEmpty &&
        college.category.toLowerCase() == category.toLowerCase()) {
      score += 60;
    }
    if (type != null &&
        type.isNotEmpty &&
        college.type.toLowerCase() == type.toLowerCase()) {
      score += 55;
    }
    return score;
  }

  static void rankResults(
    List<CollegeModel> colleges, {
    String? query,
    String? city,
    String? state,
    String? university,
    String? course,
    String? category,
    String? type,
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
        city: effectiveCity,
        state: state,
        university: university,
        course: effectiveCourse,
        category: category,
        type: type,
      );
      final filterB = filterMatchScore(
        b,
        city: effectiveCity,
        state: state,
        university: university,
        course: effectiveCourse,
        category: category,
        type: type,
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
