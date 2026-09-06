'use strict';

// Custom email-OTP verification. Firebase Auth has no email-OTP primitive,
// so this is built from scratch:
//   requestEmailOtp -> generate a 6-digit code, store it hashed in
//                      Firestore (email_otps/{uid}) with a TTL + rate
//                      limits, email it via Resend.
//   verifyEmailOtp  -> check the code, then mark the Firebase Auth user
//                      emailVerified (Admin SDK — the client cannot) and
//                      mirror it onto users/{uid}.isEmailVerified.
//
// The email_otps collection is server-only (see firestore.rules) — the
// client never reads or writes a code.

const crypto = require('crypto');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { db } = require('./admin');
const { RESEND_API_KEY, RESEND_FROM } = require('./params');

const OTP_TTL_MS = 10 * 60 * 1000; // code valid for 10 minutes
const RESEND_COOLDOWN_MS = 60 * 1000; // min gap between two sends
const SEND_WINDOW_MS = 60 * 60 * 1000; // rolling window for the send cap
const MAX_SENDS_PER_WINDOW = 5;
const MAX_VERIFY_ATTEMPTS = 5;

const COLLECTION = 'email_otps';

function generateCode() {
  // 000000–999999, cryptographically uniform.
  return String(crypto.randomInt(0, 1_000_000)).padStart(6, '0');
}

function hashCode(salt, code) {
  return crypto.createHash('sha256').update(`${salt}:${code}`).digest('hex');
}

function timingSafeEqualHex(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length) {
    return false;
  }
  return crypto.timingSafeEqual(Buffer.from(a, 'hex'), Buffer.from(b, 'hex'));
}

function otpEmailHtml(code) {
  return `
    <div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:480px;margin:0 auto;padding:24px">
      <h2 style="margin:0 0 8px;color:#0f172a">Verify your email</h2>
      <p style="margin:0 0 20px;color:#475569;font-size:14px;line-height:1.5">
        Enter this code in College Reality to verify your email address. It
        expires in 10 minutes.
      </p>
      <div style="font-size:32px;font-weight:700;letter-spacing:8px;color:#0f172a;background:#f1f5f9;border-radius:12px;padding:16px;text-align:center">
        ${code}
      </div>
      <p style="margin:20px 0 0;color:#94a3b8;font-size:12px;line-height:1.5">
        If you didn't request this, you can safely ignore this email — no
        changes were made to your account.
      </p>
    </div>`;
}

async function sendOtpEmail(toEmail, code) {
  const apiKey = RESEND_API_KEY.value();
  if (!apiKey) {
    logger.error('[emailOtp] RESEND_API_KEY is not configured');
    throw new HttpsError('failed-precondition', 'Email sending is not configured.');
  }

  let res;
  try {
    res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: RESEND_FROM.value(),
        to: [toEmail],
        subject: 'Your College Reality verification code',
        html: otpEmailHtml(code),
        text: `Your College Reality verification code is ${code}. It expires in 10 minutes.`,
      }),
    });
  } catch (err) {
    logger.error('[emailOtp] Resend request failed', { type: err && err.name });
    throw new HttpsError('unavailable', 'Could not send the code email. Please try again.');
  }

  if (!res.ok) {
    // Resend's error body can echo the recipient/sender — log only status.
    logger.error('[emailOtp] Resend returned non-2xx', { status: res.status });
    throw new HttpsError('unavailable', 'Could not send the code email. Please try again.');
  }
}

