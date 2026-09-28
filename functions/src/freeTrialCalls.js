'use strict';

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { logger } = require('firebase-functions');
const { db } = require('./admin');
const {
  FREE_TRIAL_SECONDS,
  USAGE_STATUS,
  CALL_STATUS,
  DENIAL_REASON,
  VALID_CALL_TYPES,
  isEndedStatus,
  dayKeyFor,
  usageDocId,
  evaluateFreeTrialUsage,
  usageTransition,
  sweepCutoffs,
} = require('./freeTrialCallLogic');

const MAX_CALL_REQUESTS_PER_HOUR = 10; // was CommunicationConstants.maxCallRequestsPerHour

const DENIAL_MESSAGES = {
  [DENIAL_REASON.FREE_CALL_USED]:
    'You have used your 2-minute free call for this Guide today. ' +
    'Please recharge/pay to continue calling.',
  [DENIAL_REASON.CALL_IN_PROGRESS]:
    'You already have a call ringing with this Guide. Please wait for them to answer.',
};

/**
 * The ONLY way to create a direct guide call (`call_sessions`; firestore
 * rules deny client creates). Checks, in one transaction, that this
 * (caller, guide) pair hasn't used today's free call, then creates the
 * session with the server-decided `maxDurationSeconds` and reserves the
 * quota -- so "once per day per guide" holds even against a modified
 * client or two simultaneous taps.
 *
 * Denials use `resource-exhausted` with `details.reason` (see
 * DENIAL_REASON) so the app can show the "Pay Now" popup.
 */
const startFreeTrialCall = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

  const guideId = request.data && request.data.guideId;
  const callType = request.data && request.data.callType;
  if (typeof guideId !== 'string' || !guideId) {
    throw new HttpsError('invalid-argument', 'guideId is required.');
  }
  if (!VALID_CALL_TYPES.includes(callType)) {
    throw new HttpsError('invalid-argument', 'callType must be voice or video.');
  }
  if (guideId === uid) {
    throw new HttpsError('invalid-argument', 'You cannot call yourself.');
  }

  const blocks = db.collection('user_blocks');
  const [blockedByMe, blockedMe, callerSnap, guideSnap, recentCalls] =
    await Promise.all([
      blocks.where('blockerId', '==', uid).where('blockedId', '==', guideId).limit(1).get(),
      blocks.where('blockerId', '==', guideId).where('blockedId', '==', uid).limit(1).get(),
      db.collection('users').doc(uid).get(),
      db.collection('public_profiles').doc(guideId).get(),
      db
        .collection('call_sessions')
        .where('callerId', '==', uid)
        .where('createdAt', '>', new Date(Date.now() - 60 * 60 * 1000).toISOString())
        .get(),
    ]);

  if (!blockedByMe.empty || !blockedMe.empty) {
    throw new HttpsError('failed-precondition', 'Unable to connect with this guide.');
  }
  if (!callerSnap.exists || !guideSnap.exists) {
    throw new HttpsError('not-found', 'User not found.');
  }
  const caller = callerSnap.data();
  const guide = guideSnap.data();
  const settings = guide.communicationSettings || {};
  if (settings.isGuideAvailable !== true) {
    throw new HttpsError('failed-precondition', 'This guide is not available.');
  }
  if (callType === 'video' && settings.videoCallsEnabled === false) {
    throw new HttpsError('failed-precondition', 'Video calls are disabled for this guide.');
  }
  if (recentCalls.size >= MAX_CALL_REQUESTS_PER_HOUR) {
    throw new HttpsError(
      'resource-exhausted',
      'Too many call requests. Please wait before trying again.',
      { reason: 'rate_limited' },
    );
  }

  const nowMs = Date.now();
  const nowIso = new Date(nowMs).toISOString();
  const dayKey = dayKeyFor(nowMs);
  const usageId = usageDocId(uid, guideId, dayKey);
  const usageRef = db.collection('free_call_usage').doc(usageId);
  const sessionRef = db.collection('call_sessions').doc();

  await db.runTransaction(async (tx) => {
    const usageSnap = await tx.get(usageRef);
    const usage = usageSnap.exists ? usageSnap.data() : null;
    const prevRef = usage && usage.sessionId
      ? db.collection('call_sessions').doc(usage.sessionId)
      : null;
    const prevSnap = prevRef ? await tx.get(prevRef) : null;
    const prevSession = prevSnap && prevSnap.exists ? prevSnap.data() : null;

    const decision = evaluateFreeTrialUsage(usage, prevSession, nowMs);
    if (!decision.allowed) {
      throw new HttpsError('resource-exhausted', DENIAL_MESSAGES[decision.reason], {
        reason: decision.reason,
        guideId,
      });
    }

    // A dead, never-answered reservation is being replaced: close its
    // session so the guide's phone stops showing it as ringing. The
    // trigger ignores it (usage.sessionId now points at the new session).
    if (prevRef && prevSession && !isEndedStatus(prevSession.status)) {
      tx.update(prevRef, {
        status: CALL_STATUS.MISSED,
        endedAt: nowIso,
        endedBy: 'system',
      });
    }

    // Same shape the app's CallSessionModel reads.
    tx.set(sessionRef, {
      id: sessionRef.id,
      callerId: uid,
      calleeId: guideId,
      callType,
      status: CALL_STATUS.REQUESTED,
      callerAccepted: true,
      calleeAccepted: false,
      callerAlias: caller.anonymousGuideAlias || 'Student',
      calleeAlias: guide.anonymousGuideAlias || 'Guide',
      callerTier: caller.subscriptionTier || 'free',
      calleeTier: guide.subscriptionTier || 'free',
      maxDurationSeconds: FREE_TRIAL_SECONDS,
      isFreeTrial: true,
      freeUsageId: usageId,
      createdAt: nowIso,
      startedAt: null,
      endedAt: null,
      endedBy: null,
      isEmergencyEnd: false,
      ratingsSubmittedCaller: false,
      ratingsSubmittedCallee: false,
    });

    // The call log for this (user, guide, day).
    tx.set(usageRef, {
      callerId: uid,
      guideId,
      dayKey,
      sessionId: sessionRef.id,
      callType,
      status: USAGE_STATUS.RESERVED,
      lastFreeCallAt: nowIso,
      createdAt: nowIso,
      connectedAt: null,
      endedAt: null,
      durationUsedSeconds: 0,
      freeLimitSeconds: FREE_TRIAL_SECONDS,
    });
  });

  return { sessionId: sessionRef.id, maxDurationSeconds: FREE_TRIAL_SECONDS };
});

