import 'package:college_reality_india/core/services/search_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SearchHistoryService', () {
    test('ignores short queries and stores trimmed unique recent searches',
        () async {
      final service = SearchHistoryService();
      await service.addSearch('a');
      expect(await service.getRecentSearches(), isEmpty);

      await service.addSearch('  IIT Bombay  ');
      await service.addSearch('NIT Trichy');
      await service.addSearch('iit bombay');

      expect(await service.getRecentSearches(), ['iit bombay', 'NIT Trichy']);
    });

    test('caps history and clears', () async {
      final service = SearchHistoryService();
      for (var i = 0; i < 12; i++) {
        await service.addSearch('query-$i');
      }
      final recent = await service.getRecentSearches();
      expect(recent.length, 8);
      expect(recent.first, 'query-11');

      await service.clear();
      expect(await service.getRecentSearches(), isEmpty);
    });
  });

  test('trending search constants are non-empty', () {
    expect(kTrendingCollegeSearches, isNotEmpty);
    expect(kTrendingCollegeSearches.first, isNotEmpty);
  });
}
