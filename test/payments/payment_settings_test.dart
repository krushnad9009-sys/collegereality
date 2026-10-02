import 'package:college_reality_india/core/payments/payment_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentSettings.isValidKeyIdOrEmpty', () {
    test('accepts empty, test and live key ids', () {
      expect(PaymentSettings.isValidKeyIdOrEmpty(''), isTrue);
      expect(PaymentSettings.isValidKeyIdOrEmpty('rzp_test_1DP5mmOlF5G5ag'),
          isTrue);
      expect(PaymentSettings.isValidKeyIdOrEmpty('rzp_live_AbCdEf1234567890'),
          isTrue);
    });

    test('rejects malformed values', () {
      expect(PaymentSettings.isValidKeyIdOrEmpty('rzp_prod_1DP5mmOlF5G5ag'),
          isFalse);
      expect(PaymentSettings.isValidKeyIdOrEmpty('rzp_test_short'), isFalse);
      expect(PaymentSettings.isValidKeyIdOrEmpty('some-secret-value'), isFalse);
    });
  });

  test('fromJson tolerates a missing doc and trims the key', () {
    expect(PaymentSettings.fromJson(null).razorpayKeyId, '');
    final s = PaymentSettings.fromJson(
        {'razorpayKeyId': ' rzp_live_AbCdEf1234567890 '});
    expect(s.razorpayKeyId, 'rzp_live_AbCdEf1234567890');
    expect(s.isLiveKey, isTrue);
    expect(s.isTestKey, isFalse);
  });
}
