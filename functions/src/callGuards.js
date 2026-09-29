'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const { db } = require('./admin');
const { VALID_CALL_TYPES } = require('./freeTrialCallLogic');

const MAX_CALL_REQUESTS_PER_HOUR = 10; // was CommunicationConstants.maxCallRequestsPerHour

/**
 * Checks shared by every way of starting a direct guide call (free trial
 * and wallet-paid): valid input, not calling yourself, no block in either
 * direction, guide in guide mode, video allowed, request rate limit.
 *
 * @returns {Promise<{guideId: string, callType: string, caller: object, guide: object}>}
 */
async function assertCanCallGuide(uid, data) {
  const guideId = data && data.guideId;
  const callType = data && data.callType;
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
  return { guideId, callType, caller, guide };
}

module.exports = { assertCanCallGuide };