/**
 * Keeps free_call_usage in step with the call the clients drive:
 *   connected            -> CONSUMED (today's free call for this guide used)
 *   ended after connect  -> record endedAt + durationUsedSeconds
 *   ended, never connected (declined / missed) -> reservation released,
 *                           the user hasn't actually talked to the guide
 */
const onFreeTrialCallUpdated = onDocumentUpdated(
  'call_sessions/{sessionId}',
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!after.isFreeTrial || !after.freeUsageId) return;

    const transition = usageTransition(before, after);
    if (!transition) return;

    const sessionId = event.params.sessionId;
    const usageRef = db.collection('free_call_usage').doc(after.freeUsageId);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(usageRef);
      // Superseded by a newer call to the same guide -- not ours to touch.
      if (!snap.exists || snap.data().sessionId !== sessionId) return;
      if (transition.type === 'release') {
        tx.delete(usageRef);
      } else {
        tx.update(usageRef, transition.fields);
      }
    });
  },
);

/**
 * Server backstop for when neither app is around to hang up (both killed,
 * offline): ends free calls running past the limit + grace, and marks
 * calls nobody answered as missed (which releases their reservation).
 */
const sweepFreeTrialCalls = onSchedule('every 1 minutes', async () => {
  const nowIso = new Date().toISOString();
  const { overrunStartedBefore, unansweredCreatedBefore } = sweepCutoffs(Date.now());
  const sessions = db.collection('call_sessions');

  const [overrun, unanswered] = await Promise.all([
    sessions
      .where('isFreeTrial', '==', true)
      .where('status', '==', CALL_STATUS.ACTIVE)
      .where('startedAt', '<', overrunStartedBefore)
      .limit(200)
      .get(),
    sessions
      .where('isFreeTrial', '==', true)
      .where('status', 'in', [CALL_STATUS.REQUESTED, CALL_STATUS.ACCEPTED])
      .where('createdAt', '<', unansweredCreatedBefore)
      .limit(200)
      .get(),
  ]);

  const batch = db.batch();
  for (const doc of overrun.docs) {
    batch.update(doc.ref, {
      status: CALL_STATUS.ENDED,
      endedAt: nowIso,
      endedBy: 'system',
    });
  }
  for (const doc of unanswered.docs) {
    batch.update(doc.ref, {
      status: CALL_STATUS.MISSED,
      endedAt: nowIso,
      endedBy: 'system',
    });
  }
  if (overrun.empty && unanswered.empty) return;
  await batch.commit();
  logger.info(
    `sweepFreeTrialCalls: ended ${overrun.size} overrun, ${unanswered.size} unanswered`,
  );
});

module.exports = { startFreeTrialCall, onFreeTrialCallUpdated, sweepFreeTrialCalls };
