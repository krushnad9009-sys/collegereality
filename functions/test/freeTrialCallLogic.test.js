'use strict';

const {
  FREE_TRIAL_SECONDS,
  RING_TIMEOUT_SECONDS,
  OVERRUN_GRACE_SECONDS,
  USAGE_STATUS,
  DENIAL_REASON,
  dayKeyFor,
  usageDocId,
  evaluateFreeTrialUsage,
  durationUsedSeconds,
  usageTransition,
  sweepCutoffs,
  remainingFreeSeconds,
} = require('../src/freeTrialCallLogic');
const { Timestamp } = require('firebase-admin/firestore');

const NOW = Date.parse('2026-09-28T10:00:00.000Z');
const iso = (ms) => new Date(ms).toISOString();

describe('dayKeyFor (IST calendar day)', () => {
  it('rolls over at IST midnight, not UTC midnight', () => {
    // 18:29:59Z = 23:59:59 IST; 18:30:00Z = 00:00 IST next day.
    expect(dayKeyFor(Date.parse('2026-09-28T18:29:59Z'))).toBe('2026-09-28');
    expect(dayKeyFor(Date.parse('2026-09-28T18:30:00Z'))).toBe('2026-09-29');
  });

  it('a UTC-evening-before call is already "today" in India', () => {
    expect(dayKeyFor(Date.parse('2026-09-27T20:00:00Z'))).toBe('2026-09-28');
  });
});

describe('usageDocId', () => {
  it('is distinct per guide and per day for the same caller', () => {
    const a = usageDocId('userA', 'guide1', '2026-09-28');
    expect(a).not.toBe(usageDocId('userA', 'guide2', '2026-09-28'));
    expect(a).not.toBe(usageDocId('userA', 'guide1', '2026-09-29'));
  });
});

describe('evaluateFreeTrialUsage', () => {
  it('allows the first call to a guide today', () => {
    expect(evaluateFreeTrialUsage(null, null, NOW)).toEqual({ allowed: true });
  });

  it('blocks once the free call to this guide has been consumed', () => {
    const usage = { status: USAGE_STATUS.CONSUMED, sessionId: 's1', createdAt: iso(NOW - 3600e3) };
    expect(evaluateFreeTrialUsage(usage, { status: 'ended', startedAt: iso(NOW - 3500e3) }, NOW))
      .toEqual({ allowed: false, reason: DENIAL_REASON.FREE_CALL_USED });
  });

  it('blocks on a connected session even before the trigger marks it consumed', () => {
    const usage = { status: USAGE_STATUS.RESERVED, sessionId: 's1', createdAt: iso(NOW - 5e3) };
    const session = { status: 'active', startedAt: iso(NOW - 2e3) };
    expect(evaluateFreeTrialUsage(usage, session, NOW).reason)
      .toBe(DENIAL_REASON.FREE_CALL_USED);
  });

  it('blocks a second parallel call while the first is still ringing', () => {
    const usage = { status: USAGE_STATUS.RESERVED, sessionId: 's1', createdAt: iso(NOW - 10e3) };
    expect(evaluateFreeTrialUsage(usage, { status: 'requested' }, NOW))
      .toEqual({ allowed: false, reason: DENIAL_REASON.CALL_IN_PROGRESS });
  });

  it('lets the user retry after an unanswered call rang out', () => {
    const usage = {
      status: USAGE_STATUS.RESERVED,
      sessionId: 's1',
      createdAt: iso(NOW - (RING_TIMEOUT_SECONDS + 1) * 1000),
    };
    expect(evaluateFreeTrialUsage(usage, { status: 'requested' }, NOW))
      .toEqual({ allowed: true, supersedesSessionId: 's1' });
  });

  it('lets the user retry after the guide declined (never connected)', () => {
    const usage = { status: USAGE_STATUS.RESERVED, sessionId: 's1', createdAt: iso(NOW - 5e3) };
    expect(evaluateFreeTrialUsage(usage, { status: 'rejected' }, NOW).allowed).toBe(true);
  });
});

