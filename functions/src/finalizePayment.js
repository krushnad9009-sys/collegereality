'use strict';

const { FieldValue } = require('firebase-admin/firestore');
const { db } = require('./admin');
const { splitConsultationAmount, CONSULTATION_STATUS, PAYMENT_STATUS } = require('./consultationLogic');

/** Deterministic so a retry/replay never creates a second conversation. */
function chatConversationIdFor(consultationId) {
  return `consultation_${consultationId}`;
}

/**
 * The single place a payment is ever marked successful. Called from BOTH
 * the client-facing verifyConsultationPayment callable (instant UX) and
 * the Razorpay webhook (authoritative, survives a killed app) — either can
 * arrive first or be replayed any number of times; the Firestore
 * transaction below makes that safe:
 *   - re-reads the payment doc's *current* status inside the transaction
 *   - a no-op if it's already 'success' (idempotent against webhook
 *     replays / duplicate callback delivery)
 *   - never trusts amounts the client sent; recomputes the fee split from
 *     the payment doc's own grossAmountPaise, written at order-creation
 *     time from the guide's server-verified published price
 */
async function finalizePaymentSuccess({ paymentDocId, gatewayPaymentId }) {
  const paymentRef = db.collection('payments').doc(paymentDocId);

  const result = await db.runTransaction(async (tx) => {
    const paymentSnap = await tx.get(paymentRef);
    if (!paymentSnap.exists) {
      throw new Error(`payments/${paymentDocId} not found`);
    }
    const payment = paymentSnap.data();

    if (payment.status === PAYMENT_STATUS.SUCCESS) {
      return { alreadyProcessed: true, payment };
    }
    if (payment.status !== PAYMENT_STATUS.PENDING) {
      throw new Error(
        `payments/${paymentDocId} is '${payment.status}', cannot mark success`,
      );
    }

    const consultationRef = db.collection('consultations').doc(payment.consultationId);
    const consultationSnap = await tx.get(consultationRef); // read before any write
    if (!consultationSnap.exists) {
      throw new Error(`consultations/${payment.consultationId} not found`);
    }
    const consultation = consultationSnap.data();

    const { platformFeePaise, guideAmountPaise } = splitConsultationAmount(
      payment.grossAmountPaise,
    );
    const now = FieldValue.serverTimestamp();
    const nowIso = new Date().toISOString();

    tx.update(paymentRef, {
      status: PAYMENT_STATUS.SUCCESS,
      gatewayPaymentId,
      platformFeePaise,
      guideAmountPaise,
      verifiedAt: nowIso,
    });

    const isChat = consultation.type === 'chat';
    const conversationId = isChat ? chatConversationIdFor(payment.consultationId) : null;

    tx.update(consultationRef, {
      status: isChat ? CONSULTATION_STATUS.ACTIVE : CONSULTATION_STATUS.PAID,
      paidAt: nowIso,
      startedAt: isChat ? nowIso : null,
      conversationId,
      updatedAt: nowIso,
      'priceInfo.platformFeePaise': platformFeePaise,
      'priceInfo.guideAmountPaise': guideAmountPaise,
    });

    // Chat consultations reuse the existing private community chat engine
    // wholesale — server creates it (never the client) so its mere
    // existence proves payment succeeded. Deterministic doc ID makes this
    // safe against the same replay/idempotency concerns as the rest of
    // this function.
    if (isChat) {
      const conversationRef = db.collection('community_conversations').doc(conversationId);
      tx.set(
        conversationRef,
        {
          id: conversationId,
          type: 'private',
          participantIds: [payment.studentId, payment.guideId],
          consultationId: payment.consultationId,
          lastMessageText: '',
          lastMessageSenderId: null,
          lastMessageAt: nowIso,
          createdAt: nowIso,
          updatedAt: nowIso,
        },
        { merge: true },
      );
    }

    const earningsRef = db
      .collection('guide_earnings')
      .doc(payment.guideId)
      .collection('entries')
      .doc(payment.consultationId);
    tx.set(earningsRef, {
      consultationId: payment.consultationId,
      amountPaise: guideAmountPaise,
      status: 'pending', // -> 'payable' on consultation completion, or
      //                     reversed on refund — see triggers.js
      createdAt: now,
    });

    return {
      alreadyProcessed: false,
      payment: { ...payment, status: PAYMENT_STATUS.SUCCESS, platformFeePaise, guideAmountPaise },
    };
  });

  return result;
}

module.exports = { finalizePaymentSuccess };
