import 'package:college_reality_india/core/constants/cr_score_constants.dart';
import 'package:college_reality_india/features/ranking/models/cr_score_model.dart';
import 'package:college_reality_india/features/ranking/services/cr_score_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  CrScoreSnapshot _snapshot({double score = 82.5, int reviews = 120}) {
    return CrScoreSnapshot(
      score: score,
      categories: const CrScoreCategories(
        education: 80,
        placements: 90,
        campusLife: 75,
        infrastructure: 70,
        safety: 85,
      ),
      verifiedReviewCount: reviews,
      updatedAt: DateTime(2026, 2, 1),
    );
  }

  group('CrScoreCacheService', () {
    test('cacheSnapshot and readSnapshot round-trip', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = CrScoreCacheService(prefs);
      final snapshot = _snapshot();

      await service.cacheSnapshot('col-1', snapshot);
      final loaded = service.readSnapshot('col-1');

      expect(loaded, isNotNull);
      expect(loaded!.score, 82.5);
      expect(loaded.categories.placements, 90);
      expect(loaded.verifiedReviewCount, 120);
      expect(loaded.updatedAt, snapshot.updatedAt);
    });

    test('readSnapshot returns null for unknown college', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = CrScoreCacheService(prefs);
      expect(service.readSnapshot('missing'), isNull);
    });

    test('readSnapshot returns null for expired cache', () async {
      final expiredAt = DateTime.now().subtract(const Duration(hours: 7));
      SharedPreferences.setMockInitialValues({
        'cr_score_cache_v1_col-expired': '''
{"score":70,"categories":{"${CrScoreConstants.categoryEducation}":70,"${CrScoreConstants.categoryPlacements}":70,"${CrScoreConstants.categoryCampusLife}":70,"${CrScoreConstants.categoryInfrastructure}":70,"${CrScoreConstants.categorySafety}":70},"verifiedReviewCount":10,"updatedAt":"2026-01-01T00:00:00.000","cachedAt":"${expiredAt.toIso8601String()}"}
''',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = CrScoreCacheService(prefs);
      expect(service.readSnapshot('col-expired'), isNull);
    });

    test('readSnapshot returns null for corrupt JSON', () async {
      SharedPreferences.setMockInitialValues({
        'cr_score_cache_v1_col-bad': '{not-json',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = CrScoreCacheService(prefs);
      expect(service.readSnapshot('col-bad'), isNull);
    });

    test('clearCollege removes cached entry', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = CrScoreCacheService(prefs);
      await service.cacheSnapshot('col-clear', _snapshot());
      expect(service.readSnapshot('col-clear'), isNotNull);

      await service.clearCollege('col-clear');
      expect(service.readSnapshot('col-clear'), isNull);
    });
  });
}
