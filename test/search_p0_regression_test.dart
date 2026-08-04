import 'package:college_reality_india/features/colleges/utils/college_search_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CollegeSearchUtils city aliases', () {
    test('Bangalore and Bengaluru share search keys', () {
      expect(
        CollegeSearchUtils.citySearchKeys('Bangalore'),
        containsAll(['bangalore', 'bengaluru']),
      );
      expect(
        CollegeSearchUtils.cityMatchesCollege(
          cityLower: 'bengaluru',
          districtLower: '',
          cityFilter: 'Bangalore',
        ),
        isTrue,
      );
    });
  });

  group('CollegeSearchUtils course matching', () {
    test('tolerates dots and spacing', () {
      expect(
        CollegeSearchUtils.courseMatches(['B.Tech', 'MBA'], 'BTech'),
        isTrue,
      );
      expect(
        CollegeSearchUtils.courseMatches(['B.Tech'], 'b.tech'),
        isTrue,
      );
      expect(
        CollegeSearchUtils.courseMatches(['MBA'], 'B.Tech'),
        isFalse,
      );
    });
  });

  group('CollegeSearchUtils university normalize', () {
    test('collapses whitespace', () {
      expect(
        CollegeSearchUtils.normalizeUniversity('Pune  University'),
        'pune university',
      );
    });
  });
}