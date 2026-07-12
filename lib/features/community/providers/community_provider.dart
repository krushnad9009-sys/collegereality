import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/community_constants.dart';
import '../../auth/providers/user_provider.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';
import '../models/user_presence_model.dart';
import '../services/community_firestore_service.dart';

final communityServiceProvider = Provider<CommunityFirestoreService>((ref) {
  return CommunityFirestoreService();
});

final privateConversationsProvider =
    StreamProvider<List<ChatConversationModel>>((ref) {
  final user = ref.watch(currentUserDetailProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(communityServiceProvider).watchPrivateConversations(user.uid);
});

final conversationProvider =
    StreamProvider.family<ChatConversationModel?, String>((ref, id) {
  return ref.watch(communityServiceProvider).watchConversation(id);
});

final messagesProvider =
    StreamProvider.family<List<ChatMessageModel>, String>((ref, conversationId) {
  return ref.watch(communityServiceProvider).watchMessages(conversationId);
});

final askSeniorsThreadsProvider =
    StreamProvider<List<ChatConversationModel>>((ref) {
  final user = ref.watch(currentUserDetailProvider).valueOrNull;
  if (user?.collegeId == null) return Stream.value([]);
  return ref.watch(communityServiceProvider).watchThreads(
        type: CommunityConstants.typeAskSeniors,
        collegeId: user!.collegeId,
      );
});

final qaThreadsProvider = StreamProvider<List<ChatConversationModel>>((ref) {
  final user = ref.watch(currentUserDetailProvider).valueOrNull;
  if (user?.collegeId == null) return Stream.value([]);
  return ref.watch(communityServiceProvider).watchThreads(
        type: CommunityConstants.typeQa,
        collegeId: user!.collegeId,
      );
});

final presenceProvider =
    StreamProvider.family<UserPresenceModel?, String>((ref, userId) {
  return ref.watch(communityServiceProvider).watchPresence(userId);
});

final communityReportsAdminProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(communityServiceProvider).getOpenCommunityReports();
});
