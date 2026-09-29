'use strict';

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const crypto = require('crypto');
const { RtcTokenBuilder, RtcRole } = require('agora-token');
const { db } = require('./admin');
const { CONSULTATION_STATUS } = require('./consultationLogic');
const { AGORA_APP_ID, AGORA_APP_CERTIFICATE } = require('./params');
const { assertConfigured } = require('./util/guards');
const {
  CALL_STATUS,
  OVERRUN_GRACE_SECONDS,
  remainingFreeSeconds,
  remainingSecondsFor,
} = require('./freeTrialCallLogic');

const TOKEN_TTL_SECONDS = 60 * 60 * 2; // 2h — comfortably covers any priced duration

/**
 * Mints a short-lived Agora RTC join token. This is the trusted half of
 * "real voice/video calling" — proving the caller is a paid participant on
 * this exact consultation before any token is issued. The Flutter client
 * still needs the `agora_rtc_engine` SDK wired up to actually join with
 * this token; see functions/README.md and the main plan's §G for why that
 * SDK integration is tracked separately (it needs a real Agora project,
 * which this repo does not have credentials for).
 */
const mintConsultationCallToken = onCall(
  { secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const consultationId = request.data && request.data.consultationId;
    if (!consultationId) {
      throw new HttpsError('invalid-argument', 'consultationId is required.');
    }

    const snap = await db.collection('consultations').doc(consultationId).get();
    if (!snap.exists) throw new HttpsError('not-found', 'Consultation not found.');
    const consultation = snap.data();

    if (consultation.studentId !== uid && consultation.guideId !== uid) {
      throw new HttpsError('permission-denied', 'Not a participant.');
    }
    if (consultation.type === 'chat') {
      throw new HttpsError('failed-precondition', 'This consultation is chat, not a call.');
    }
    const joinableStates = [
      CONSULTATION_STATUS.PAID,
      CONSULTATION_STATUS.WAITING_FOR_GUIDE,
      CONSULTATION_STATUS.ACTIVE,
    ];
    if (!joinableStates.includes(consultation.status)) {
      throw new HttpsError(
        'failed-precondition',
        `Consultation is '${consultation.status}', not joinable.`,
      );
    }

    const numericUid = agoraUidFor(uid);
    const appId = assertConfigured(AGORA_APP_ID.value(), 'Calling');
    const appCertificate = assertConfigured(
      AGORA_APP_CERTIFICATE.value(),
      'Calling',
    );

    const expireAt = Math.floor(Date.now() / 1000) + TOKEN_TTL_SECONDS;
    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      consultationId,
      numericUid,
      RtcRole.PUBLISHER,
      expireAt,
      expireAt,
    );

    return {
      appId,
      channelName: consultationId,
      token,
      uid: numericUid,
    };
  },
);

/**
 * Deterministic small numeric uid Agora requires, derived from the
 * Firebase uid (stable per user, doesn't leak the real uid string).
 */
function agoraUidFor(uid) {
  return (
    parseInt(crypto.createHash('sha256').update(uid).digest('hex').slice(0, 8), 16) %
    2147483647
  );
}

/**
 * Agora join token for a direct guide call (`call_sessions`, created by
 * startFreeTrialCall). Only a participant of an ACTIVE session gets one.
 *
 * For a free trial call the token expires when the free time runs out
 * (server clock, `serverStartedAt`) plus a small grace: Agora itself then
 * drops both sides from the channel, so the 2-minute limit holds even if
 * neither app hangs up.
 */
const mintCallSessionToken = onCall(
  { secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const sessionId = request.data && request.data.sessionId;
    if (typeof sessionId !== 'string' || !sessionId) {
      throw new HttpsError('invalid-argument', 'sessionId is required.');
    }

    const snap = await db.collection('call_sessions').doc(sessionId).get();
    if (!snap.exists) throw new HttpsError('not-found', 'Call not found.');
    const session = snap.data();
    if (session.callerId !== uid && session.calleeId !== uid) {
      throw new HttpsError('permission-denied', 'Not a participant.');
    }
    if (session.status !== CALL_STATUS.ACTIVE) {
      throw new HttpsError(
        'failed-precondition',
        `Call is '${session.status}', not connected.`,
      );
    }

    const nowSec = Math.floor(Date.now() / 1000);
    // Free trial: what's left of the 2 minutes. Wallet call: what's left of
    // the talk time the balance paid for at start (maxDurationSeconds).
    const allowedSeconds = session.isFreeTrial
      ? remainingFreeSeconds(session.serverStartedAt, Date.now())
      : remainingSecondsFor(
          Number(session.maxDurationSeconds) || 0,
          session.serverStartedAt,
          Date.now(),
        );
    if (allowedSeconds <= 0) {
      throw new HttpsError('failed-precondition', 'This call has reached its time limit.');
    }
    const expireAt = nowSec + allowedSeconds + OVERRUN_GRACE_SECONDS;

    const appId = assertConfigured(AGORA_APP_ID.value(), 'Calling');
    const appCertificate = assertConfigured(AGORA_APP_CERTIFICATE.value(), 'Calling');
    const channelName = `call_${sessionId}`;
    const numericUid = agoraUidFor(uid);
    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      numericUid,
      RtcRole.PUBLISHER,
      expireAt,
      expireAt,
    );

    return { appId, channelName, token, uid: numericUid, expiresAt: expireAt };
  },
);

module.exports = { mintConsultationCallToken, mintCallSessionToken };
