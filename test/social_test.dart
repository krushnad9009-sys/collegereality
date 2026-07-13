import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/communication_constants.dart';
import 'package:college_reality_india/features/social/utils/content_filter_utils.dart';
import 'package:college_reality_india/features/social/utils/moderation_utils.dart';

void main() {
  group('ModerationUtils', () {
    test('isLikelySpam detects repeated links', () {
      expect(
        isLikelySpam('Check http://a.com http://b.com http://c.com now'),
        isTrue,
      );
    });

    test('isLikelySpam rejects empty content', () {
      expect(isLikelySpam(''), isTrue);
      expect(isLikelySpam('  '), isTrue);
    });

    test('containsOffensiveContent detects blocked terms', () {
      expect(containsOffensiveContent('This is a scam offer'), isTrue);
      expect(containsOffensiveContent('Great college experience'), isFalse);
    });

    test('moderateContent blocks spam and offensive text', () {
      expect(moderateContent('aaaaaaaaaaaaaa').allowed, isFalse);
      expect(moderateContent('Nice campus and good faculty').allowed, isTrue);
      expect(moderateContent('You are stupid').allowed, isFalse);
    });

    test('shouldAutoHide uses spam report threshold', () {
      expect(shouldAutoHide(CommunicationConstants.spamReportThreshold - 1), isFalse);
      expect(shouldAutoHide(CommunicationConstants.spamReportThreshold), isTrue);
      expect(shouldAutoHide(CommunicationConstants.spamReportThreshold + 1), isTrue);
    });
  });

  group('ContentFilterUtils', () {
    test('sanitizeUserContent trims and collapses whitespace', () {
      expect(sanitizeUserContent('  hello   world  '), 'hello world');
    });

    test('sanitizeUserContent enforces max length', () {
      final long = 'a' * 50;
      expect(sanitizeUserContent(long, maxLength: 10).length, 10);
    });

    test('buildContentPreview truncates long text', () {
      final preview = buildContentPreview('x' * 200, maxChars: 50);
      expect(preview.length, lessThanOrEqualTo(51));
      expect(preview.endsWith('…'), isTrue);
    });

    test('isEmptyContent detects blank input', () {
      expect(isEmptyContent('   '), isTrue);
      expect(isEmptyContent('Hello'), isFalse);
    });
  });
}
