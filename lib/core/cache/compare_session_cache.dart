import '../../features/compare/models/college_comparison_result.dart';

class CompareSessionCache {
  CompareSessionCache._();

  static final Map<String, CollegeComparisonResult> _cache = {};
  static const Duration ttl = Duration(minutes: 15);
  static final Map<String, DateTime> _cacheAt = {};

  static String keyFor(List<String> ids) => ids.join(',');

  static CollegeComparisonResult? get(List<String> ids) {
    final key = keyFor(ids);
    final at = _cacheAt[key];
    if (at == null || DateTime.now().difference(at) > ttl) {
      _cache.remove(key);
      _cacheAt.remove(key);
      return null;
    }
    return _cache[key];
  }

  static void set(List<String> ids, CollegeComparisonResult result) {
    final key = keyFor(ids);
    _cache[key] = result;
    _cacheAt[key] = DateTime.now();
  }
}
