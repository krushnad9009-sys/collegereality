import 'package:college_reality_india/core/cache/college_session_cache.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    CollegeSessionCache.clearFeatured();
  });

  test('search cache get/set/stale and limit trimming', () {
    expect(CollegeSessionCache.getSearch(5), isNull);
    expect(CollegeSessionCache.getSearchStale(5), isNull);

    final colleges = List.generate(5, (i) => CollegeModel.createDraft(id: '$i'));
    CollegeSessionCache.setSearch(colleges);
    expect(CollegeSessionCache.getSearch(5)?.length, 5);
    expect(CollegeSessionCache.getSearch(2)?.length, 2);
    expect(CollegeSessionCache.getSearchStale(2)?.length, 2);
  });

  test('byId cache get/set/clear and stale', () {
    expect(CollegeSessionCache.getById('x'), isNull);
    final college = CollegeModel.createDraft(id: 'c9');
    CollegeSessionCache.setById(college);
    expect(CollegeSessionCache.getById('c9')?.id, 'c9');
    expect(CollegeSessionCache.getByIdStale('c9')?.id, 'c9');
    CollegeSessionCache.clearById('c9');
    expect(CollegeSessionCache.getById('c9'), isNull);
    expect(CollegeSessionCache.getByIdStale('c9'), isNull);
  });

  test('featured limit trimming', () {
    final colleges = List.generate(4, (i) => CollegeModel.createDraft(id: 'f$i'));
    CollegeSessionCache.setFeatured(colleges);
    expect(CollegeSessionCache.getFeatured(2)?.length, 2);
    expect(CollegeSessionCache.getFeaturedStale(2)?.length, 2);
  });
}