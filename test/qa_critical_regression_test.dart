import 'package:college_reality_india/config/router/route_names.dart';
import 'package:college_reality_india/core/cache/college_session_cache.dart';
import 'package:college_reality_india/core/constants/college_constants.dart';
import 'package:college_reality_india/core/data/college_bundled_data_source.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/utils/college_search_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('City aliases (QA)', () {
    test('Delhi matches New Delhi colleges', () {
      expect(
        CollegeSearchUtils.citySearchKeys('Delhi'),
        containsAll(['delhi', 'new delhi']),
      );
      expect(
        CollegeSearchUtils.cityMatchesCollege(
          cityLower: 'new delhi',
          districtLower: '',
          cityFilter: 'Delhi',
        ),
        isTrue,
      );
      expect(CollegeSearchUtils.cityNeedsAliasMerge('Delhi'), isTrue);
      expect(CollegeSearchUtils.cityNeedsAliasMerge('Chennai'), isTrue); // madras alias
    });

    test('Bangalore/Bengaluru still need alias merge', () {
      expect(CollegeSearchUtils.cityNeedsAliasMerge('Bangalore'), isTrue);
    });
  });

  group('Course matching (QA)', () {
    test('fuzzy B.Tech variants match', () {
      expect(
        CollegeSearchUtils.courseMatches(['BTech', 'MBA'], 'B.Tech'),
        isTrue,
      );
    });

    test('BA does not false-match MBA or BBA', () {
      expect(CollegeSearchUtils.courseMatches(['MBA'], 'BA'), isFalse);
      expect(CollegeSearchUtils.courseMatches(['BBA'], 'BA'), isFalse);
      expect(CollegeSearchUtils.courseMatches(['BA'], 'BA'), isTrue);
    });
  });

  group('Dropdown clamp (QA)', () {
    test('clampToAllowed is case-insensitive and returns canonical', () {
      expect(
        CollegeConstants.clampToAllowed('Maharashtra', CollegeConstants.indianStates),
        'Maharashtra',
      );
      expect(
        CollegeConstants.clampToAllowed('maharashtra', CollegeConstants.indianStates),
        'Maharashtra',
      );
      expect(
        CollegeConstants.clampToAllowed('Private', CollegeConstants.collegeTypes),
        'private',
      );
      expect(
        CollegeConstants.clampToAllowed('UnknownState', CollegeConstants.indianStates),
        isNull,
      );
    });

    test('dedupePreserveOrder removes duplicates', () {
      expect(
        CollegeConstants.dedupePreserveOrder(['MBA', 'mba', 'Engineering']),
        ['MBA', 'Engineering'],
      );
    });
  });

  group('Auth return paths (QA)', () {
    test('login/signup/display-name preserve from', () {
      expect(
        RouteNames.loginWithReturn('/college-details/abc'),
        contains('from='),
      );
      expect(
        RouteNames.signupWithReturn('/college-details/abc'),
        contains('from='),
      );
      expect(
        RouteNames.displayNameSetupWithReturn('/college-details/abc'),
        allOf(contains(RouteNames.displayNameSetup), contains('from=')),
      );
      expect(
        RouteNames.safeReturnPath('/college-details/abc?tab=reviews'),
        '/college-details/abc?tab=reviews',
      );
      expect(RouteNames.safeReturnPath('https://evil.com'), isNull);
    });
  });

  group('Featured session cache (QA)', () {
    setUp(CollegeSessionCache.clearFeatured);

    test('smaller featured write does not shrink cached pool', () {
      final large = List.generate(
        12,
        (i) => CollegeModel.createDraft(id: 'c$i').copyWith(
          name: 'College $i',
          nameLower: 'college $i',
        ),
      );
      CollegeSessionCache.setFeatured(large);
      CollegeSessionCache.setFeatured(large.take(6).toList());
      expect(CollegeSessionCache.getFeatured(12)?.length, 12);
    });
  });

  group('Bundled search combinations (QA)', () {
    test('city + course + category combinations return coherent pages', () async {
      final delhi = await CollegeBundledDataSource.search(city: 'Delhi', limit: 24);
      expect(delhi.colleges, isNotEmpty);
      expect(
        delhi.colleges.every(
          (c) => CollegeSearchUtils.cityMatchesCollege(
            cityLower: c.cityLower,
            districtLower: c.districtLower,
            cityFilter: 'Delhi',
          ),
        ),
        isTrue,
      );

      final page1 = await CollegeBundledDataSource.search(limit: 10);
      expect(page1.hasMore, isTrue);
      final page2 = await CollegeBundledDataSource.search(
        limit: 10,
        startAfterDocumentId: page1.lastDocumentId,
      );
      final ids1 = page1.colleges.map((c) => c.id).toSet();
      final ids2 = page2.colleges.map((c) => c.id).toSet();
      expect(ids1.intersection(ids2), isEmpty);

      final engineering = await CollegeBundledDataSource.search(
        category: 'Engineering',
        limit: 20,
      );
      expect(
        engineering.colleges.every(
          (c) => c.category.toLowerCase() == 'engineering',
        ),
        isTrue,
      );

      final ownership = await CollegeBundledDataSource.search(
        type: 'private',
        limit: 20,
      );
      expect(
        ownership.colleges.every((c) => c.type.toLowerCase() == 'private'),
        isTrue,
      );

      final combined = await CollegeBundledDataSource.search(
        city: 'Pune',
        state: 'Maharashtra',
        category: 'Engineering',
        limit: 20,
      );
      for (final c in combined.colleges) {
        expect(CollegeSearchUtils.normalizeState(c.state), 'maharashtra');
        expect(
          CollegeSearchUtils.cityMatchesCollege(
            cityLower: c.cityLower,
            districtLower: c.districtLower,
            cityFilter: 'Pune',
          ),
          isTrue,
        );
        expect(c.category.toLowerCase(), 'engineering');
      }
    });
  });
}