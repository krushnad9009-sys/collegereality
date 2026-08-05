import 'package:college_reality_india/core/data/college_bundled_data_source.dart';
import 'package:college_reality_india/features/colleges/utils/college_search_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveSearchIntent', () {
    test('Pune free-text promotes city and clears retrieval query', () {
      final intent = CollegeSearchUtils.resolveSearchIntent(query: 'Pune');
      expect(intent.city?.toLowerCase(), 'pune');
      expect(intent.retrievalQuery, isNull);
      expect(intent.rankingQuery, 'Pune');
    });

    test('Engineering free-text promotes category', () {
      final intent =
          CollegeSearchUtils.resolveSearchIntent(query: 'Engineering');
      expect(intent.category, 'Engineering');
      expect(intent.retrievalQuery, isNull);
    });

    test('explicit city wins over parsed city', () {
      final intent = CollegeSearchUtils.resolveSearchIntent(
        query: 'Pune',
        city: 'Mumbai',
      );
      expect(intent.city, 'Mumbai');
    });

    test('compound B.Tech Pune promotes city and course', () {
      final intent =
          CollegeSearchUtils.resolveSearchIntent(query: 'B.Tech Pune');
      expect(intent.city?.toLowerCase(), 'pune');
      expect(intent.course, 'B.Tech');
      expect(intent.retrievalQuery, isNull);
    });
  });

  group('bundled search against complete dataset', () {
    Future<Set<String>> collectAllIds({
      String? query,
      String? state,
      String? city,
      String? university,
      String? course,
      String? category,
      String? type,
    }) async {
      final ids = <String>{};
      String? cursor;
      var hasMore = true;
      var pages = 0;
      while (hasMore && pages < 40) {
        final page = await CollegeBundledDataSource.search(
          query: query,
          state: state,
          city: city,
          university: university,
          course: course,
          category: category,
          type: type,
          limit: 24,
          startAfterDocumentId: cursor,
        );
        for (final college in page.colleges) {
          ids.add(college.id);
        }
        cursor = page.lastDocumentId;
        hasMore = page.hasMore;
        pages++;
        if (page.colleges.isEmpty) break;
      }
      return ids;
    }

    test('Pune returns ALL Pune-city colleges from dataset', () async {
      final all = await CollegeBundledDataSource.loadAll();
      final expected = all
          .where(
            (c) =>
                c.isActive &&
                CollegeSearchUtils.cityMatchesCollege(
                  cityLower: c.cityLower,
                  districtLower: c.districtLower,
                  cityFilter: 'Pune',
                ),
          )
          .map((c) => c.id)
          .toSet();
      expect(expected, isNotEmpty);

      final found = await collectAllIds(query: 'Pune');
      expect(found, expected);
      expect(found.length, greaterThan(1));
    });

    test('Mumbai returns ALL Mumbai-city colleges from dataset', () async {
      final all = await CollegeBundledDataSource.loadAll();
      final expected = all
          .where(
            (c) =>
                c.isActive &&
                CollegeSearchUtils.cityMatchesCollege(
                  cityLower: c.cityLower,
                  districtLower: c.districtLower,
                  cityFilter: 'Mumbai',
                ),
          )
          .map((c) => c.id)
          .toSet();
      expect(expected, isNotEmpty);

      final found = await collectAllIds(query: 'Mumbai');
      expect(found, expected);
      expect(found.length, greaterThan(1));
    });

    test('Engineering category returns only Engineering colleges', () async {
      final page = await CollegeBundledDataSource.search(
        query: 'Engineering',
        limit: 50,
      );
      expect(page.colleges, isNotEmpty);
      expect(
        page.colleges.every((c) => c.category.toLowerCase() == 'engineering'),
        isTrue,
      );
    });

    test('Medical category returns only Medical colleges', () async {
      final page = await CollegeBundledDataSource.search(
        query: 'Medical',
        limit: 50,
      );
      expect(page.colleges, isNotEmpty);
      expect(
        page.colleges.every((c) => c.category.toLowerCase() == 'medical'),
        isTrue,
      );
    });

    test('combined city + category filters', () async {
      final page = await CollegeBundledDataSource.search(
        city: 'Pune',
        category: 'Engineering',
        limit: 50,
      );
      for (final college in page.colleges) {
        expect(
          CollegeSearchUtils.cityMatchesCollege(
            cityLower: college.cityLower,
            districtLower: college.districtLower,
            cityFilter: 'Pune',
          ),
          isTrue,
        );
        expect(college.category.toLowerCase(), 'engineering');
      }
    });

    test('empty search returns a browse page without crashing', () async {
      final page = await CollegeBundledDataSource.search(limit: 24);
      expect(page.colleges, isNotEmpty);
      expect(page.colleges.length, lessThanOrEqualTo(24));
    });

    test('partial name search returns matching colleges', () async {
      final all = await CollegeBundledDataSource.loadAll();
      final sample = all.firstWhere(
        (c) => c.isActive && c.name.trim().length >= 4,
      );
      final partial = sample.name.substring(0, 3);
      final page = await CollegeBundledDataSource.search(
        query: partial,
        limit: 50,
      );
      expect(page.colleges, isNotEmpty);
      expect(
        page.colleges.every(
          (c) => CollegeSearchUtils.matchesQuery(c, partial),
        ),
        isTrue,
      );
    });

    test('university search matches university field', () async {
      final all = await CollegeBundledDataSource.loadAll();
      final withUni = all.where(
        (c) =>
            c.isActive &&
            (c.universityName?.trim().isNotEmpty ?? false) &&
            c.universityName!.trim().length >= 5,
      );
      expect(withUni, isNotEmpty);
      final sample = withUni.first;
      final needle = sample.universityName!.trim().split(' ').first;
      final page = await CollegeBundledDataSource.search(
        query: needle,
        limit: 50,
      );
      expect(page.colleges, isNotEmpty);
      expect(
        page.colleges.any(
          (c) => CollegeSearchUtils.normalizeUniversity(c.universityName)
              .contains(CollegeSearchUtils.normalizeUniversity(needle)),
        ),
        isTrue,
      );
    });
  });
}