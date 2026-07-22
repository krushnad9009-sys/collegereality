import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:college_reality_india/core/constants/engagement_constants.dart';
import 'package:college_reality_india/core/constants/social_constants.dart';
import 'package:college_reality_india/features/community/models/chat_message_model.dart';
import 'package:college_reality_india/features/community/services/message_cache_service.dart';
import 'package:college_reality_india/features/engagement/models/engagement_models.dart';
import 'package:college_reality_india/features/engagement/utils/alert_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification preferences', () {
    test('new notification types respect toggles', () {
      final prefs = NotificationPreferencesModel.defaults('u1').copyWith(
        verificationUpdates: false,
        communityUpdates: false,
        adminAnnouncements: false,
        reviewApproved: false,
      );

      expect(
        isPreferenceEnabled(prefs, EngagementConstants.typeVerificationUpdate),
        isFalse,
      );
      expect(
        isPreferenceEnabled(prefs, EngagementConstants.typeCommunityPost),
        isFalse,
      );
      expect(
        isPreferenceEnabled(prefs, EngagementConstants.typeAdminAnnouncement),
        isFalse,
      );
      expect(
        isPreferenceEnabled(prefs, EngagementConstants.typeReviewApproved),
        isFalse,
      );
      expect(
        isPreferenceEnabled(prefs, EngagementConstants.typeReviewComment),
        isTrue,
      );
    });
  });

  group('MessageCacheService', () {
    test('round-trips chat messages', () async {
      SharedPreferences.setMockInitialValues({});
      const conversationId = 'conv_test_1';
      final messages = [
        ChatMessageModel(
          id: 'm1',
          conversationId: conversationId,
          senderId: 'u1',
          senderName: 'A',
          text: 'Hello',
          createdAt: DateTime(2026, 7, 13),
        ),
      ];

      await MessageCacheService.saveMessages(conversationId, messages);
      final loaded = await MessageCacheService.loadMessages(conversationId);
      expect(loaded.length, 1);
      expect(loaded.first.text, 'Hello');
    });
  });

  group('Chat rate limit constant', () {
    test('max messages per minute is configured', () {
      expect(SocialConstants.maxMessagesPerMinute, greaterThan(0));
    });
  });
}
