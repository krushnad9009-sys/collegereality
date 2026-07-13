import '../../features/colleges/models/college_model.dart';

/// In-memory session cache for frequently accessed college lists.
class CollegeSessionCache {
  CollegeSessionCache._();

  static List<CollegeModel>? _featured;
  static DateTime? _featuredAt;
  static const Duration _ttl = Duration(minutes: 20);

  static List<CollegeModel>? getFeatured(int limit) {
    final cached = _featured;
    final at = _featuredAt;
    if (cached == null || at == null) return null;
    if (DateTime.now().difference(at) > _ttl) {
      clearFeatured();
      return null;
    }
    if (cached.length <= limit) return cached;
    return cached.take(limit).toList();
  }

  static void setFeatured(List<CollegeModel> colleges) {
    _featured = List.unmodifiable(colleges);
    _featuredAt = DateTime.now();
  }

  static void clearFeatured() {
    _featured = null;
    _featuredAt = null;
  }
}
