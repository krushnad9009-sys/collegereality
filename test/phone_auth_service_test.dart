import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/services/phone_auth_service.dart';

void main() {
  group('isLocalWebHostName', () {
    test('detects localhost variants', () {
      expect(isLocalWebHostName('localhost'), isTrue);
      expect(isLocalWebHostName('LOCALHOST'), isTrue);
      expect(isLocalWebHostName('127.0.0.1'), isTrue);
      expect(isLocalWebHostName('[::1]'), isTrue);
    });

    test('returns false for production hosts', () {
      expect(isLocalWebHostName('collegereality.in'), isFalse);
      expect(isLocalWebHostName('app.example.com'), isFalse);
    });
  });
}
