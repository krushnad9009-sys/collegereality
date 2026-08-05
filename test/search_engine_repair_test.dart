import 'package:college_reality_india/core/cache/college_session_cache.dart';
import 'package:college_reality_india/core/constants/college_constants.dart';
import 'package:college_reality_india/core/data/college_bundled_data_source.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/utils/college_search_utils.dart';
import 'package:flutter_test/flutter_test.dart';

const kAuditPune = 533;
const kAuditMumbai = 353;
const kAuditEngineering = 4253;
const kAuditMedical = 1359;
const kAuditNursing = 3016;

CollegeModel _college({
  required String id,
  required String name,
  required String city,
  required String state,
  required String category,
  String type = 'private',
  String? universityName,
  String? cityLower,
  List<String> searchTokens = const [],
}) {
  return CollegeModel(
    id: id,
    name: name,
    nameLower: name.toLowerCase(),
    slug: id,
    city: city,
    cityLower: cityLower ?? city.toLowerCase(),
    district: city,
    state: state,
    address: 'Test',
    type: type,
    category: category,
    universityName: universityName,
    courses: const ['B.Tech'],
    searchTokens: searchTokens,
    fees: const CollegeFees(tuitionMin: 100000, tuitionMax: 200000, hostelAnnual: 50000),
    placements: const CollegePlacements(
      highestPackageLpa: 12,
      averagePackageLpa: 6,
      placementPercentage: 80,
    ),
    aggregatedRatings: const CollegeRatings(
      overall: 4,
      faculty: 4,
      infrastructure: 4,
      placements: 4,
      campusLife: 4,
      hostel: 4,
      teaching: 4,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('audit targets documented for regression', () {
    test('mandatory production counts are locked for regression', () {
      expect(kAuditPune, 533);
      expect(kAuditMumbai, 353);
      expect(kAuditEngineering, 4253);
      expect(kAuditMedical, 1359);
      expect(kAuditNursing, 3016);
    });

    test('exhaust batch has no artificial tiny page cap', () {
      expect(
        CollegeConstants.searchExhaustBatchSize,
        greaterThanOrEqualTo(500),
      );
    });
  });

  group('resolveSearchIntent searchable fields', () {
    test('city free-text Pune', () {
      final i = CollegeSearchUtils.resolveSearchIntent(query: 'Pune');
      expect(i.city?.toLowerCase(), 'pune');
      expect(i.retrievalQuery, isNull);
      expect(i.hasCity, isTrue);
    });

    test('city free-text Mumbai', () {
      final i = CollegeSearchUtils.resolveSearchIntent(query: 'Mumbai');
      expect(i.city?.toLowerCase(), 'mumbai');
      expect(i.retrievalQuery, isNull);
    });

    test('category Engineering Medical Nursing', () {
      for (final cat in ['Engineering', 'Medical', 'Nursing']) {
        final i = CollegeSearchUtils.resolveSearchIntent(query: cat);
        expect(i.category, cat);
        expect(i.retrievalQuery, isNull);
      }
    });

    test('ownership maps to type', () {
      expect(
        CollegeSearchUtils.resolveSearchIntent(ownership: 'Government').type,
        'government',
      );
      expect(
        CollegeSearchUtils.resolveSearchIntent(ownership: 'private').type,
        'private',
      );
    });

    test('university filter preserved', () {
      final i = CollegeSearchUtils.resolveSearchIntent(
        university: 'Savitribai Phule Pune University',
      );
      expect(i.university, 'Savitribai Phule Pune University');
    });

    test('category city state combination', () {
      final i = CollegeSearchUtils.resolveSearchIntent(
        category: 'Engineering',
        city: 'Pune',
        state: 'Maharashtra',
      );
      expect(i.category, 'Engineering');
      expect(i.city, 'Pune');
      expect(i.state, 'Maharashtra');
      expect(i.retrievalQuery, isNull);
    });
  });

  group('applyFilters ownership university combined', () {
    final sample = [
      _college(
        id: '1',
        name: 'Alpha Engineering',
        city: 'Pune',
        state: 'Maharashtra',
        category: 'Engineering',
        type: 'government',
        universityName: 'SPPU',
      ),
      _college(
        id: '2',
        name: 'Beta Medical',
        city: 'Mumbai',
        state: 'Maharashtra',
        category: 'Medical',
        type: 'private',
        searchTokens: const ['aiims', 'delhi'],
      ),
      _college(
        id: '3',
        name: 'Gamma Nursing',
        city: 'Pune',
        state: 'Maharashtra',
        category: 'Nursing',
        type: 'private',
      ),
    ];

    test('city Pune returns every Pune college', () {
      expect(
        CollegeSearchUtils.applyFilters(sample, city: 'Pune').map((c) => c.id),
        ['1', '3'],
      );
    });

    test('category Engineering', () {
      expect(
        CollegeSearchUtils.applyFilters(sample, category: 'Engineering')
            .map((c) => c.id),
        ['1'],
      );
    });

    test('ownership type government', () {
      expect(
        CollegeSearchUtils.applyFilters(sample, type: 'government')
            .map((c) => c.id),
        ['1'],
      );
    });

    test('university matches name field', () {
      expect(
        CollegeSearchUtils.applyFilters(sample, university: 'SPPU')
            .map((c) => c.id),
        ['1'],
      );
    });

    test('university falls back to searchTokens', () {
      expect(
        CollegeSearchUtils.applyFilters(sample, university: 'aiims')
            .map((c) => c.id),
        ['2'],
      );
    });

    test('combined category city state', () {
      expect(
        CollegeSearchUtils.applyFilters(
          sample,
          category: 'Engineering',
          city: 'Pune',
          state: 'Maharashtra',
        ).map((c) => c.id),
        ['1'],
      );
    });

    test('cityLower used when city display empty', () {
      final odd = _college(
        id: '4',
        name: 'Delta',
        city: '',
        state: 'Maharashtra',
        category: 'Engineering',
        cityLower: 'pune',
      );
      expect(
        CollegeSearchUtils.applyFilters([odd], city: 'Pune').map((c) => c.id),
        ['4'],
      );
    });
  });

  group('session cache clear', () {
    test('clearSearch empties cached search results', () {
      CollegeSessionCache.setSearch([_college(
        id: 'x',
        name: 'X',
        city: 'Pune',
        state: 'Maharashtra',
        category: 'Engineering',
      )]);
      CollegeSessionCache.clearSearch();
      expect(CollegeSessionCache.getSearchStale(1), isNull);
    });
  });

  group('bundled offline incomplete vs audit', () {
    test('bundled dataset must not be treated as full production', () async {
      final all = await CollegeBundledDataSource.loadAll();
      expect(all.length, lessThan(kAuditEngineering));
      final pune = all
          .where((c) => CollegeSearchUtils.normalizeCity(c.city) == 'pune')
          .length;
      expect(pune, lessThan(kAuditPune));
    });
  });
}
