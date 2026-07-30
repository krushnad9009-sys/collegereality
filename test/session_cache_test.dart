import 'package:college_reality_india/core/cache/college_session_cache.dart';
import 'package:college_reality_india/core/cache/ranking_session_cache.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    CollegeSessionCache.clearFeatured();
    RankingSessionCache.clearAll();
  });

  test('CollegeSessionCache stores and returns featured list', () {
    expect(CollegeSessionCache.getFeatured(5), isNull);
    final draft = CollegeModel.createDraft(id: '1');
    CollegeSessionCache.setFeatured([draft]);
    expect(CollegeSessionCache.getFeatured(5)?.length, 1);
    expect(CollegeSessionCache.getFeaturedStale(5)?.length, 1);
    CollegeSessionCache.clearFeatured();
    expect(CollegeSessionCache.getFeatured(5), isNull);
  });

  test('RankingSessionCache key and set/get', () {
    final key = RankingSessionCache.rankingKey(state: 'MH', course: 'CSE');
    expect(key, contains('MH'));
    expect(RankingSessionCache.getRankingList(key), isNull);
    final draft = CollegeModel.createDraft(id: '2');
    RankingSessionCache.setRankingList(key, [draft]);
    expect(RankingSessionCache.getRankingList(key)?.first.id, '2');
  });
}