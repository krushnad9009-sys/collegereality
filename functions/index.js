'use strict';

// Trusted backend for the "Talk to a Verified Student/Alumni" paid
// consultation feature. See README.md for required secrets before deploy —
// nothing here runs correctly without real Razorpay/Agora credentials
// configured in Secret Manager. Never deployed automatically by an agent;
// you (the project owner) run `firebase deploy --only functions` yourself.

const { createConsultationOrder, verifyConsultationPayment } = require('./src/consultations');
const { razorpayWebhook } = require('./src/webhook');
const { mintConsultationCallToken, mintCallSessionToken } = require('./src/callToken');
const { onConsultationWrite } = require('./src/triggers');
const { expireStaleConsultations } = require('./src/scheduled');
const {
  startFreeTrialCall,
  onFreeTrialCallUpdated,
  sweepFreeTrialCalls,
} = require('./src/freeTrialCalls');
const { onUserWriteSyncPublicProfile } = require('./src/publicProfileSync');
const { onInteractionRatingCreated } = require('./src/interactionRatingTriggers');
const {
  createWalletRechargeOrder,
  verifyWalletRecharge,
  startPaidCall,
  onWalletCallUpdated,
  sweepWalletCalls,
} = require('./src/wallet');
const { aiChatComplete } = require('./src/aiChat');
const { requestEmailOtp, verifyEmailOtp } = require('./src/emailOtp');
const { requestAccountDeletion } = require('./src/accountDeletion');
const {
  onVerificationRequestCreated,
  onCollegeRequestCreated,
} = require('./src/verificationTriggers');
const { onConsultationRatingCreated } = require('./src/consultationRatingTriggers');
const {
  onUserVerificationBadgeGranted,
  onChatMessageCreated,
  onCallSessionCreated,
} = require('./src/pushNotificationTriggers');
const { onLeadActivityEventCreated } = require('./src/leadActivityTriggers');

module.exports = {
  createConsultationOrder,
  verifyConsultationPayment,
  razorpayWebhook,
  mintConsultationCallToken,
  // Agora join token for direct guide calls (expires with the free time).
  mintCallSessionToken,
  onConsultationWrite,
  expireStaleConsultations,
  // Direct guide calls: 2-minute free trial, once per day per guide.
  // startFreeTrialCall is the only way to create a call_sessions doc.
  startFreeTrialCall,
  onFreeTrialCallUpdated,
  sweepFreeTrialCalls,
  // Keeps public_profiles (guide directory, presence) in step with users
  // even when a client mirror write was denied; strips legacy PII keys.
  onUserWriteSyncPublicProfile,
  // Free call/chat ratings -> ratee's guideStats (was a cross-user client
  // write that rules denied).
  onInteractionRatingCreated,
  // Shared call wallet: recharge once, spend on paid calls with any guide
  // at that guide's per-minute rate; unused balance stays for next time.
  createWalletRechargeOrder,
  verifyWalletRecharge,
  startPaidCall,
  onWalletCallUpdated,
  sweepWalletCalls,
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
  // FCM push notifications: verified badge granted, 1-on-1 chat message,
  // incoming voice/video call. See src/push.js for the actual send call.
  onUserVerificationBadgeGranted,
  onChatMessageCreated,
  onCallSessionCreated,
  // Weekly Lead Analytics (Super Admin panel): rolls each
  // lead_activity_events doc into lead_summaries/{uid}.
  onLeadActivityEventCreated,
};
