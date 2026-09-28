'use strict';

// Pure policy for the free trial call ("2 minutes free, once per day, per
// guide") -- no Firestore handles, so every rule is unit-testable
// (test/freeTrialCallLogic.test.js). freeTrialCalls.js is the thin
// Firestore/callable wrapper around it.
//
// Mirrored client-side in lib/core/constants/communication_constants.dart
// (freeTrialCallSeconds) and FreeTrialCallService.dayKeyFor -- the server
// is the only one whose answer counts; the client copy just lets the UI
// show the "already used" popup without a round trip.

const FREE_TRIAL_SECONDS = 120;

// How long a free-trial call may ring unanswered before the reservation is
// released (the caller didn't get to talk, so they haven't "used" it).
const RING_TIMEOUT_SECONDS = 60;

// Clients auto-disconnect at FREE_TRIAL_SECONDS; the server sweeper only
// steps in once a call is this far past the limit (e.g. both apps killed).
const OVERRUN_GRACE_SECONDS = 15;

// "Per day" is an India calendar day. IST is a fixed +05:30 with no DST,
// so a plain offset is exact.
const DAY_TZ_OFFSET_MINUTES = 330;

const USAGE_STATUS = Object.freeze({
  RESERVED: 'reserved', // call requested, not yet connected
  CONSUMED: 'consumed', // connected at least once -> today's free call is used
});

// Mirrors CommunicationConstants call statuses.
const CALL_STATUS = Object.freeze({
  REQUESTED: 'requested',
  ACCEPTED: 'accepted',
  ACTIVE: 'active',
  ENDED: 'ended',
  REJECTED: 'rejected',
  EMERGENCY_ENDED: 'emergency_ended',
  MISSED: 'missed',
});

const ENDED_STATUSES = Object.freeze([
  CALL_STATUS.ENDED,
  CALL_STATUS.REJECTED,
  CALL_STATUS.EMERGENCY_ENDED,
  CALL_STATUS.MISSED,
]);

const DENIAL_REASON = Object.freeze({
  FREE_CALL_USED: 'free_call_used',
  CALL_IN_PROGRESS: 'call_in_progress',
});

const VALID_CALL_TYPES = Object.freeze(['voice', 'video']);

function isEndedStatus(status) {
  return ENDED_STATUSES.includes(status);
}

/** `YYYY-MM-DD` of the IST calendar day containing `ms`. */
function dayKeyFor(ms) {
  return new Date(ms + DAY_TZ_OFFSET_MINUTES * 60 * 1000)
    .toISOString()
    .slice(0, 10);
}

/**
 * One doc per (caller, guide, day). The deterministic id is what makes
 * "once per day per guide" enforceable in a single transactional read --
 * no query, no race between two simultaneous taps.
 */
function usageDocId(callerId, guideId, dayKey) {
  return `${callerId}_${guideId}_${dayKey}`;
}

function parseMs(iso) {
  const ms = Date.parse(iso || '');
  return Number.isFinite(ms) ? ms : null;
}

/**
 * Decides whether a new free trial call may start, given today's usage doc
 * for this (caller, guide) pair and the session it points at.
 *
 * @param {object|null} usage   free_call_usage doc data, or null
 * @param {object|null} session call_sessions doc data for usage.sessionId
 * @param {number} nowMs
 * @returns {{allowed: true, supersedesSessionId?: string} |
 *           {allowed: false, reason: string}}
 */
function evaluateFreeTrialUsage(usage, session, nowMs) {
  if (!usage) return { allowed: true };

  // Once a call has connected, today's free call for this guide is gone,
  // however short it was. `session.startedAt` covers the few seconds
  // before the trigger flips the usage doc to CONSUMED.
  if (usage.status === USAGE_STATUS.CONSUMED || (session && session.startedAt)) {
    return { allowed: false, reason: DENIAL_REASON.FREE_CALL_USED };
  }

  // RESERVED and never connected: if it's still ringing, don't start a
  // second parallel call to the same guide...
  const sessionLive = session && !isEndedStatus(session.status);
  const createdMs = parseMs(usage.createdAt);
  const stillRinging =
    sessionLive &&
    createdMs !== null &&
    nowMs - createdMs < RING_TIMEOUT_SECONDS * 1000;
  if (stillRinging) {
    return { allowed: false, reason: DENIAL_REASON.CALL_IN_PROGRESS };
  }

  // ...otherwise it was never answered: the reservation is dead, the user
  // hasn't talked to this guide yet, so let them try again.
  return { allowed: true, supersedesSessionId: usage.sessionId || undefined };
}

/** Seconds of the free call actually used, clamped to [0, limit]. */
function durationUsedSeconds(startedAtIso, endedAtIso) {
  const start = parseMs(startedAtIso);
  const end = parseMs(endedAtIso);
  if (start === null || end === null) return 0;
  const secs = Math.round((end - start) / 1000);
  return Math.min(Math.max(secs, 0), FREE_TRIAL_SECONDS);
}

/**
 * How a call_sessions update should change its free_call_usage doc.
 * Returns null when the update is irrelevant (ratings, accept flags...).
 */
function usageTransition(before, after) {
  const endedNow = !isEndedStatus(before.status) && isEndedStatus(after.status);
  const connectedNow = !before.startedAt && !!after.startedAt;

  if (endedNow) {
    if (!after.startedAt) return { type: 'release' };
    return {
      type: 'finish',
      fields: {
        status: USAGE_STATUS.CONSUMED,
        connectedAt: after.startedAt,
        endedAt: after.endedAt || null,
        durationUsedSeconds: durationUsedSeconds(after.startedAt, after.endedAt),
      },
    };
  }
  if (connectedNow) {
    return {
      type: 'consume',
      fields: { status: USAGE_STATUS.CONSUMED, connectedAt: after.startedAt },
    };
  }
  return null;
}

/** ISO cutoffs for the sweeper's two queries. */
function sweepCutoffs(nowMs) {
  return {
    overrunStartedBefore: new Date(
      nowMs - (FREE_TRIAL_SECONDS + OVERRUN_GRACE_SECONDS) * 1000,
    ).toISOString(),
    unansweredCreatedBefore: new Date(
      nowMs - RING_TIMEOUT_SECONDS * 1000,
    ).toISOString(),
  };
}

module.exports = {
  FREE_TRIAL_SECONDS,
  RING_TIMEOUT_SECONDS,
  OVERRUN_GRACE_SECONDS,
  USAGE_STATUS,
  CALL_STATUS,
  DENIAL_REASON,
  VALID_CALL_TYPES,
  isEndedStatus,
  dayKeyFor,
  usageDocId,
  evaluateFreeTrialUsage,
  durationUsedSeconds,
  usageTransition,
  sweepCutoffs,
};
