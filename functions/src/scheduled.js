'use strict';

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { logger } = require('firebase-functions');
const { db } = require('./admin');
const { CONSULTATION_STATUS, PAYMENT_STATUS } = require('./consultationLogic');

const REQUEST_EXPIRY_MINUTES = 30; // student never paid / guide never answered
const GUIDE_NO_ANSWER_MINUTES = 5; // paid, but guide didn't pick up the call

/**
 * Resolves consultations that would otherwise sit in an unresolved state
 * forever (feature spec §8: "Do not silently keep money in an unresolved
 * state"):
 *   - requested/payment_pending with no payment after 30 min -> expired
 *   - waiting_for_guide (paid, ringing) with no answer after 5 min ->
 *     cancelled, which onConsultationWrite then refunds automatically
 */
const expireStaleConsultations = onSchedule('every 5 minutes', async () => {
  const now = Date.now();
  const nowIso = new Date(now).toISOString();

  await expireUnpaidRequests(now, nowIso);
  await cancelUnansweredCalls(now, nowIso);
});

async function expireUnpaidRequests(now, nowIso) {
  const cutoff = new Date(now - REQUEST_EXPIRY_MINUTES * 60 * 1000).toISOString();
  const snap = await db
    .collection('consultations')
    .where('status', 'in', [CONSULTATION_STATUS.REQUESTED, CONSULTATION_STATUS.PAYMENT_PENDING])
    .where('createdAt', '<', cutoff)
    .limit(200)
    .get();

  for (const doc of snap.docs) {
    const data = doc.data();
    await doc.ref.update({
      status: CONSULTATION_STATUS.EXPIRED,
      updatedAt: nowIso,
    });
    if (data.paymentId) {
      const paymentRef = db.collection('payments').doc(data.paymentId);
      const paymentSnap = await paymentRef.get();
      if (paymentSnap.exists && paymentSnap.data().status === PAYMENT_STATUS.PENDING) {
        await paymentRef.update({ status: PAYMENT_STATUS.CANCELLED });
      }
    }
  }
  if (!snap.empty) {
    logger.info(`expireUnpaidRequests: expired ${snap.size} consultation(s)`);
  }
}

async function cancelUnansweredCalls(now, nowIso) {
  const cutoff = new Date(now - GUIDE_NO_ANSWER_MINUTES * 60 * 1000).toISOString();
  const snap = await db
    .collection('consultations')
    .where('status', '==', CONSULTATION_STATUS.WAITING_FOR_GUIDE)
    .where('updatedAt', '<', cutoff)
    .limit(200)
    .get();

  for (const doc of snap.docs) {
    await doc.ref.update({
      status: CONSULTATION_STATUS.CANCELLED,
      cancelledAt: nowIso,
      cancelReason: 'guide_no_answer',
      updatedAt: nowIso,
    });
  }
  if (!snap.empty) {
    logger.info(`cancelUnansweredCalls: cancelled ${snap.size} consultation(s)`);
  }
}

module.exports = { expireStaleConsultations };
