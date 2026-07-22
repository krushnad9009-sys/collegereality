import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/colleges/models/college_model.dart';

/// Persists featured / trending / top-rated college lists for offline quota fallback.
class CollegeLocalCache {
  CollegeLocalCache._();

  static const _featuredKey = 'college_cache_featured_v1';
  static const _trendingKey = 'college_cache_trending_v1';
  static const _topRatedKey = 'college_cache_top_rated_v1';
  static const _searchKey = 'college_cache_search_v1';
  static const _countKey = 'college_cache_count_v1';
  static const _collegePrefix = 'college_cache_id_v1_';
  static const _maxCachedColleges = 120;

  static Future<void> saveFeatured(List<CollegeModel> colleges) async {
    await _saveList(_featuredKey, colleges);
    await _saveDerivedLists(colleges);
  }

  static Future<void> saveTrending(List<CollegeModel> colleges) async {
    await _saveList(_trendingKey, colleges);
  }

  static Future<void> saveTopRated(List<CollegeModel> colleges) async {
    await _saveList(_topRatedKey, colleges);
  }

  static Future<void> saveSearch(List<CollegeModel> colleges) async {
    await _saveList(_searchKey, colleges);
  }

  static Future<void> saveCollegeCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, count);
  }

  static Future<List<CollegeModel>?> loadFeatured() => _loadList(_featuredKey);

  static Future<List<CollegeModel>?> loadTrending() => _loadList(_trendingKey);

  static Future<List<CollegeModel>?> loadTopRated() => _loadList(_topRatedKey);

  static Future<List<CollegeModel>?> loadSearch() => _loadList(_searchKey);

  static Future<int?> loadCollegeCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_countKey);
  }

  static Future<void> saveCollege(CollegeModel college) async {
    if (college.id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_collegePrefix${college.id}',
      jsonEncode(college.toJson()),
    );
    await _trimCollegeCache(prefs);
  }

  static Future<CollegeModel?> loadCollege(String id) async {
    if (id.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_collegePrefix$id');
    if (raw == null || raw.isEmpty) return null;
    try {
      return CollegeModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        docId: id,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _trimCollegeCache(SharedPreferences prefs) async {
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_collegePrefix))
        .toList();
    if (keys.length <= _maxCachedColleges) return;
    keys.sort();
    for (final key in keys.take(keys.length - _maxCachedColleges)) {
      await prefs.remove(key);
    }
  }

  static Future<void> _saveDerivedLists(List<CollegeModel> featured) async {
    if (featured.isEmpty) return;
    final trending = featured.take(12).toList();
    final topRated = [...featured]
      ..sort(
        (a, b) =>
            b.aggregatedRatings.overall.compareTo(a.aggregatedRatings.overall),
      );
    await saveTrending(trending);
    await saveTopRated(topRated.take(8).toList());
  }

  static Future<void> _saveList(String key, List<CollegeModel> colleges) async {
    if (colleges.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = colleges.map((c) => c.toJson()).toList();
    await prefs.setString(key, jsonEncode(payload));
  }

  static Future<List<CollegeModel>?> _loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => CollegeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
