import 'package:college_reality_india/features/colleges/utils/college_search_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalize helpers collapse whitespace and case', () {
    expect(CollegeSearchUtils.normalizeName('  IIT  Bombay '), 'iit bombay');
    expect(CollegeSearchUtils.normalizeCity(' Pune '), 'pune');
    expect(CollegeSearchUtils.normalizeUniversity(' Savitribai '), 'savitribai');
    expect(CollegeSearchUtils.normalizeUniversity(null), '');
  });

  test('titleCaseCity and buildSlug', () {
    expect(CollegeSearchUtils.titleCaseCity('new delhi'), 'New Delhi');
    expect(CollegeSearchUtils.buildSlug('IIT Bombay!', 'Mumbai'), 'iit-bombay-mumbai');
    expect(CollegeSearchUtils.buildSlug('   ', '  '), 'college');
  });

  test('extractSearchWords splits punctuation', () {
    final words = CollegeSearchUtils.extractSearchWords('B.Tech, Pune!!');
    expect(words.any((w) => w.contains('tech') || w == 'b.tech'), isTrue);
    expect(words, contains('pune'));
  });

  test('parseCompoundQuery extracts city and course', () {
    final parsed = CollegeSearchUtils.parseCompoundQuery('B.Tech Pune');
    expect(parsed.city?.toLowerCase(), 'pune');
    expect(parsed.course, isNotNull);
  });
}