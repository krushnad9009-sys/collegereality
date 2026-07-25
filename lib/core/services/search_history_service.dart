import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local recent search queries — UI/UX only, no backend changes.
class SearchHistoryService {
  static const _key = 'recent_college_searches';
  static const _maxItems = 8;

  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    final next = [
      trimmed,
      ...current.where((e) => e.toLowerCase() != trimmed.toLowerCase()),
    ].take(_maxItems).toList();
    await prefs.setStringList(_key, next);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final searchHistoryServiceProvider = Provider<SearchHistoryService>((ref) {
  return SearchHistoryService();
});

final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(searchHistoryServiceProvider).getRecentSearches();
});

/// Static trending queries shown on the search screen.
const kTrendingCollegeSearches = [
  'IIT Bombay',
  'B.Tech Pune',
  'MBA Bangalore',
  'Medical Delhi',
  'Engineering Maharashtra',
  'NIT Trichy',
  'Computer Science',
  'Private colleges under 5 lakh',
];
