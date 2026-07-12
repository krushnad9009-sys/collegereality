import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/communication_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../models/call_session_model.dart';

extension CommunicationFirestoreQueries on FirebaseFirestore {
  Stream<List<CallSessionModel>> watchIncomingCalls(String calleeId) {
    return collection(FirestoreConstants.callSessionsCollection)
        .where('calleeId', isEqualTo: calleeId)
        .where('status', whereIn: [
          CommunicationConstants.callStatusRequested,
          CommunicationConstants.callStatusAccepted,
        ])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => CallSessionModel.fromJson(d.data(), docId: d.id))
            .toList());
  }
}

String formatGuideResponseTime(int minutes) {
  if (minutes <= 0) return 'Usually responds quickly';
  if (minutes < 60) return '~$minutes min response';
  final hours = (minutes / 60).round();
  return '~$hours hr response';
}

String formatLastActive(DateTime? lastActive) {
  if (lastActive == null) return 'Recently active';
  final diff = DateTime.now().difference(lastActive);
  if (diff.inMinutes < 5) return 'Active now';
  if (diff.inHours < 1) return 'Active ${diff.inMinutes}m ago';
  if (diff.inDays < 1) return 'Active ${diff.inHours}h ago';
  if (diff.inDays < 7) return 'Active ${diff.inDays}d ago';
  return 'Active ${lastActive.day}/${lastActive.month}/${lastActive.year}';
}

String formatCallDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
