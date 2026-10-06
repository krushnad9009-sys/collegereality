import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/display_text_quality.dart';

/// Local recent search queries — UI/UX only, no backend changes.
class SearchHistoryService {
  static const _key = 'recent_college_searches';
  static const _maxItems = 8;

  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    // Also hides junk saved before the quality check existed.
    return (prefs.getStringList(_key) ?? []).where(isPresentableText).toList();
  }

  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (!isPresentableText(trimmed)) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    final next = [
      trimmed,
      ...current.where((e) => e.toLowerCase() != trimmed.toLowerCase()),
    ].take(_maxItems).toList();
    await prefs.setStringList(_key, next);
  }

  /// Removes one recent search (case-insensitive).
  Future<void> removeSearch(String query) async {
    final target = query.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    await prefs.setStringList(
      _key,
      current.where((e) => e.trim().toLowerCase() != target).toList(),
    );
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
