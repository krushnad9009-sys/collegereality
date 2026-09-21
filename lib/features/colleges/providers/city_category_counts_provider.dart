import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'college_provider.dart';

/// The streams listed on the Browse screen, in display order.
const List<String> kBrowseCategoryLabels = [
  'Engineering',
  'Medical',
  'MBA',
  'Law',
  'Pharmacy',
  'Arts',
  'Commerce',
  'Science',
  'Polytechnic',
  'Nursing',
  'Agriculture',
  'Architecture',
];

/// Exact number of colleges per stream WITHIN one city (the family key, e.g.
/// `pune`) -- `{'Engineering': 45, 'Medical': 12, 'Law': 0, ...}`.
///
/// One structured Firestore `count()` per stream (city + category), run in
/// parallel. It is the same `cityLower` + `category` filter the search
/// results use, so a tile's number always matches the list it opens, and
/// city aliases (Bangalore/Bengaluru, Bombay/Mumbai, ...) are counted
/// together.
///
/// Deliberately all-or-nothing: if any count fails, the whole provider errors
/// rather than showing partial or un-filtered numbers for the city.
final cityCategoryCountsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, String>((ref, city) async {
      await ref.watch(collegeDataReadyProvider.future);
      final repository = ref.watch(collegeRepositoryProvider);

      final entries = await Future.wait(
        kBrowseCategoryLabels.map((label) async {
          final count = await repository.countSearchMatches(
            city: city,
            category: label,
          );
          // -1 means "no exact total available" -- never show that as a count.
          if (count < 0) {
            throw StateError('No exact count for $label in $city');
          }
          return MapEntry(label, count);
        }),
      );
      return Map.fromEntries(entries);
    });
