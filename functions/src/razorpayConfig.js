'use strict';

const { logger } = require('firebase-functions');
const { db } = require('./admin');
const { RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET } = require('./params');
const { assertConfigured } = require('./util/guards');
const { PAYMENT_SETTINGS_DOC, resolveRazorpayKeyId } = require('./paymentSettingsLogic');

/**
 * The Razorpay key pair every server call uses: Key ID from
 * `app_config/payment_settings` (Super Admin panel) falling back to the
 * RAZORPAY_KEY_ID secret; Key Secret always from Secret Manager.
 * Callers must declare both secrets on their function.
 */
async function razorpayCredentials() {
  let settings = null;
  try {
    const snap = await db.collection('app_config').doc(PAYMENT_SETTINGS_DOC).get();
    settings = snap.exists ? snap.data() : null;
  } catch (e) {
    // Settings unreadable -> deployed secret, never a hard failure.
    logger.warn('payment_settings read failed; using RAZORPAY_KEY_ID secret', e);
  }
  return {
    keyId: assertConfigured(resolveRazorpayKeyId(settings, RAZORPAY_KEY_ID.value()), 'Payments'),
    keySecret: assertConfigured(RAZORPAY_KEY_SECRET.value(), 'Payments'),
  };
}

/** Razorpay API client + the Key ID the app must open checkout with. */
async function razorpayClient() {
  const { keyId, keySecret } = await razorpayCredentials();
  const Razorpay = require('razorpay'); // lazy: only payment handlers need it
  return { razorpay: new Razorpay({ key_id: keyId, key_secret: keySecret }), keyId };
}

module.exports = { razorpayCredentials, razorpayClient };
