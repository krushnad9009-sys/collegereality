'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');
const { finalizePaymentSuccess } = require('./finalizePayment');
const { verifyWebhookSignature } = require('./consultationLogic');
const { RAZORPAY_WEBHOOK_SECRET } = require('./params');

/**
 * Razorpay webhook — the AUTHORITATIVE payment-success path. Must survive
 * the student's app being killed/offline right after paying, and must be
 * safe against Razorpay redelivering the same event (their docs say
 * "design your webhook handler to be idempotent" — finalizePaymentSuccess
 * is exactly that).
 *
 * Configure this URL in the Razorpay dashboard (Settings > Webhooks) after
 * deploy, with the same secret as RAZORPAY_WEBHOOK_SECRET, subscribed to
 * `payment.captured` (and optionally `payment.failed`).
 */
const razorpayWebhook = onRequest(
  { secrets: [RAZORPAY_WEBHOOK_SECRET] },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    const signature = req.headers['x-razorpay-signature'];
    // req.rawBody is populated by the Functions runtime for onRequest —
    // MUST verify against the raw bytes, not the parsed/re-serialized body.
    const rawBody = req.rawBody;
    if (!signature || !rawBody) {
      res.status(400).send('Missing signature or body');
      return;
    }

    const valid = verifyWebhookSignature({
      rawBody,
      signature,
      secret: RAZORPAY_WEBHOOK_SECRET.value(),
    });
    if (!valid) {
      logger.warn('razorpayWebhook: invalid signature');
      res.status(401).send('Invalid signature');
      return;
    }

    const event = req.body;
    const eventType = event && event.event;

    try {
      if (eventType === 'payment.captured') {
        const payment = event.payload.payment.entity;
        await finalizePaymentSuccess({
          paymentDocId: payment.order_id,
          gatewayPaymentId: payment.id,
        });
      } else if (eventType === 'payment.failed') {
        const payment = event.payload.payment.entity;
        const { db } = require('./admin');
        const { PAYMENT_STATUS } = require('./consultationLogic');
        const ref = db.collection('payments').doc(payment.order_id);
        const snap = await ref.get();
        if (snap.exists && snap.data().status === PAYMENT_STATUS.PENDING) {
          await ref.update({ status: PAYMENT_STATUS.FAILED });
        }
      }
      // Other event types are intentionally ignored but still 200'd so
      // Razorpay doesn't retry-storm us for events we don't act on.
      res.status(200).send('ok');
    } catch (err) {
      logger.error('razorpayWebhook handler error', err);
      // 500 tells Razorpay to retry — safe because finalizePaymentSuccess
      // is idempotent.
      res.status(500).send('Internal error');
    }
  },
);

module.exports = { razorpayWebhook };
