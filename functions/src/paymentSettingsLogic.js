'use strict';

// Super Admin-managed payment settings (`app_config/payment_settings`).
// Pure rules only -- razorpayConfig.js does the Firestore read.
//
// Only the PUBLIC Key ID is admin-editable. The Key Secret stays in Secret
// Manager (RAZORPAY_KEY_SECRET) and is never stored in Firestore; the two
// must belong to the same Razorpay key pair, so switching to a different
// key means updating the secret too (still no app release needed).

const PAYMENT_SETTINGS_DOC = 'payment_settings';

// Razorpay key ids look like rzp_test_XXXXXXXXXXXXXX / rzp_live_XXXXXXXXXXXXXX.
// Keep in sync with firestore.rules (isValidPaymentSettings) and
// lib/core/payments/payment_settings.dart.
const RAZORPAY_KEY_ID_PATTERN = /^rzp_(test|live)_[A-Za-z0-9]{8,32}$/;

function isValidRazorpayKeyId(value) {
  return typeof value === 'string' && RAZORPAY_KEY_ID_PATTERN.test(value);
}

/**
 * Key ID to use for both the server API client and the app's checkout
 * (they MUST be the same, or Razorpay rejects the order in checkout).
 * Admin value wins when it is well-formed; otherwise the deployed secret.
 */
function resolveRazorpayKeyId(settings, secretKeyId) {
  const fromAdmin = settings && typeof settings.razorpayKeyId === 'string'
    ? settings.razorpayKeyId.trim()
    : '';
  if (isValidRazorpayKeyId(fromAdmin)) return fromAdmin;
  return secretKeyId || '';
}

module.exports = {
  PAYMENT_SETTINGS_DOC,
  isValidRazorpayKeyId,
  resolveRazorpayKeyId,
};
