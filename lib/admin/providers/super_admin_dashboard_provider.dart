import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_constants.dart';
import '../../features/admin/models/admin_models.dart';
import '../../features/admin/providers/admin_dashboard_provider.dart';

class SuperAdminExtendedStats {
  final int todayRegistrations;
  final int aiUsageSessions;
  final int activeUsers;
  final DateTime fetchedAt;

  const SuperAdminExtendedStats({
    this.todayRegistrations = 0,
    this.aiUsageSessions = 0,
    this.activeUsers = 0,
    required this.fetchedAt,
  });
}

final superAdminExtendedStatsProvider = FutureProvider<SuperAdminExtendedStats>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  final usersRef = firestore.collection(FirestoreConstants.usersCollection);

  final todaySnap = await usersRef
      .where('createdAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
      .count()
      .get();
  final todayRegistrations = todaySnap.count ?? 0;

  // TODO: Wire to dedicated ai_usage collection when assistant telemetry is persisted.
  var aiUsageSessions = 0;
  try {
    final aiSnap = await firestore
        .collection(FirestoreConstants.metaCollection)
        .doc('ai_usage_stats')
        .get();
    aiUsageSessions = (aiSnap.data()?['totalSessions'] as num?)?.toInt() ?? 0;
  } catch (_) {
    aiUsageSessions = 0;
  }

  final dashboardStats = await ref.watch(adminDashboardStatsProvider.future);

  return SuperAdminExtendedStats(
    todayRegistrations: todayRegistrations,
    aiUsageSessions: aiUsageSessions,
    activeUsers: dashboardStats.dailyActiveUsers,
    fetchedAt: now,
  );
});

typedef SuperAdminDashboardBundle = ({
  AdminDashboardStats stats,
  SuperAdminExtendedStats extended,
  AdminAnalyticsData analytics,
});

final superAdminDashboardBundleProvider = FutureProvider<SuperAdminDashboardBundle>((ref) async {
  Future<SuperAdminDashboardBundle> load() async {
    final stats = await ref.watch(adminDashboardStatsProvider.future);
    final extended = await ref.watch(superAdminExtendedStatsProvider.future);
    final analytics = await ref.watch(adminAnalyticsDataProvider.future);
    return (stats: stats, extended: extended, analytics: analytics);
  }

  // Bounds the whole dashboard load, not just individual queries -- a
  // Firestore call that hangs rather than throwing (a stuck connection,
  // a still-building index that never actually errors, etc) would
  // otherwise leave the screen's AsyncValue stuck on `loading` forever,
  // which reads to a user as "the dashboard never loads" even though
  // the screen's own .when() already has a real error branch -- that
  // branch just never gets a chance to run without this.
  return load().timeout(const Duration(seconds: 20));
});
