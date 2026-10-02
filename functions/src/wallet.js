'use strict';

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { logger } = require('firebase-functions');
const { FieldValue } = require('firebase-admin/firestore');
const { db } = require('./admin');
const { assertCanCallGuide } = require('./callGuards');
const { verifyCheckoutSignature, PAYMENT_STATUS } = require('./consultationLogic');
const {
  CALL_STATUS,
  OVERRUN_GRACE_SECONDS,
  RING_TIMEOUT_SECONDS,
  isEndedStatus,
  durationUsedSeconds,
  remainingSecondsFor,
  toMs,
} = require('./freeTrialCallLogic');
const {
  MIN_CALL_SECONDS,
  resolvePerMinuteRatePaise,
  maxCallSecondsFor,
  settleCall,
  validateRechargeAmount,
} = require('./walletLogic');
const { RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET } = require('./params');
const { assertConfigured } = require('./util/guards');
const { razorpayClient } = require('./razorpayConfig');

// Shared call wallet: the student recharges rupees once and spends them on
// paid calls with ANY guide, billed per second at that guide's rate, only
// for time actually talked. Pure money rules: walletLogic.js.
//
// Data (all server-written; firestore.rules: owner read-only):
//   wallets/{uid}                 { balancePaise, activeCallId, updatedAt }
//   wallet_transactions/{id}      ledger: recharge (+) / call (-)
//   payments/{razorpayOrderId}    kind: 'wallet_recharge' (same collection
//                                 as consultation payments, so the one
//                                 Razorpay webhook finds both)

const BILLING_MODE_WALLET = 'wallet';
const PAYMENT_KIND_WALLET_RECHARGE = 'wallet_recharge';

const nowIso = () => new Date().toISOString();

/** Step 1 of a recharge: server creates the Razorpay order. */
const createWalletRechargeOrder = onCall(
  { secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
    const amountPaise = request.data && request.data.amountPaise;
    if (!validateRechargeAmount(amountPaise)) {
      throw new HttpsError('invalid-argument', 'Recharge between ₹50 and ₹10,000.');
    }

    const { razorpay, keyId } = await razorpayClient();
    const order = await razorpay.orders.create({
      amount: amountPaise,
      currency: 'INR',
      receipt: `wallet_${uid}`.slice(0, 40),
      notes: { kind: PAYMENT_KIND_WALLET_RECHARGE, studentId: uid },
    });

    await db.collection('payments').doc(order.id).set({
      kind: PAYMENT_KIND_WALLET_RECHARGE,
      consultationId: null,
      studentId: uid,
      guideId: null,
      grossAmountPaise: amountPaise,
      platformFeePaise: 0,
      guideAmountPaise: 0,
      currency: 'INR',
      gateway: 'razorpay',
      gatewayOrderId: order.id,
      gatewayKeyId: keyId,
      gatewayPaymentId: null,
      status: PAYMENT_STATUS.PENDING,
      createdAt: nowIso(),
      verifiedAt: null,
    });

    return {
      paymentDocId: order.id,
      razorpayOrderId: order.id,
      keyId,
      amountPaise,
      currency: 'INR',
    };
  },
);

/**
 * Credits a paid recharge to the wallet. Idempotent (the client verify and
 * the Razorpay webhook both call it; whichever lands second is a no-op).
 */
async function creditWalletRecharge({ paymentDocId, gatewayPaymentId }) {
  const payRef = db.collection('payments').doc(paymentDocId);
  return db.runTransaction(async (tx) => {
    const paySnap = await tx.get(payRef);
    if (!paySnap.exists) throw new Error(`payment ${paymentDocId} not found`);
    const pay = paySnap.data();
    if (pay.kind !== PAYMENT_KIND_WALLET_RECHARGE) {
      throw new Error(`payment ${paymentDocId} is not a wallet recharge`);
    }
    if (pay.status === PAYMENT_STATUS.SUCCESS) return { alreadyProcessed: true };

    const walletRef = db.collection('wallets').doc(pay.studentId);
    const walletSnap = await tx.get(walletRef);
    const balance = (walletSnap.exists && walletSnap.data().balancePaise) || 0;
    const balanceAfter = balance + pay.grossAmountPaise;
    const at = nowIso();

    tx.set(walletRef, { balancePaise: balanceAfter, updatedAt: at }, { merge: true });
    tx.set(db.collection('wallet_transactions').doc(`recharge_${paymentDocId}`), {
      uid: pay.studentId,
      type: 'recharge',
      amountPaise: pay.grossAmountPaise,
      balanceAfterPaise: balanceAfter,
      paymentId: paymentDocId,
      createdAt: at,
    });
    tx.update(payRef, {
      status: PAYMENT_STATUS.SUCCESS,
      gatewayPaymentId,
      verifiedAt: at,
    });
    return { alreadyProcessed: false, balancePaise: balanceAfter };
  });
}

