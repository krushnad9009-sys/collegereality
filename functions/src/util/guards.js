'use strict';

const crypto = require('crypto');
const { HttpsError } = require('firebase-functions/v2/https');

/**
 * Fail fast, with a clean client-facing message, when a Secret Manager
 * value a callable depends on is missing (never deployed / not granted).
 * Without this the underlying SDK (Razorpay, Agora, …) throws a vendor
 * error that only reaches the client as a bare `internal`.
 *
 * @param {*} value        the resolved `defineSecret(...).value()`
 * @param {string} feature human name for the message ("Payments", "Calling")
 * @returns the value, when set
 */
function assertConfigured(value, feature) {
  if (value === undefined || value === null || value === '') {
    throw new HttpsError(
      'failed-precondition',
      `${feature} is temporarily unavailable. Please try again later.`,
    );
  }
  return value;
}

/**
 * Short, unguessable token used to tie a generic client error response to
 * the detailed server-side log line for it. ~12 url-safe chars.
 */
function newCorrelationId() {
  return crypto.randomBytes(9).toString('base64url');
}

module.exports = { assertConfigured, newCorrelationId };
