import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/call_session_model.dart';
import '../models/interaction_rating_model.dart';
import '../models/public_guide_profile.dart';
import '../models/public_student_profile.dart';
import '../services/communication_firestore_service.dart';
import '../utils/communication_formatters.dart';

final communicationServiceProvider = Provider<CommunicationFirestoreService>((ref) {
  return CommunicationFirestoreService();
});

final guidesDirectoryProvider =
    FutureProvider.family<List<PublicGuideProfile>, String?>((ref, language) {
  return ref.watch(communicationServiceProvider).searchGuides(language: language);
});

final publicGuideProvider =
    FutureProvider.family<PublicGuideProfile?, String>((ref, uid) {
  return ref.watch(communicationServiceProvider).getPublicGuideProfile(uid);
});

final collegeConnectableStudentsProvider = FutureProvider.family<
    List<PublicStudentProfile>, ({String collegeId, String? excludeUserId})>(
  (ref, params) {
    return ref.watch(communicationServiceProvider).searchConnectableStudents(
          collegeId: params.collegeId,
          excludeUserId: params.excludeUserId,
        );
  },
);

final callSessionProvider =
    StreamProvider.family<CallSessionModel?, String>((ref, sessionId) {
  return ref.watch(communicationServiceProvider).watchCallSession(sessionId);
});

final incomingCallsProvider =
    StreamProvider.family<List<CallSessionModel>, String>((ref, userId) {
  return FirebaseFirestore.instance.watchIncomingCalls(userId);
});

final adminReportsProvider = FutureProvider<List<UserReportModel>>((ref) {
  return ref.watch(communicationServiceProvider).getOpenReports();
});