/** Step 2 of a recharge: client reports Razorpay's signed success. */
const verifyWalletRecharge = onCall(
  { secrets: [RAZORPAY_KEY_SECRET] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
    const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = request.data || {};
    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      throw new HttpsError('invalid-argument', 'Missing payment fields.');
    }

    const paySnap = await db.collection('payments').doc(razorpayOrderId).get();
    if (!paySnap.exists) throw new HttpsError('not-found', 'Recharge not found.');
    const pay = paySnap.data();
    if (pay.kind !== PAYMENT_KIND_WALLET_RECHARGE || pay.studentId !== uid) {
      throw new HttpsError('permission-denied', 'Not your recharge.');
    }

    const valid = verifyCheckoutSignature({
      orderId: razorpayOrderId,
      paymentId: razorpayPaymentId,
      signature: razorpaySignature,
      secret: assertConfigured(RAZORPAY_KEY_SECRET.value(), 'Payments'),
    });
    if (!valid) throw new HttpsError('permission-denied', 'Invalid payment signature.');

    const result = await creditWalletRecharge({
      paymentDocId: razorpayOrderId,
      gatewayPaymentId: razorpayPaymentId,
    });
    return { status: 'success', alreadyProcessed: result.alreadyProcessed };
  },
);

/**
 * Starts a paid call to any guide from the wallet. The session's
 * maxDurationSeconds is what the balance buys at this guide's rate; one
 * paid call at a time per wallet (activeCallId) so two calls can't both
 * spend the same money. Denials use `resource-exhausted` + details.reason
 * ('insufficient_balance' | 'call_in_progress') so the app can respond.
 */
const startPaidCall = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

  const { guideId, callType, caller, guide } = await assertCanCallGuide(uid, request.data);
  const ratePaisePerMinute = resolvePerMinuteRatePaise(guide.communicationSettings);

  const walletRef = db.collection('wallets').doc(uid);
  const sessionRef = db.collection('call_sessions').doc();
  let maxDurationSeconds = 0;

  await db.runTransaction(async (tx) => {
    const walletSnap = await tx.get(walletRef);
    const wallet = walletSnap.exists ? walletSnap.data() : {};
    if (wallet.activeCallId) {
      const active = await tx.get(db.collection('call_sessions').doc(wallet.activeCallId));
      if (active.exists && !isEndedStatus(active.data().status)) {
        throw new HttpsError(
          'resource-exhausted',
          'You are already on a paid call. End it before starting another.',
          { reason: 'call_in_progress' },
        );
      }
    }

    const balancePaise = wallet.balancePaise || 0;
    maxDurationSeconds = maxCallSecondsFor(balancePaise, ratePaisePerMinute);
    if (maxDurationSeconds < MIN_CALL_SECONDS) {
      throw new HttpsError(
        'resource-exhausted',
        'Your wallet balance is too low for this guide. Please recharge to continue calling.',
        { reason: 'insufficient_balance', balancePaise, ratePaisePerMinute, guideId },
      );
    }

    const at = nowIso();
    tx.set(sessionRef, {
      id: sessionRef.id,
      callerId: uid,
      calleeId: guideId,
      callType,
      status: CALL_STATUS.REQUESTED,
      callerAccepted: true,
      calleeAccepted: false,
      callerAlias: caller.anonymousGuideAlias || 'Student',
      calleeAlias: guide.anonymousGuideAlias || 'Guide',
      callerTier: caller.subscriptionTier || 'free',
      calleeTier: guide.subscriptionTier || 'free',
      maxDurationSeconds,
      isFreeTrial: false,
      billingMode: BILLING_MODE_WALLET,
      ratePaisePerMinute,
      createdAt: at,
      startedAt: null,
      endedAt: null,
      endedBy: null,
      isEmergencyEnd: false,
      ratingsSubmittedCaller: false,
      ratingsSubmittedCallee: false,
    });
    tx.set(walletRef, { activeCallId: sessionRef.id, updatedAt: at }, { merge: true });
  });

  return { sessionId: sessionRef.id, ratePaisePerMinute, maxDurationSeconds };
});

/**
 * Wallet call lifecycle:
 *   connected -> stamp serverStartedAt (server clock; billing starts here)
 *   ended     -> bill connected seconds (server clock) at the session's
 *                rate, debit the wallet, credit the guide (80%), release
 *                the one-call lock. Never connected -> costs nothing.
 * Idempotent via `settledAt`.
 */
