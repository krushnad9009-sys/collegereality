'use strict';

const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const Razorpay = require('razorpay');
const { db } = require('./admin');
const { CONSULTATION_STATUS, PAYMENT_STATUS } = require('./consultationLogic');
const { RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET } = require('./params');

/**
 * Watches every consultation update for two trusted-only transitions that
 * the client is intentionally forbidden from making directly:
 *   - cancelled AFTER payment -> initiate a real Razorpay refund
 *   - completed -> release the guide's earnings entry from 'pending' to
 *     'payable'
 * This is what makes firestore.rules' "client can mark cancelled but never
 * touches refundStatus" design actually resolve the money side of §8/§10
 * ("do not silently keep money in an unresolved state").
 */
const onConsultationWrite = onDocumentUpdated(
  { document: 'consultations/{consultationId}', secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const consultationId = event.params.consultationId;

    const justCancelled =
      before.status !== CONSULTATION_STATUS.CANCELLED &&
      after.status === CONSULTATION_STATUS.CANCELLED;
    const justCompleted =
      before.status !== CONSULTATION_STATUS.COMPLETED &&
      after.status === CONSULTATION_STATUS.COMPLETED;

    if (justCancelled && after.paymentId) {
      await refundIfPaid({ consultationId, paymentId: after.paymentId });
    }

    if (justCompleted) {
      await releaseEarnings({ consultationId, guideId: after.guideId });
    }
  },
);

async function refundIfPaid({ consultationId, paymentId }) {
  const paymentRef = db.collection('payments').doc(paymentId);
  const paymentSnap = await paymentRef.get();
  if (!paymentSnap.exists) return;
  const payment = paymentSnap.data();

  if (payment.status !== PAYMENT_STATUS.SUCCESS) {
    // Never actually charged (still pending/failed) — nothing to refund,
    // just make sure the payment record itself reflects "won't be charged".
    if (payment.status === PAYMENT_STATUS.PENDING) {
      await paymentRef.update({ status: PAYMENT_STATUS.CANCELLED });
    }
    return;
  }

  try {
    const razorpay = new Razorpay({
      key_id: RAZORPAY_KEY_ID.value(),
      key_secret: RAZORPAY_KEY_SECRET.value(),
    });
    await razorpay.payments.refund(payment.gatewayPaymentId, {
      amount: payment.grossAmountPaise,
      speed: 'optimum',
    });

    await paymentRef.update({ status: PAYMENT_STATUS.REFUNDED });
    await db.collection('consultations').doc(consultationId).update({
      refundStatus: 'refunded',
      updatedAt: new Date().toISOString(),
    });

    // Void the guide's earnings entry — the consultation never happened.
    const earningsRef = db
      .collection('guide_earnings')
      .doc(payment.guideId)
      .collection('entries')
      .doc(consultationId);
    await earningsRef.set({ status: 'void' }, { merge: true });
  } catch (err) {
    logger.error(`refundIfPaid failed for consultation ${consultationId}`, err);
    await db.collection('consultations').doc(consultationId).update({
      refundStatus: 'failed',
      updatedAt: new Date().toISOString(),
    });
    // Re-throw so this invocation shows as failed/retried in Cloud
    // Functions logs — a failed refund must be visible to an operator,
    // never silently swallowed (see feature spec §8).
    throw err;
  }
}

async function releaseEarnings({ consultationId, guideId }) {
  const earningsRef = db
    .collection('guide_earnings')
    .doc(guideId)
    .collection('entries')
    .doc(consultationId);
  const snap = await earningsRef.get();
  if (!snap.exists || snap.data().status !== 'pending') return;
  await earningsRef.update({ status: 'payable' });
}

module.exports = { onConsultationWrite };
