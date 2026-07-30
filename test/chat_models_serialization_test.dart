import 'package:college_reality_india/core/constants/community_constants.dart';
import 'package:college_reality_india/features/community/models/chat_conversation_model.dart';
import 'package:college_reality_india/features/community/models/chat_message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  test('ChatConversationModel JSON and display helpers', () {
    final privateChat = ChatConversationModel(
      id: 'cv1',
      type: CommunityConstants.typePrivate,
      participantIds: const ['u1', 'u2'],
      participantNames: const {'u1': 'Ada', 'u2': 'Bob'},
      lastMessageText: 'hi',
      lastMessageAt: now,
      createdAt: now,
      updatedAt: now,
    );
    expect(privateChat.displayTitle('u1'), 'Bob');
    expect(privateChat.peerIdFor('u1'), 'u2');
    expect(privateChat.peerIdFor('u2'), 'u1');
    expect(
      ChatConversationModel(
        id: 'solo',
        type: CommunityConstants.typePrivate,
        participantIds: const ['u1'],
        createdAt: now,
        updatedAt: now,
      ).peerIdFor('u1'),
      isNull,
    );
    final restored = ChatConversationModel.fromJson(privateChat.toJson(), docId: 'cv1');
    expect(restored.participantIds, ['u1', 'u2']);

    final room = ChatConversationModel(
      id: 'cv2',
      type: CommunityConstants.typeCollege,
      collegeName: 'COEP',
      course: 'CSE',
      title: '',
      createdAt: now,
      updatedAt: now,
    );
    expect(room.displayTitle('u1'), contains('COEP'));
    expect(room.peerIdFor('u1'), isNull);

    final named = ChatConversationModel(
      id: 'cv3',
      type: CommunityConstants.typeCollege,
      title: 'Custom',
      createdAt: now,
      updatedAt: now,
    );
    expect(named.displayTitle('u1'), 'Custom');

    final collegeOnly = ChatConversationModel(
      id: 'cv4',
      type: CommunityConstants.typeCollege,
      collegeName: 'COEP',
      createdAt: now,
      updatedAt: now,
    );
    expect(collegeOnly.displayTitle('u1'), contains('COEP'));

    final bare = ChatConversationModel.fromJson({}, docId: 'x');
    expect(bare.id, 'x');
  });

  test('ChatMessageModel JSON and isReadBy', () {
    final msg = ChatMessageModel(
      id: 'm1',
      conversationId: 'cv1',
      senderId: 'u1',
      senderName: 'Ada',
      text: 'Hello',
      readBy: const ['u2'],
      likeCount: 2,
      likedBy: const ['u2', 'u3'],
      createdAt: now,
    );
    expect(msg.isReadBy('u2'), isTrue);
    expect(msg.isReadBy('u1'), isFalse);
    final restored = ChatMessageModel.fromJson(msg.toJson(), docId: 'm1');
    expect(restored.text, 'Hello');
    expect(ChatMessageModel.fromJson({}).senderName, 'Student');
  });
}