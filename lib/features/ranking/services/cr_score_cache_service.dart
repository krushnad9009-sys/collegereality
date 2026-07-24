import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cr_score_model.dart';

/// Local cache for frequently viewed CR Score snapshots.
class CrScoreCacheService {
  CrScoreCacheService(this._prefs);

  final SharedPreferences _prefs;
  static const _prefix = 'cr_score_cache_v1_';
  static const _ttl = Duration(hours: 6);

  Future<void> cacheSnapshot(String collegeId, CrScoreSnapshot snapshot) async {
    await _prefs.setString(
      '$_prefix$collegeId',
      jsonEncode({
        'score': snapshot.score,
        'categories': snapshot.categories.toJson(),
        'verifiedReviewCount': snapshot.verifiedReviewCount,
        'updatedAt': snapshot.updatedAt?.toIso8601String(),
        'cachedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  CrScoreSnapshot? readSnapshot(String collegeId) {
    final raw = _prefs.getString('$_prefix$collegeId');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(map['cachedAt']?.toString() ?? '');
      if (cachedAt == null ||
          DateTime.now().difference(cachedAt) > _ttl) {
        return null;
      }
      return CrScoreSnapshot(
        score: (map['score'] as num?)?.toDouble() ?? 0,
        categories: CrScoreCategories.fromJson(
          map['categories'] as Map<String, dynamic>?,
        ),
        verifiedReviewCount: (map['verifiedReviewCount'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCollege(String collegeId) async {
    await _prefs.remove('$_prefix$collegeId');
  }
}
