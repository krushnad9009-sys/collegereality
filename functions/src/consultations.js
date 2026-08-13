'use strict';

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const Razorpay = require('razorpay');
const { db } = require('./admin');
const { finalizePaymentSuccess } = require('./finalizePayment');
const {
  resolveGuidePriceForConsultation,
  verifyCheckoutSignature,
  CONSULTATION_STATUS,
  PAYMENT_STATUS,
} = require('./consultationLogic');
const {
  RAZORPAY_KEY_ID,
  RAZORPAY_KEY_SECRET,
} = require('./params');

/**
 * Student calls this after creating the `requested` consultation doc
 * client-side. Re-validates everything server-side — the guide's
 * currently published price, their eligibility, and the consultation's
 * own state — before ever creating a real order or letting money move.
 */
const createConsultationOrder = onCall(
  { secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const consultationId = request.data && request.data.consultationId;
    if (!consultationId) {
      throw new HttpsError('invalid-argument', 'consultationId is required.');
    }

    const consultationRef = db.collection('consultations').doc(consultationId);
    const consultationSnap = await consultationRef.get();
    if (!consultationSnap.exists) {
      throw new HttpsError('not-found', 'Consultation not found.');
    }
    const consultation = consultationSnap.data();

    if (consultation.studentId !== uid) {
      throw new HttpsError('permission-denied', 'Not your consultation.');
    }
    if (consultation.status !== CONSULTATION_STATUS.REQUESTED) {
      throw new HttpsError(
        'failed-precondition',
        `Consultation is '${consultation.status}', expected 'requested'.`,
      );
    }

    const guideSnap = await db.collection('users').doc(consultation.guideId).get();
    if (!guideSnap.exists) throw new HttpsError('not-found', 'Guide not found.');
    const guide = guideSnap.data();

    const eligible =
      (guide.verificationBadge === 'verified_student' ||
        guide.verificationBadge === 'verified_alumni') &&
      guide.verificationStatus === 'approved';
    if (!eligible) {
      throw new HttpsError('failed-precondition', 'Guide is not eligible.');
    }

    const serverPrice = resolveGuidePriceForConsultation({
      settings: guide.communicationSettings,
      type: consultation.type,
      durationMinutes: consultation.durationMinutes,
    });
    if (serverPrice == null) {
      throw new HttpsError(
        'failed-precondition',
        'This guide no longer offers that consultation option.',
      );
    }
    // The client's displayed price must match what the guide actually
    // publishes right now — if it drifted (guide changed price mid-flow),
    // fail closed rather than silently charging a different amount.
    if (serverPrice !== consultation.priceInfo.grossPaise) {
      throw new HttpsError(
        'failed-precondition',
        'This guide’s price has changed. Please go back and try again.',
      );
    }

    const razorpay = new Razorpay({
      key_id: RAZORPAY_KEY_ID.value(),
      key_secret: RAZORPAY_KEY_SECRET.value(),
    });
    const order = await razorpay.orders.create({
      amount: serverPrice,
      currency: 'INR',
      receipt: consultationId,
      notes: {
        consultationId,
        studentId: uid,
        guideId: consultation.guideId,
      },
    });

    const nowIso = new Date().toISOString();
    await db.collection('payments').doc(order.id).set({
      consultationId,
      studentId: uid,
      guideId: consultation.guideId,
      grossAmountPaise: serverPrice,
      platformFeePaise: 0,
      guideAmountPaise: 0,
      currency: 'INR',
      gateway: 'razorpay',
      gatewayOrderId: order.id,
      gatewayPaymentId: null,
      status: PAYMENT_STATUS.PENDING,
      createdAt: nowIso,
      verifiedAt: null,
    });

    await consultationRef.update({
      status: CONSULTATION_STATUS.PAYMENT_PENDING,
      paymentId: order.id,
      updatedAt: nowIso,
    });

    return {
      paymentDocId: order.id,
      razorpayOrderId: order.id,
      keyId: RAZORPAY_KEY_ID.value(),
      amountPaise: serverPrice,
      currency: 'INR',
    };
  },
);

/**
 * Called by the client immediately after Razorpay Checkout reports
 * success, for instant UX. The webhook (webhook.js) is the authoritative
 * path that doesn't depend on the app staying open — both funnel into the
 * same idempotent finalizePaymentSuccess().
 */
const verifyConsultationPayment = onCall(
  { secrets: [RAZORPAY_KEY_SECRET] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const { consultationId, razorpayOrderId, razorpayPaymentId, razorpaySignature } =
      request.data || {};
    if (!consultationId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      throw new HttpsError('invalid-argument', 'Missing payment fields.');
    }

    const consultationSnap = await db.collection('consultations').doc(consultationId).get();
    if (!consultationSnap.exists) throw new HttpsError('not-found', 'Consultation not found.');
    const consultation = consultationSnap.data();
    if (consultation.studentId !== uid) {
      throw new HttpsError('permission-denied', 'Not your consultation.');
    }
    if (consultation.paymentId !== razorpayOrderId) {
      throw new HttpsError('failed-precondition', 'Order does not match this consultation.');
    }

    const validSignature = verifyCheckoutSignature({
      orderId: razorpayOrderId,
      paymentId: razorpayPaymentId,
      signature: razorpaySignature,
      secret: RAZORPAY_KEY_SECRET.value(),
    });
    if (!validSignature) {
      throw new HttpsError('permission-denied', 'Invalid payment signature.');
    }

    await finalizePaymentSuccess({
      paymentDocId: razorpayOrderId,
      gatewayPaymentId: razorpayPaymentId,
    });

    return { status: 'success' };
  },
);

module.exports = { createConsultationOrder, verifyConsultationPayment };