describe('durationUsedSeconds', () => {
  it('measures the connected time', () => {
    expect(durationUsedSeconds(iso(NOW), iso(NOW + 45e3))).toBe(45);
  });

  it('never records more than the free limit', () => {
    expect(durationUsedSeconds(iso(NOW), iso(NOW + 500e3))).toBe(FREE_TRIAL_SECONDS);
  });

  it('is 0 for missing or reversed timestamps', () => {
    expect(durationUsedSeconds(null, iso(NOW))).toBe(0);
    expect(durationUsedSeconds(iso(NOW), iso(NOW - 5e3))).toBe(0);
  });
});

describe('usageTransition', () => {
  const requested = { status: 'requested', startedAt: null };
  const active = { status: 'active', startedAt: iso(NOW) };

  it('consumes the free call when the call connects', () => {
    expect(usageTransition(requested, active)).toEqual({
      type: 'consume',
      stampServerStart: true,
      fields: { status: USAGE_STATUS.CONSUMED, connectedAt: iso(NOW) },
    });
  });

  it('asks the trigger to stamp a server-clock start on connect', () => {
    expect(usageTransition(requested, active).stampServerStart).toBe(true);
  });

  it('measures duration on the server clock when serverStartedAt exists', () => {
    // The accepting phone's clock ran 10 minutes behind: its startedAt
    // string is useless, the server stamp is not.
    const ended = {
      status: 'ended',
      startedAt: iso(NOW - 600e3),
      endedAt: iso(NOW + 40e3),
      serverStartedAt: Timestamp.fromMillis(NOW),
    };
    expect(usageTransition(active, ended, NOW + 40e3).fields.durationUsedSeconds).toBe(40);
  });

  it('records the duration when a connected call ends', () => {
    const ended = { ...active, status: 'ended', endedAt: iso(NOW + 120e3) };
    const t = usageTransition(active, ended);
    expect(t.type).toBe('finish');
    expect(t.fields.durationUsedSeconds).toBe(120);
    expect(t.fields.status).toBe(USAGE_STATUS.CONSUMED);
  });

  it('releases the reservation when the call ends without connecting', () => {
    expect(usageTransition(requested, { status: 'rejected' })).toEqual({ type: 'release' });
    expect(usageTransition(requested, { status: 'missed' })).toEqual({ type: 'release' });
  });

  it('ignores updates that are neither connect nor end (ratings, accept flags)', () => {
    const ended = { status: 'ended', startedAt: iso(NOW), endedAt: iso(NOW + 5e3) };
    expect(usageTransition(ended, { ...ended, ratingsSubmittedCaller: true })).toBeNull();
    expect(usageTransition(requested, { ...requested, status: 'accepted' })).toBeNull();
  });
});

describe('sweepCutoffs', () => {
  it('only ends calls past the free limit plus grace', () => {
    const { overrunStartedBefore, unansweredCreatedBefore } = sweepCutoffs(NOW);
    expect(overrunStartedBefore.getTime())
      .toBe(NOW - (FREE_TRIAL_SECONDS + OVERRUN_GRACE_SECONDS) * 1000);
    expect(Date.parse(unansweredCreatedBefore)).toBe(NOW - RING_TIMEOUT_SECONDS * 1000);
  });
});

describe('remainingFreeSeconds', () => {
  it('counts down from the server-stamped start', () => {
    expect(remainingFreeSeconds(Timestamp.fromMillis(NOW), NOW + 45e3)).toBe(75);
    expect(remainingFreeSeconds(Timestamp.fromMillis(NOW), NOW + 500e3)).toBe(0);
  });

  it('assumes the full allowance before the start is stamped', () => {
    expect(remainingFreeSeconds(null, NOW)).toBe(FREE_TRIAL_SECONDS);
  });
});
