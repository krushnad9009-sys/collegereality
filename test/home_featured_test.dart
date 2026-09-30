import 'package:college_reality_india/features/home/featured/home_featured.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeFeaturedConfig.fromJson', () {
    test('missing doc = nothing curated', () {
      expect(HomeFeaturedConfig.fromJson(null).isEmpty, isTrue);
    });

    test('keeps order, drops blanks/duplicates/non-strings, caps at max', () {
      final config = HomeFeaturedConfig.fromJson({
        'collegeIds': ['c3', 'c1', '', 'c3', 42, 'c2'],
        'guideIds': [for (var i = 0; i < 15; i++) 'g$i'],
      });
      expect(config.collegeIds, ['c3', 'c1', 'c2']);
      expect(config.guideIds, hasLength(HomeFeaturedConfig.maxItems));
      expect(config.guideIds.first, 'g0');
    });
  });

  group('editing the list', () {
    test('add appends once and respects the cap', () {
      expect(addFeaturedId(['a'], 'b'), ['a', 'b']);
      expect(addFeaturedId(['a', 'b'], 'a'), ['a', 'b']);
      expect(addFeaturedId(['a', 'b'], 'c', max: 2), ['a', 'b']);
    });

    test('move to a final position (priority 1, 2, 3...)', () {
      const ids = ['a', 'b', 'c', 'd'];
      expect(moveFeaturedId(ids, 3, 0), ['d', 'a', 'b', 'c']); // to top
      expect(moveFeaturedId(ids, 0, 3), ['b', 'c', 'd', 'a']); // to bottom
      expect(moveFeaturedId(ids, 1, 2), ['a', 'c', 'b', 'd']); // down one
      expect(moveFeaturedId(ids, 2, 1), ['a', 'c', 'b', 'd']); // up one
      expect(moveFeaturedId(ids, 9, 0), ids); // out of range: unchanged
    });
  });

  test('resolved items follow the curated order and skip missing ones', () {
    final byId = {'b': 'B', 'a': 'A', 'd': 'D'};
    expect(inFeaturedOrder(['d', 'x', 'a', 'b'], byId), ['D', 'A', 'B']);
  });
}
