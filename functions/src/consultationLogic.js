'use strict';

const crypto = require('crypto');

// Keep in sync with lib/core/constants/consultation_constants.dart —
// this is the ONE place platform fee % is actually enforced; the Dart
// constant is display-estimate only.
const PLATFORM_FEE_PERCENT = 20;

const CONSULTATION_STATUS = {
  REQUESTED: 'requested',
  PAYMENT_PENDING: 'payment_pending',
  PAID: 'paid',
  WAITING_FOR_GUIDE: 'waiting_for_guide',
  ACTIVE: 'active',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
  EXPIRED: 'expired',
};

const PAYMENT_STATUS = {
  PENDING: 'pending',
  SUCCESS: 'success',
  FAILED: 'failed',
  REFUNDED: 'refunded',
  CANCELLED: 'cancelled',
};

/**
 * Splits a gross paise amount into platform fee + guide amount. Always
 * paise-integer, never float — this is the one function every money split
 * in the backend must go through.
 */
function splitConsultationAmount(grossPaise) {
  if (!Number.isInteger(grossPaise) || grossPaise <= 0) {
    throw new Error(`Invalid grossPaise: ${grossPaise}`);
  }
  const platformFeePaise = Math.round((grossPaise * PLATFORM_FEE_PERCENT) / 100);
  const guideAmountPaise = grossPaise - platformFeePaise;
  return { platformFeePaise, guideAmountPaise };
}

/**
 * Resolves a guide's currently published price for a given consultation
 * type/duration from their communicationSettings — the server's source of
 * truth for "how much should this cost", never the client's number.
 * Returns null if the guide doesn't offer that exact option.
 */
function resolveGuidePriceForConsultation({ settings, type, durationMinutes }) {
  if (type === 'chat') {
    if (!settings || !settings.chatAvailable) return null;
    if (settings.chatDurationMinutes !== durationMinutes) return null;
    return settings.chatPricePaise > 0 ? settings.chatPricePaise : null;
  }
  if (!settings || !settings.callAvailable) return null;
  const options = Array.isArray(settings.callPricing) ? settings.callPricing : [];
  const match = options.find(
    (o) => o && o.type === type && o.minutes === durationMinutes,
  );
  return match && match.pricePaise > 0 ? match.pricePaise : null;
}

/** Razorpay checkout-success signature (order_id|payment_id, HMAC-SHA256). */
function verifyCheckoutSignature({ orderId, paymentId, signature, secret }) {
  const expected = crypto
    .createHmac('sha256', secret)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');
  return timingSafeEqualHex(expected, signature);
}

/** Razorpay webhook signature (raw request body, HMAC-SHA256). */
function verifyWebhookSignature({ rawBody, signature, secret }) {
  const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
  return timingSafeEqualHex(expected, signature);
}

function timingSafeEqualHex(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length) {
    return false;
  }
  try {
    return crypto.timingSafeEqual(Buffer.from(a, 'hex'), Buffer.from(b, 'hex'));
  } catch {
    return false;
  }
}

module.exports = {
  PLATFORM_FEE_PERCENT,
  CONSULTATION_STATUS,
  PAYMENT_STATUS,
  splitConsultationAmount,
  resolveGuidePriceForConsultation,
  verifyCheckoutSignature,
  verifyWebhookSignature,
};
