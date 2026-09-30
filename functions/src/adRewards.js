'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');
const { db } = require('./admin');
const { dayKeyFor } = require('./freeTrialCallLogic');
const {
  VERIFIER_KEYS_URL,
  parseSsvQuery,
  verifySsvSignature,
  pemForKeyId,
  decideReward,
} = require('./adRewardLogic');

// Google's SSV public keys, cached (they rotate rarely; refetch on miss).
let cachedKeys = null;
let cachedAt = 0;
const KEYS_TTL_MS = 12 * 60 * 60 * 1000;

async function verifierKeys(forceRefresh = false) {
  if (!forceRefresh && cachedKeys && Date.now() - cachedAt < KEYS_TTL_MS) {
    return cachedKeys;
  }
  const res = await fetch(VERIFIER_KEYS_URL);
  if (!res.ok) throw new Error(`verifier keys HTTP ${res.status}`);
  cachedKeys = await res.json();
  cachedAt = Date.now();
  return cachedKeys;
}

/**
 * AdMob rewarded-ad server-side verification (SSV) callback. Configure its
 * URL on the REWARDED ad unit in the AdMob console (Ad unit -> Server-side
 * verification). Google's official TEST ad units cannot be configured, so
 * dev builds show the ad but never credit -- by design.
 *
 * Only a Google-signed callback credits the wallet: +REWARD_PAISE to
 * wallets/{user_id}, once per transaction_id, at most DAILY_CAP a day.
 * Always 200 after a valid signature (AdMob retries non-2xx), 4xx if not.
 */
const admobRewardCallback = onRequest(async (req, res) => {
  res.set('Cache-Control', 'no-store');
  if (req.method !== 'GET') {
    res.status(405).send('Method not allowed');
    return;
  }

  // Must be the RAW query string: the signature covers its exact bytes.
  const rawQuery = (req.originalUrl || req.url || '').split('?')[1] || '';
  const parsed = parseSsvQuery(rawQuery);
  if (!parsed) {
    res.status(400).send('Bad request');
    return;
  }

  let pem;
  try {
    pem = pemForKeyId(await verifierKeys(), parsed.keyId) ||
      pemForKeyId(await verifierKeys(true), parsed.keyId);
  } catch (e) {
    logger.error('[adReward] could not fetch verifier keys', { e: e.message });
    res.status(503).send('Try again'); // AdMob will retry
    return;
  }
  if (!pem || !verifySsvSignature(parsed.message, parsed.signature, pem)) {
    logger.warn('[adReward] invalid signature', { keyId: parsed.keyId });
    res.status(403).send('Invalid signature');
    return;
  }

  const { userId, transactionId, adUnit } = parsed.params;
  const day = dayKeyFor(Date.now());
  const rewardRef = transactionId
    ? db.collection('ad_rewards').doc(transactionId)
    : null;

  try {
    const outcome = await db.runTransaction(async (tx) => {
      const [existing, today, userSnap] = await Promise.all([
        rewardRef ? tx.get(rewardRef) : Promise.resolve(null),
        tx.get(db.collection('ad_rewards')
          .where('uid', '==', userId || '_')
          .where('dayKey', '==', day)),
        userId ? tx.get(db.collection('users').doc(userId)) : Promise.resolve(null),
      ]);
      const decision = decideReward({
        userId: userSnap && userSnap.exists ? userId : '',
        transactionId,
        alreadyProcessed: !!(existing && existing.exists),
        rewardsToday: today.size,
      });
      if (!decision.credit) return decision;

      const walletRef = db.collection('wallets').doc(userId);
      const walletSnap = await tx.get(walletRef);
      const balance = (walletSnap.exists && walletSnap.data().balancePaise) || 0;
      const balanceAfter = balance + decision.amountPaise;
      const at = new Date().toISOString();

      tx.set(rewardRef, {
        uid: userId,
        amountPaise: decision.amountPaise,
        dayKey: day,
        adUnit,
        createdAt: at,
      });
      tx.set(walletRef, { balancePaise: balanceAfter, updatedAt: at }, { merge: true });
      tx.set(db.collection('wallet_transactions').doc(`adreward_${transactionId}`), {
        uid: userId,
        type: 'ad_reward',
        amountPaise: decision.amountPaise,
        balanceAfterPaise: balanceAfter,
        adTransactionId: transactionId,
        createdAt: at,
      });
      return decision;
    });
    logger.info('[adReward] processed', { userId, transactionId, outcome });
    res.status(200).send('ok');
  } catch (e) {
    logger.error('[adReward] credit failed', { userId, transactionId, e: e.message });
    res.status(500).send('Error'); // retried by AdMob; idempotent by transactionId
  }
});

module.exports = { admobRewardCallback };
