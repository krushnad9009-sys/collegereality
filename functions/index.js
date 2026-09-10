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
const { aiChatComplete } = require('./src/aiChat');
const { requestEmailOtp, verifyEmailOtp } = require('./src/emailOtp');
const { requestAccountDeletion } = require('./src/accountDeletion');
const {
  onVerificationRequestCreated,
  onCollegeRequestCreated,
} = require('./src/verificationTriggers');
const { onConsultationRatingCreated } = require('./src/consultationRatingTriggers');

module.exports = {
  createConsultationOrder,
  verifyConsultationPayment,
  razorpayWebhook,
  mintConsultationCallToken,
  onConsultationWrite,
  expireStaleConsultations,
  aiChatComplete,
  requestEmailOtp,
  verifyEmailOtp,
  // Self-serve account deletion (GDPR/DPDP erasure): deletes the caller's
  // own data, anonymises retained content, keeps financial records.
  requestAccountDeletion,
  // AI Automated Verification Agent (Super Admin panel background flow).
  onVerificationRequestCreated,
  onCollegeRequestCreated,
  // Recomputes a guide's consultation-rating aggregate + the PII-free
  // public review copy whenever a two-way rating is filed.
  onConsultationRatingCreated,
};
