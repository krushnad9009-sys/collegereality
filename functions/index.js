'use strict';

// Trusted backend for the "Talk to a Verified Student/Alumni" paid
// consultation feature. See README.md for required secrets before deploy —
// nothing here runs correctly without real Razorpay/Agora credentials
// configured in Secret Manager. Never deployed automatically by an agent;
// you (the project owner) run `firebase deploy --only functions` yourself.

const { createConsultationOrder, verifyConsultationPayment } = require('./src/consultations');
const { razorpayWebhook } = require('./src/webhook');
const { mintConsultationCallToken } = require('./src/callToken');
const { onConsultationWrite } = require('./src/triggers');
const { expireStaleConsultations } = require('./src/scheduled');

module.exports = {
  createConsultationOrder,
  verifyConsultationPayment,
  razorpayWebhook,
  mintConsultationCallToken,
  onConsultationWrite,
  expireStaleConsultations,
};
