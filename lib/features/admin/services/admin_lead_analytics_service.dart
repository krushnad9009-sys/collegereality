import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_constants.dart';
import '../models/admin_models.dart';

/// Weekly Lead Analytics (Super Admin panel) -- reads the per-user rollup
/// docs functions/src/leadActivityTriggers.js maintains from students'
/// search-by-faculty/college-view/call-college activity (see
/// lib/features/leads/services/lead_activity_service.dart for the writes).
class AdminLeadAnalyticsService {
  AdminLeadAnalyticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _summaries =>
      _firestore.collection(FirestoreConstants.leadSummariesCollection);

  /// Every `lead_summaries` doc active in the last 7 days, newest first.
  /// State/City/Faculty are NOT filtered here server-side -- combining
  /// those equality filters with the `lastActiveAt` range filter would
  /// need a composite index per combination (state alone, city alone,
  /// faculty alone, and every pairing), none of which are deployed for
  /// this collection. Filtering this single, already date-bounded fetch
  /// client-side (AdminLeadAnalyticsScreen) avoids that entirely; the
  /// range filter + matching orderBy on the SAME field (`lastActiveAt`)
  /// needs no composite index since Firestore's automatic single-field
  /// index already covers it. [sampleLimit] caps how many of the most
  /// recently active leads are fetched -- a real limit on how many
  /// people were active this week, not an approximation the way the
  /// Region Analytics "active users" count is.
  Future<List<LeadSummary>> getWeeklyLeads({int sampleLimit = 1000}) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final snap = await _summaries
        .where('lastActiveAt', isGreaterThanOrEqualTo: cutoff)
        .orderBy('lastActiveAt', descending: true)
        .limit(sampleLimit)
        .get();
    return snap.docs.map(_map).toList();
  }

  LeadSummary _map(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final lastActiveRaw = data['lastActiveAt']?.toString();
    return LeadSummary(
      uid: doc.id,
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      state: data['state']?.toString() ?? '',
      topFaculty: data['topFaculty']?.toString(),
      lastActiveAt: lastActiveRaw != null ? DateTime.tryParse(lastActiveRaw) : null,
    );
  }
}
