import 'package:college_reality_india/config/router/route_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteNames.safeReturnPath', () {
    test('allows in-app write-review return paths and preserves name', () {
      final withEncoded =
          '/college-details/abc123/write-review?name=${Uri.encodeComponent('IIT Bombay')}';
      final withSpace =
          '/college-details/abc123/write-review?name=IIT Bombay';

      void expectName(String? result) {
        expect(result, isNotNull);
        final uri = Uri.parse(result!);
        expect(uri.path, '/college-details/abc123/write-review');
        expect(uri.queryParameters['name'], 'IIT Bombay');
      }

      expectName(RouteNames.safeReturnPath(withEncoded));
      expectName(RouteNames.safeReturnPath(withSpace));
    });

    test('rejects absolute and auth loop targets', () {
      expect(RouteNames.safeReturnPath('https://evil.example/phish'), isNull);
      expect(RouteNames.safeReturnPath('//evil.example'), isNull);
      expect(RouteNames.safeReturnPath('/login'), isNull);
      expect(RouteNames.safeReturnPath('/login?from=/home'), isNull);
      expect(RouteNames.safeReturnPath('/signup'), isNull);
      expect(RouteNames.safeReturnPath('/admin/login'), isNull);
      expect(RouteNames.safeReturnPath(null), isNull);
      expect(RouteNames.safeReturnPath(''), isNull);
    });

    test('loginWithReturn encodes from query', () {
      final login = RouteNames.loginWithReturn(
        '/college-details/x/write-review?name=Test',
      );
      final uri = Uri.parse(login);
      expect(uri.path, RouteNames.login);
      expect(
        uri.queryParameters['from'],
        '/college-details/x/write-review?name=Test',
      );
      final returned =
          RouteNames.safeReturnPath(uri.queryParameters['from']);
      expect(returned, isNotNull);
      expect(Uri.parse(returned!).queryParameters['name'], 'Test');
    });
  });
}