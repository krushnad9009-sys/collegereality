import '../models/admin_models.dart';

/// Buckets documents by day for growth charts.
List<AdminGrowthPoint> buildGrowthSeries({
  required List<DateTime> timestamps,
  int days = 14,
}) {
  if (timestamps.isEmpty) return [];

  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
  final buckets = <DateTime, int>{};

  for (var i = 0; i < days; i++) {
    final day = start.add(Duration(days: i));
    buckets[DateTime(day.year, day.month, day.day)] = 0;
  }

  for (final ts in timestamps) {
    final day = DateTime(ts.year, ts.month, ts.day);
    if (buckets.containsKey(day)) {
      buckets[day] = (buckets[day] ?? 0) + 1;
    }
  }

  final sorted = buckets.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  var cumulative = 0;
  return sorted.map((e) {
    cumulative += e.value;
    return AdminGrowthPoint(date: e.key, count: cumulative);
  }).toList();
}

List<AdminGrowthPoint> buildDailyGrowthSeries({
  required List<DateTime> timestamps,
  int days = 14,
}) {
  if (timestamps.isEmpty) return [];

  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
  final buckets = <DateTime, int>{};

  for (var i = 0; i < days; i++) {
    final day = start.add(Duration(days: i));
    buckets[DateTime(day.year, day.month, day.day)] = 0;
  }

  for (final ts in timestamps) {
    final day = DateTime(ts.year, ts.month, ts.day);
    if (buckets.containsKey(day)) {
      buckets[day] = (buckets[day] ?? 0) + 1;
    }
  }

  return buckets.entries
      .map((e) => AdminGrowthPoint(date: e.key, count: e.value))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}

int countActiveSince(List<DateTime?> lastSeenTimes, Duration window) {
  final cutoff = DateTime.now().subtract(window);
  return lastSeenTimes.where((t) => t != null && t.isAfter(cutoff)).length;
}

List<AdminTopCollegeMetric> rankBookmarkCounts(
  Map<String, int> bookmarkCounts,
  Map<String, String> collegeNames, {
  int limit = 10,
}) {
  final entries = bookmarkCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.take(limit).map((e) {
    return AdminTopCollegeMetric(
      collegeId: e.key,
      collegeName: collegeNames[e.key] ?? e.key,
      value: e.value,
      label: '${e.value} bookmarks',
    );
  }).toList();
}

bool isLikelySpamReport(String reason) {
  final lower = reason.toLowerCase();
  return lower.contains('spam') ||
      lower.contains('promo') ||
      lower.contains('advertisement') ||
      lower.contains('scam');
}

bool isLikelyAbuseReport(String reason) {
  final lower = reason.toLowerCase();
  return lower.contains('abuse') ||
      lower.contains('harass') ||
      lower.contains('hate') ||
      lower.contains('threat') ||
      lower.contains('offensive');
}
