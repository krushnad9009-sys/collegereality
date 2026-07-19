import '../../features/colleges/models/college_model.dart';

/// In-memory session cache for frequently accessed college lists.
class CollegeSessionCache {
  CollegeSessionCache._();

  static List<CollegeModel>? _featured;
  static DateTime? _featuredAt;
  static List<CollegeModel>? _search;
  static DateTime? _searchAt;
  static const Duration _ttl = Duration(minutes: 20);

  static List<CollegeModel>? getFeatured(int limit) {
    final cached = _featured;
    final at = _featuredAt;
    if (cached == null || at == null) return null;
    if (DateTime.now().difference(at) > _ttl) {
      return null;
    }
    if (cached.length <= limit) return cached;
    return cached.take(limit).toList();
  }

  /// Returns featured list even if TTL expired (quota fallback).
  static List<CollegeModel>? getFeaturedStale(int limit) {
    final cached = _featured;
    if (cached == null) return null;
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

  static List<CollegeModel>? getSearch(int limit) {
    final cached = _search;
    final at = _searchAt;
    if (cached == null || at == null) return null;
    if (DateTime.now().difference(at) > _ttl) return null;
    if (cached.length <= limit) return cached;
    return cached.take(limit).toList();
  }

  static List<CollegeModel>? getSearchStale(int limit) {
    final cached = _search;
    if (cached == null) return null;
    if (cached.length <= limit) return cached;
    return cached.take(limit).toList();
  }

  static void setSearch(List<CollegeModel> colleges) {
    _search = List.unmodifiable(colleges);
    _searchAt = DateTime.now();
  }

  static final Map<String, _CachedCollege> _byId = {};

  static CollegeModel? getById(String id) {
    final entry = _byId[id];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > _ttl) return null;
    return entry.college;
  }

  static CollegeModel? getByIdStale(String id) => _byId[id]?.college;

  static void setById(CollegeModel college) {
    _byId[college.id] = _CachedCollege(college, DateTime.now());
  }

  static void clearById(String id) => _byId.remove(id);
}

class _CachedCollege {
  final CollegeModel college;
  final DateTime at;

  _CachedCollege(this.college, this.at);
}