const requestEmailOtp = onCall(
  { secrets: [RESEND_API_KEY], timeoutSeconds: 20, memory: '128MiB' },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const userRecord = await getAuth().getUser(uid);
    const email = userRecord.email;
    if (!email) {
      throw new HttpsError('failed-precondition', 'Your account has no email address.');
    }
    if (userRecord.emailVerified) {
      throw new HttpsError('already-exists', 'Your email is already verified.');
    }

    const now = Date.now();
    const ref = db.collection(COLLECTION).doc(uid);
    const snap = await ref.get();
    const prev = snap.exists ? snap.data() : null;

    if (prev) {
      const lastSentMs = prev.lastSentAt ? prev.lastSentAt.toMillis() : 0;
      if (now - lastSentMs < RESEND_COOLDOWN_MS) {
        throw new HttpsError(
          'resource-exhausted',
          'Please wait a moment before requesting another code.',
          { retryAfterSeconds: Math.ceil((RESEND_COOLDOWN_MS - (now - lastSentMs)) / 1000) },
        );
      }
    }

    // Rolling send-count window.
    const windowStartMs = prev && prev.windowStartedAt ? prev.windowStartedAt.toMillis() : 0;
    const windowActive = now - windowStartMs < SEND_WINDOW_MS;
    const sendCount = windowActive ? (prev.sendCount || 0) : 0;
    if (windowActive && sendCount >= MAX_SENDS_PER_WINDOW) {
      throw new HttpsError(
        'resource-exhausted',
        'Too many codes requested. Please try again in an hour.',
        { retryAfterSeconds: Math.ceil((SEND_WINDOW_MS - (now - windowStartMs)) / 1000) },
      );
    }

    const code = generateCode();
    const salt = crypto.randomBytes(16).toString('hex');

    await ref.set({
      email,
      codeHash: hashCode(salt, code),
      salt,
      expiresAt: Timestamp.fromMillis(now + OTP_TTL_MS),
      attempts: 0,
      sendCount: sendCount + 1,
      windowStartedAt: windowActive
        ? prev.windowStartedAt
        : Timestamp.fromMillis(now),
      lastSentAt: Timestamp.fromMillis(now),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await sendOtpEmail(email, code);

    return {
      ok: true,
      expiresInSeconds: Math.floor(OTP_TTL_MS / 1000),
      retryAfterSeconds: Math.floor(RESEND_COOLDOWN_MS / 1000),
    };
  },
);

const verifyEmailOtp = onCall(
  { timeoutSeconds: 20, memory: '128MiB' },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const code = request.data && request.data.code;
    if (typeof code !== 'string' || !/^\d{6}$/.test(code)) {
      throw new HttpsError('invalid-argument', 'Enter the 6-digit code.');
    }

    const ref = db.collection(COLLECTION).doc(uid);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError('failed-precondition', 'Request a code first.');
    }
    const data = snap.data();

    if (!data.expiresAt || data.expiresAt.toMillis() < Date.now()) {
      await ref.delete();
      throw new HttpsError('deadline-exceeded', 'This code has expired. Request a new one.');
    }

    if ((data.attempts || 0) >= MAX_VERIFY_ATTEMPTS) {
      await ref.delete();
      throw new HttpsError(
        'resource-exhausted',
        'Too many incorrect attempts. Request a new code.',
      );
    }

    const userRecord = await getAuth().getUser(uid);
    // The address may have changed since the code was issued.
    if (userRecord.email && data.email && userRecord.email !== data.email) {
      await ref.delete();
      throw new HttpsError(
        'failed-precondition',
        'Your email address changed. Request a new code.',
      );
    }
    if (userRecord.emailVerified) {
      await ref.delete();
      return { ok: true, alreadyVerified: true };
    }

    const matches = timingSafeEqualHex(hashCode(data.salt, code), data.codeHash);
    if (!matches) {
      const attempts = (data.attempts || 0) + 1;
      await ref.update({ attempts, updatedAt: FieldValue.serverTimestamp() });
      throw new HttpsError('invalid-argument', 'Incorrect code. Please try again.', {
        attemptsLeft: Math.max(0, MAX_VERIFY_ATTEMPTS - attempts),
      });
    }

    // The code is correct — from here the only failures are backend ones
    // (Auth Admin API blip, Firestore). Log them with the full stack and
    // return a clean, retryable error instead of a bare 'internal'. The
    // OTP doc is intentionally NOT deleted on failure so a retry works
    // without a Resend.
    try {
      await getAuth().updateUser(uid, { emailVerified: true });
      await db.collection('users').doc(uid).set(
        {
          isEmailVerified: true,
          updatedAt: new Date().toISOString(),
        },
        { merge: true },
      );
      await ref.delete();
    } catch (err) {
      logger.error('[emailOtp] verifyEmailOtp: post-verify write failed', {
        uid,
        errorCode: err && err.code,
        errorType: err && err.constructor && err.constructor.name,
        stack: err && err.stack,
      });
      throw new HttpsError(
        'unavailable',
        'Your code was correct but we could not finish. Please try again in a moment.',
      );
    }

    return { ok: true };
  },
);

module.exports = { requestEmailOtp, verifyEmailOtp };
