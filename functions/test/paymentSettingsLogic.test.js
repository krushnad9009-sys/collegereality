'use strict';

const {
  isValidRazorpayKeyId,
  resolveRazorpayKeyId,
} = require('../src/paymentSettingsLogic');

describe('isValidRazorpayKeyId', () => {
  test('accepts test and live key ids', () => {
    expect(isValidRazorpayKeyId('rzp_test_1DP5mmOlF5G5ag')).toBe(true);
    expect(isValidRazorpayKeyId('rzp_live_AbCdEf1234567890')).toBe(true);
  });

  test('rejects secrets, junk and non-strings', () => {
    expect(isValidRazorpayKeyId('')).toBe(false);
    expect(isValidRazorpayKeyId('rzp_prod_1DP5mmOlF5G5ag')).toBe(false);
    expect(isValidRazorpayKeyId('rzp_test_short')).toBe(false);
    expect(isValidRazorpayKeyId('rzp_test_1DP5mmOlF5G5ag ')).toBe(false);
    expect(isValidRazorpayKeyId('rzp_test_abc-def-ghij')).toBe(false);
    expect(isValidRazorpayKeyId(null)).toBe(false);
    expect(isValidRazorpayKeyId(123)).toBe(false);
  });
});

describe('resolveRazorpayKeyId', () => {
  const SECRET = 'rzp_test_FromSecretManager1';

  test('admin key id wins when well-formed (trimmed)', () => {
    expect(resolveRazorpayKeyId({ razorpayKeyId: ' rzp_live_AdminKey123456 ' }, SECRET))
      .toBe('rzp_live_AdminKey123456');
  });

  test('falls back to the deployed secret', () => {
    expect(resolveRazorpayKeyId(null, SECRET)).toBe(SECRET);
    expect(resolveRazorpayKeyId({}, SECRET)).toBe(SECRET);
    expect(resolveRazorpayKeyId({ razorpayKeyId: '' }, SECRET)).toBe(SECRET);
    expect(resolveRazorpayKeyId({ razorpayKeyId: 'garbage' }, SECRET)).toBe(SECRET);
  });

  test('empty when nothing is configured', () => {
    expect(resolveRazorpayKeyId(null, undefined)).toBe('');
  });
});
