import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/community_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/profile_constants.dart';
import '../../../core/constants/social_constants.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/firestore_user_service.dart';
import '../../communication/services/communication_firestore_service.dart';
import '../../engagement/services/firestore_engagement_service.dart';
import '../../social/models/social_models.dart';
import '../../social/services/moderation_service.dart';
import '../../social/services/notification_bridge_service.dart';
import '../../social/utils/content_filter_utils.dart';
import '../../social/utils/moderation_utils.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';
import '../models/user_presence_model.dart';
import 'community_storage_service.dart';

class CommunityFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _userService = FirestoreUserService();
  final _communicationService = CommunicationFirestoreService();
  final _storageService = CommunityStorageService();
  final _moderationService = ModerationService();
  final _notificationBridge =
      NotificationBridgeService(FirestoreEngagementService());

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection(FirestoreConstants.communityConversationsCollection);

  CollectionReference<Map<String, dynamic>> get _messages =>
      _firestore.collection(FirestoreConstants.communityMessagesCollection);

  Future<void> updatePresence(String userId, {required bool isOnline}) async {
    final doc =
        await _firestore.collection(FirestoreConstants.usersCollection).doc(userId).get();
    final existingPresence = doc.data()?['presence'] as Map<String, dynamic>?;
    final availabilityStatus =
        existingPresence?['availabilityStatus'] as String? ??
            ProfileConstants.availabilityOffline;

    await _firestore.collection(FirestoreConstants.usersCollection).doc(userId).update({
      'presence': {
        'isOnline': isOnline,
        'lastSeenAt': DateTime.now().toIso8601String(),
        'availabilityStatus': availabilityStatus,
      },
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<UserPresenceModel?> getPresence(String userId) async {
    final user = await _userService.getUserByUID(userId);
    if (user == null) return null;
    return user.presence;
  }

  Stream<UserPresenceModel?> watchPresence(String userId) {
    return _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()?['presence'] as Map<String, dynamic>?;
      return UserPresenceModel.fromJson(data);
    });
  }

  Future<List<String>> _blockedIds(String userId) async {
    return _communicationService.getBlockedUserIds(userId);
  }

  Future<bool> _isBlockedEitherWay(String a, String b) async {
    return await _communicationService.isBlocked(a, b) ||
        await _communicationService.isBlocked(b, a);
  }

  Future<ChatConversationModel> getOrCreateRoom({
    required String type,
    required UserModel user,
    String? course,
  }) async {
    if (type == CommunityConstants.typeCollege ||
        type == CommunityConstants.typeBranch) {
      if (user.collegeId == null) {
        throw CommunityException('Set your college in profile first.');
      }
    }
    if (type == CommunityConstants.typeBranch &&
        (course ?? user.course)?.isEmpty != false) {
      throw CommunityException('Set your course in profile for branch chat.');
    }

    Query<Map<String, dynamic>> query = _conversations.where('type', isEqualTo: type);
    if (type == CommunityConstants.typeCollege) {
      query = query.where('collegeId', isEqualTo: user.collegeId);
    } else if (type == CommunityConstants.typeBranch) {
      query = query
          .where('collegeId', isEqualTo: user.collegeId)
          .where('course', isEqualTo: course ?? user.course);
    }

    final existing = await query.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return ChatConversationModel.fromJson(existing.docs.first.data(),
          docId: existing.docs.first.id);
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final conversation = ChatConversationModel(
      id: id,
      type: type,
      collegeId: user.collegeId,
      collegeName: user.collegeName,
      course: type == CommunityConstants.typeBranch ? (course ?? user.course) : null,
      title: CommunityConstants.roomTitle(type),
      createdAt: now,
      updatedAt: now,
    );
    await _conversations.doc(id).set(conversation.toJson());
    return conversation;
  }

  Future<ChatConversationModel> getOrCreatePrivateChat({
    required UserModel currentUser,
    required String peerId,
    required String peerName,
  }) async {
    if (await _isBlockedEitherWay(currentUser.uid, peerId)) {
      throw CommunityException('Unable to chat with this student.');
    }

    final ids = [currentUser.uid, peerId]..sort();
    final snapshot = await _conversations
        .where('type', isEqualTo: CommunityConstants.typePrivate)
        .where('participantIds', isEqualTo: ids)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ChatConversationModel.fromJson(snapshot.docs.first.data(),
          docId: snapshot.docs.first.id);
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final conversation = ChatConversationModel(
      id: id,
      type: CommunityConstants.typePrivate,
      participantIds: ids,
      participantNames: {
        currentUser.uid: currentUser.displayName ?? 'Student',
        peerId: peerName,
      },
      createdAt: now,
      updatedAt: now,
    );
    await _conversations.doc(id).set(conversation.toJson());
    return conversation;
  }

  Future<ChatConversationModel> createThread({
    required UserModel user,
    required String type,
    required String title,
    required String initialMessage,
  }) async {
    if (user.collegeId == null) {
      throw CommunityException('Set your college in profile first.');
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final conversation = ChatConversationModel(
      id: id,
      type: type,
      collegeId: user.collegeId,
      collegeName: user.collegeName,
      course: user.course,
      title: title,
      authorId: user.uid,
      lastMessageText: initialMessage,
      lastMessageSenderId: user.uid,
      lastMessageAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await _conversations.doc(id).set(conversation.toJson());

    await sendMessage(
      conversationId: id,
      sender: user,
      text: initialMessage,
      messageType: CommunityConstants.messageText,
    );
    return conversation;
  }

  Stream<List<ChatConversationModel>> watchPrivateConversations(String userId) {
    return _conversations
        .where('type', isEqualTo: CommunityConstants.typePrivate)
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final blocked = await _blockedIds(userId);
      return snapshot.docs
          .map((d) => ChatConversationModel.fromJson(d.data(), docId: d.id))
          .where((c) {
        final peer = c.peerIdFor(userId);
        return peer == null || !blocked.contains(peer);
      }).toList();
    });
  }

  Stream<List<ChatConversationModel>> watchThreads({
    required String type,
    String? collegeId,
  }) {
    Query<Map<String, dynamic>> query =
        _conversations.where('type', isEqualTo: type);
    if (collegeId != null) {
      query = query.where('collegeId', isEqualTo: collegeId);
    }
    return query
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => ChatConversationModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Stream<ChatConversationModel?> watchConversation(String conversationId) {
    return _conversations.doc(conversationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatConversationModel.fromJson(doc.data()!, docId: doc.id);
    });
  }

  Stream<List<ChatMessageModel>> watchMessages(String conversationId) {
    return _messages
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => ChatMessageModel.fromJson(d.data(), docId: d.id))
            .where((m) => m.status != SocialConstants.contentStatusHidden)
            .toList());
  }

  Future<SocialPageResult<ChatMessageModel>> fetchMessagesPage({
    required String conversationId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = SocialConstants.defaultPageSize,
  }) async {
    Query<Map<String, dynamic>> query = _messages
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    final items = snap.docs
        .map((d) => ChatMessageModel.fromJson(d.data(), docId: d.id))
        .where((m) => m.status != SocialConstants.contentStatusHidden)
        .toList();
    return SocialPageResult(
      items: items,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<void> setTyping({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    final ref = _conversations.doc(conversationId);
    if (isTyping) {
      await ref.update({
        'typingUsers.$userId': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } else {
      await ref.update({
        'typingUsers.$userId': FieldValue.delete(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required UserModel sender,
    required String text,
    required String messageType,
    Uint8List? attachmentBytes,
    String? attachmentName,
    String? replyToMessageId,
  }) async {
    final conversationDoc = await _conversations.doc(conversationId).get();
    if (!conversationDoc.exists) {
      throw CommunityException('Conversation not found.');
    }
    final conversation = ChatConversationModel.fromJson(
      conversationDoc.data()!,
      docId: conversationDoc.id,
    );

    if (conversation.type == CommunityConstants.typePrivate) {
      final peer = conversation.peerIdFor(sender.uid);
      if (peer != null && await _isBlockedEitherWay(sender.uid, peer)) {
        throw CommunityException('Unable to send message.');
      }
    }

    final sanitizedText = sanitizeUserContent(text);
    if (messageType == CommunityConstants.messageText && sanitizedText.isNotEmpty) {
      final moderation = moderateContent(sanitizedText);
      if (!moderation.allowed) {
        throw CommunityException(
          moderation.reason == 'spam'
              ? 'Message blocked: possible spam detected.'
              : 'Message blocked: inappropriate content.',
        );
      }
    }

    final messageId = _uuid.v4();
    String? attachmentUrl;
    if (attachmentBytes != null && attachmentName != null) {
      final ext = attachmentName.split('.').last.toLowerCase();
      attachmentUrl = await _storageService.uploadAttachment(
        conversationId: conversationId,
        userId: sender.uid,
        messageId: messageId,
        extension: ext,
        bytes: attachmentBytes,
      );
    }

    final message = ChatMessageModel(
      id: messageId,
      conversationId: conversationId,
      senderId: sender.uid,
      senderName: sender.displayName ?? 'Student',
      senderPhoto: sender.photoURL,
      messageType: messageType,
      text: sanitizedText.isNotEmpty ? sanitizedText : text,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      replyToMessageId: replyToMessageId,
      readBy: [sender.uid],
      status: SocialConstants.contentStatusVisible,
      createdAt: DateTime.now(),
    );

    await _messages.doc(messageId).set(message.toJson());

    final preview = _previewText(message);
    await _conversations.doc(conversationId).update({
      'lastMessageText': preview,
      'lastMessageSenderId': sender.uid,
      'lastMessageAt': message.createdAt.toIso8601String(),
      'updatedAt': message.createdAt.toIso8601String(),
      'typingUsers.$sender.uid': FieldValue.delete(),
      if (replyToMessageId != null) 'replyCount': FieldValue.increment(1),
    });

    if (conversation.type == CommunityConstants.typePrivate) {
      final peer = conversation.peerIdFor(sender.uid);
      if (peer != null) {
        await _notificationBridge.notifyChatMessage(
          recipientId: peer,
          senderName: sender.displayName ?? 'Student',
          conversationId: conversationId,
          preview: preview,
        );
      }
    }

    return message;
  }

  String _previewText(ChatMessageModel message) {
    switch (message.messageType) {
      case CommunityConstants.messageImage:
        return '📷 Photo';
      case CommunityConstants.messagePdf:
        return '📄 ${message.attachmentName ?? 'PDF'}';
      case CommunityConstants.messageEmoji:
        return message.text;
      default:
        return message.text;
    }
  }

  Future<void> markConversationRead({
    required String conversationId,
    required String userId,
    required String lastMessageId,
  }) async {
    await _conversations.doc(conversationId).update({
      'readReceipts.$userId': lastMessageId,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final allMessages = await _messages
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final batch = _firestore.batch();
    for (final doc in allMessages.docs) {
      final data = doc.data();
      final readBy = (data['readBy'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      if (!readBy.contains(userId)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
    await batch.commit();
  }

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) =>
      _communicationService.blockUser(blockerId: blockerId, blockedId: blockedId);

  Future<void> reportContent({
    required String reporterId,
    required String reportedId,
    required String reason,
    String details = '',
    String? conversationId,
    String? messageId,
  }) async {
    await _communicationService.reportUser(
      reporterId: reporterId,
      reportedId: reportedId,
      reason: reason,
      details: details,
      sessionId: conversationId,
    );
    if (messageId != null) {
      await _firestore.collection(FirestoreConstants.communityReportsCollection).add({
        'reporterId': reporterId,
        'reportedId': reportedId,
        'conversationId': conversationId,
        'messageId': messageId,
        'reason': reason,
        'details': details,
        'status': CommunityConstants.reportStatusOpen,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await _moderationService.incrementMessageReportCount(messageId);
    }
  }

  Future<void> likeMessage({
    required String messageId,
    required String userId,
  }) async {
    final ref = _messages.doc(messageId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final likedBy = (snap.data()?['likedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (likedBy.contains(userId)) return;
      likedBy.add(userId);
      tx.update(ref, {
        'likedBy': likedBy,
        'likeCount': likedBy.length,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<List<Map<String, dynamic>>> getOpenCommunityReports({int limit = 100}) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.communityReportsCollection)
        .where('status', isEqualTo: CommunityConstants.reportStatusOpen)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<void> updateCommunityReportStatus(String reportId, String status) async {
    await _firestore
        .collection(FirestoreConstants.communityReportsCollection)
        .doc(reportId)
        .update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteMessage(String messageId) async {
    await _messages.doc(messageId).delete();
  }
}

class CommunityException implements Exception {
  final String message;
  CommunityException(this.message);
  @override
  String toString() => message;
}
