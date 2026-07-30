import 'package:college_reality_india/config/router/route_names.dart';
import 'package:college_reality_india/features/engagement/utils/fcm_action_route_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isAllowedFcmActionRoute', () {
    test('allows known in-app routes', () {
      expect(isAllowedFcmActionRoute(RouteNames.notifications), isTrue);
      expect(isAllowedFcmActionRoute('/college-details/abc'), isTrue);
      expect(isAllowedFcmActionRoute('/guides/uid123'), isTrue);
      expect(isAllowedFcmActionRoute('/community/chat/room1'), isTrue);
    });

    test('rejects admin and external routes', () {
      expect(isAllowedFcmActionRoute('/admin'), isFalse);
      expect(isAllowedFcmActionRoute('/admin/users'), isFalse);
      expect(isAllowedFcmActionRoute('https://evil.example'), isFalse);
      expect(isAllowedFcmActionRoute('../etc/passwd'), isFalse);
      expect(isAllowedFcmActionRoute(''), isFalse);
    });
  });
}