'use strict';

// Pure rules for crediting the call wallet from a rewarded video ad
// (AdMob server-side verification, SSV). No Firestore / network handles,
// so signature checking and the reward policy are unit-tested
// (test/adRewardLogic.test.js). Wrapper: adRewards.js.
//
// SSV: when a user finishes a rewarded ad, AdMob calls our HTTPS endpoint
// with a query string signed by Google (ECDSA P-256 / SHA-256). The
// signature covers every parameter BEFORE `signature=`; `signature` and
// `key_id` are always the last two. Public keys:
// https://www.gstatic.com/admob/reward/verifier-keys.json
// Docs: https://developers.google.com/admob/android/ssv

const crypto = require('crypto');

// Money policy -- the client only displays these (lib/core/ads/ad_config.dart).
const REWARD_PAISE = 200; // ₹2 per completed video
const DAILY_CAP = 5; // per user per IST day

const VERIFIER_KEYS_URL = 'https://www.gstatic.com/admob/reward/verifier-keys.json';

/**
 * Splits a raw SSV query string into the signed message, the signature and
 * key id, and the decoded parameters. Returns null if malformed.
 */
function parseSsvQuery(rawQuery) {
  if (typeof rawQuery !== 'string') return null;
  const sigIndex = rawQuery.indexOf('&signature=');
  if (sigIndex <= 0) return null;
  const message = rawQuery.slice(0, sigIndex);
  const params = new URLSearchParams(rawQuery);
  const signature = params.get('signature');
  const keyId = params.get('key_id');
  if (!signature || !keyId) return null;
  return {
    message,
    signature,
    keyId,
    params: {
      adUnit: params.get('ad_unit') || '',
      userId: params.get('user_id') || '',
      transactionId: params.get('transaction_id') || '',
      timestampMs: Number(params.get('timestamp')) || 0,
      rewardAmount: Number(params.get('reward_amount')) || 0,
      rewardItem: params.get('reward_item') || '',
    },
  };
}

/** Web-safe base64 (no padding) -> Buffer. */
function decodeWebSafeBase64(value) {
  const std = value.replace(/-/g, '+').replace(/_/g, '/');
  const padded = std + '='.repeat((4 - (std.length % 4)) % 4);
  return Buffer.from(padded, 'base64');
}

/** True iff [signature] (web-safe b64 DER ECDSA) signs [message] with [pem]. */
function verifySsvSignature(message, signature, pem) {
  try {
    return crypto.verify(
      'sha256',
      Buffer.from(message, 'utf8'),
      { key: pem, dsaEncoding: 'der' },
      decodeWebSafeBase64(signature),
    );
  } catch (_) {
    return false;
  }
}

/** Finds the PEM for [keyId] in Google's verifier-keys.json payload. */
function pemForKeyId(keysJson, keyId) {
  const keys = (keysJson && Array.isArray(keysJson.keys)) ? keysJson.keys : [];
  const match = keys.find((k) => String(k.keyId) === String(keyId));
  return match ? match.pem : null;
}

/**
 * Whether a verified callback earns a credit.
 * @returns {{credit: true, amountPaise: number} | {credit: false, reason: string}}
 */
function decideReward({ userId, transactionId, alreadyProcessed, rewardsToday }) {
  if (!userId) return { credit: false, reason: 'no_user' };
  if (!transactionId) return { credit: false, reason: 'no_transaction' };
  if (alreadyProcessed) return { credit: false, reason: 'duplicate' };
  if (rewardsToday >= DAILY_CAP) return { credit: false, reason: 'daily_cap' };
  return { credit: true, amountPaise: REWARD_PAISE };
}

module.exports = {
  REWARD_PAISE,
  DAILY_CAP,
  VERIFIER_KEYS_URL,
  parseSsvQuery,
  decodeWebSafeBase64,
  verifySsvSignature,
  pemForKeyId,
  decideReward,
};
