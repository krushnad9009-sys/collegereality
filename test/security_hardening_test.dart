import 'package:college_reality_india/core/utils/safe_launch.dart';
import 'package:college_reality_india/features/social/utils/content_filter_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeUserContent', () {
    test('strips bidi overrides, zero-width and control characters', () {
      expect(sanitizeUserContent('evil\u202Eexe.txt'), 'evilexe.txt');
      expect(sanitizeUserContent('pay\u200Bpal'), 'paypal');
      expect(sanitizeUserContent('a\u0000b\u0007c'), 'abc');
      expect(sanitizeUserContent('\uFEFFhello'), 'hello');
    });

    test('keeps normal text, emoji and Indian scripts', () {
      expect(sanitizeUserContent('  Hi 👋  कैसे   हो? '), 'Hi 👋 कैसे हो?');
    });

    test('caps length', () {
      expect(sanitizeUserContent('x' * 5000).length, 2000);
    });
  });

  group('isSafeWebUrl', () {
    test('allows http(s) links', () {
      expect(isSafeWebUrl('https://example.com/cert.pdf'), isTrue);
      expect(isSafeWebUrl(' http://example.com '), isTrue);
    });

    test('blocks app/intent/script/file schemes and junk', () {
      for (final bad in [
        'intent://scan/#Intent;scheme=zxing;end',
        'javascript:alert(1)',
        'file:///sdcard/secret.pdf',
        'content://com.android.providers/1',
        'market://details?id=x',
        'tel:123',
        '/relative/path',
        'https://',
        '',
      ]) {
        expect(isSafeWebUrl(bad), isFalse, reason: bad);
      }
    });
  });
}
