import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/bootstrap/app_error_handler.dart';
import 'package:college_reality_india/core/cache/college_session_cache.dart';

void main() {
  group('CollegeSessionCache', () {
    tearDown(CollegeSessionCache.clearFeatured);

    test('returns null when cache is empty', () {
      expect(CollegeSessionCache.getFeatured(6), isNull);
    });

    test('clearFeatured resets cache state', () {
      CollegeSessionCache.clearFeatured();
      expect(CollegeSessionCache.getFeatured(6), isNull);
    });
  });

  group('AppErrorHandler', () {
    test('install completes without throwing', () {
      expect(AppErrorHandler.install, returnsNormally);
    });
  });
}
