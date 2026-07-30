import 'package:college_reality_india/core/cache/college_local_cache.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  CollegeModel sample(String id, {double overall = 4}) {
    return CollegeModel.createDraft(id: id).copyWith(
      name: 'College $id',
      nameLower: 'college $id',
      aggregatedRatings: CollegeRatings(
        overall: overall,
        faculty: overall,
        infrastructure: overall,
        placements: overall,
        campusLife: overall,
      ),
    );
  }

  test('save/load featured trending topRated search and count', () async {
    final list = [sample('a', overall: 3), sample('b', overall: 5)];
    await CollegeLocalCache.saveFeatured(list);
    final featured = await CollegeLocalCache.loadFeatured();
    expect(featured, isNotNull);
    expect(featured!.length, 2);
    final trending = await CollegeLocalCache.loadTrending();
    expect(trending, isNotNull);
    final top = await CollegeLocalCache.loadTopRated();
    expect(top!.first.id, 'b');

    await CollegeLocalCache.saveSearch([sample('s1')]);
    expect((await CollegeLocalCache.loadSearch())!.first.id, 's1');

    await CollegeLocalCache.saveCollegeCount(42);
    expect(await CollegeLocalCache.loadCollegeCount(), 42);
  });

  test('save/load college by id and empty guards', () async {
    expect(await CollegeLocalCache.loadCollege(''), isNull);
    await CollegeLocalCache.saveCollege(CollegeModel.createDraft(id: ''));
    expect(await CollegeLocalCache.loadCollege('missing'), isNull);

    final c = sample('c99');
    await CollegeLocalCache.saveCollege(c);
    final loaded = await CollegeLocalCache.loadCollege('c99');
    expect(loaded?.id, 'c99');
  });
}