const onWalletCallUpdated = onDocumentUpdated('call_sessions/{sessionId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (after.billingMode !== BILLING_MODE_WALLET) return;

  const sessionRef = event.data.after.ref;
  const sessionId = event.params.sessionId;

  if (!before.startedAt && after.startedAt && !after.serverStartedAt) {
    await sessionRef.update({ serverStartedAt: FieldValue.serverTimestamp() });
  }

  const endedNow = !isEndedStatus(before.status) && isEndedStatus(after.status);
  if (!endedNow) return;

  await db.runTransaction(async (tx) => {
    const sessionSnap = await tx.get(sessionRef);
    const session = sessionSnap.data();
    if (!session || session.settledAt) return;

    const walletRef = db.collection('wallets').doc(session.callerId);
    const walletSnap = await tx.get(walletRef);
    const wallet = walletSnap.exists ? walletSnap.data() : {};

    const limit = Number(session.maxDurationSeconds) || 0;
    const nowMs = Date.now();
    let billedSeconds = 0;
    if (session.startedAt) {
      const serverStart = toMs(session.serverStartedAt);
      billedSeconds = serverStart !== null
        ? Math.floor((nowMs - serverStart) / 1000)
        // Ended before the server stamp landed (a few-second call): fall
        // back to the phones' own start/end times.
        : durationUsedSeconds(session.startedAt, session.endedAt);
      billedSeconds = Math.min(Math.max(billedSeconds, 0), limit);
    }

    const settlement = settleCall({
      balancePaise: wallet.balancePaise || 0,
      billedSeconds,
      ratePaisePerMinute: session.ratePaisePerMinute,
    });
    const at = nowIso();

    const walletUpdate = { updatedAt: at };
    if (wallet.activeCallId === sessionId) walletUpdate.activeCallId = FieldValue.delete();
    if (settlement.chargePaise > 0) {
      walletUpdate.balancePaise = settlement.balanceAfterPaise;
      tx.set(db.collection('wallet_transactions').doc(`call_${sessionId}`), {
        uid: session.callerId,
        type: 'call',
        amountPaise: -settlement.chargePaise,
        balanceAfterPaise: settlement.balanceAfterPaise,
        sessionId,
        guideId: session.calleeId,
        guideAlias: session.calleeAlias || 'Guide',
        billedSeconds,
        ratePaisePerMinute: session.ratePaisePerMinute,
        createdAt: at,
      });
      // Call is already over, so the guide's share is payable straight
      // away (consultation earnings wait for completion instead).
      tx.set(
        db.collection('guide_earnings').doc(session.calleeId)
          .collection('entries').doc(`call_${sessionId}`),
        {
          consultationId: `call_${sessionId}`,
          sessionId,
          source: 'wallet_call',
          amountPaise: settlement.guideAmountPaise,
          grossAmountPaise: settlement.chargePaise,
          platformFeePaise: settlement.platformFeePaise,
          status: 'payable',
          createdAt: at,
        },
      );
    }
    tx.set(walletRef, walletUpdate, { merge: true });
    tx.update(sessionRef, {
      billedSeconds,
      chargedPaise: settlement.chargePaise,
      settledAt: at,
    });
  });
});

/**
 * Backstop when neither app hangs up: ends paid calls past the time their
 * balance bought (+ grace), and marks unanswered ones missed (which
 * releases the wallet lock at no charge).
 */
const sweepWalletCalls = onSchedule('every 1 minutes', async () => {
  const nowMs = Date.now();
  const at = nowIso();
  const sessions = db.collection('call_sessions');
  const [active, unanswered] = await Promise.all([
    sessions
      .where('billingMode', '==', BILLING_MODE_WALLET)
      .where('status', '==', CALL_STATUS.ACTIVE)
      .limit(200)
      .get(),
    sessions
      .where('billingMode', '==', BILLING_MODE_WALLET)
      .where('status', '==', CALL_STATUS.REQUESTED)
      .where('createdAt', '<', new Date(nowMs - RING_TIMEOUT_SECONDS * 1000).toISOString())
      .limit(200)
      .get(),
  ]);

  const overrun = active.docs.filter((d) => {
    const s = d.data();
    if (!s.serverStartedAt) return false;
    const left = remainingSecondsFor(Number(s.maxDurationSeconds) || 0, s.serverStartedAt, nowMs);
    return left <= 0 && nowMs - toMs(s.serverStartedAt) >
      ((Number(s.maxDurationSeconds) || 0) + OVERRUN_GRACE_SECONDS) * 1000;
  });

  if (overrun.length === 0 && unanswered.empty) return;
  const batch = db.batch();
  for (const doc of overrun) {
    batch.update(doc.ref, { status: CALL_STATUS.ENDED, endedAt: at, endedBy: 'system' });
  }
  for (const doc of unanswered.docs) {
    batch.update(doc.ref, { status: CALL_STATUS.MISSED, endedAt: at, endedBy: 'system' });
  }
  await batch.commit();
  logger.info(`sweepWalletCalls: ended ${overrun.length} overrun, ${unanswered.size} unanswered`);
});

module.exports = {
  PAYMENT_KIND_WALLET_RECHARGE,
  creditWalletRecharge,
  createWalletRechargeOrder,
  verifyWalletRecharge,
  startPaidCall,
  onWalletCallUpdated,
  sweepWalletCalls,
};
