'use strict';

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const crypto = require('crypto');
const { RtcTokenBuilder, RtcRole } = require('agora-token');
const { db } = require('./admin');
const { CONSULTATION_STATUS } = require('./consultationLogic');
const { AGORA_APP_ID, AGORA_APP_CERTIFICATE } = require('./params');

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

    // Deterministic small numeric uid Agora requires, derived from the
    // Firebase uid (stable per user, doesn't leak the real uid string).
    const numericUid =
      parseInt(crypto.createHash('sha256').update(uid).digest('hex').slice(0, 8), 16) %
      2147483647;

    const expireAt = Math.floor(Date.now() / 1000) + TOKEN_TTL_SECONDS;
    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID.value(),
      AGORA_APP_CERTIFICATE.value(),
      consultationId,
      numericUid,
      RtcRole.PUBLISHER,
      expireAt,
      expireAt,
    );

    return {
      appId: AGORA_APP_ID.value(),
      channelName: consultationId,
      token,
      uid: numericUid,
    };
  },
);

module.exports = { mintConsultationCallToken };
