'use strict';

// Secret Manager-backed config — nothing here is a literal value. Set each
// with `firebase functions:secrets:set NAME`, then grant the function
// access on deploy (the Firebase CLI prompts automatically). See README.md.
const { defineSecret, defineString } = require('firebase-functions/params');

const RAZORPAY_KEY_ID = defineSecret('RAZORPAY_KEY_ID');
const RAZORPAY_KEY_SECRET = defineSecret('RAZORPAY_KEY_SECRET');
const RAZORPAY_WEBHOOK_SECRET = defineSecret('RAZORPAY_WEBHOOK_SECRET');
const AGORA_APP_ID = defineSecret('AGORA_APP_ID');
const AGORA_APP_CERTIFICATE = defineSecret('AGORA_APP_CERTIFICATE');
const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

// Email OTP (see src/emailOtp.js). RESEND_API_KEY is a Secret Manager
// secret; RESEND_FROM is a plain deploy-time value (a verified sender
// address on your Resend account, e.g. "College Reality <verify@yourdomain>").
const RESEND_API_KEY = defineSecret('RESEND_API_KEY');
const RESEND_FROM = defineString('RESEND_FROM', {
  default: 'College Reality <onboarding@resend.dev>',
});

module.exports = {
  RAZORPAY_KEY_ID,
  RAZORPAY_KEY_SECRET,
  RAZORPAY_WEBHOOK_SECRET,
  AGORA_APP_ID,
  AGORA_APP_CERTIFICATE,
  GEMINI_API_KEY,
  RESEND_API_KEY,
  RESEND_FROM,
};
