'use strict';

const { Timestamp } = require('firebase-admin/firestore');
const {
  MIRRORED_FIELDS,
  FORBIDDEN_PUBLIC_KEYS,
  deepEqual,
  computeMirrorPatch,
} = require('../src/publicProfileMirror');

const guideUser = () => ({
  email: 'guide@example.com',
  phone: '+910000000000',
  verifiedRealName: 'Legal Name',
  displayName: 'Guide',
  verificationBadge: 'verified_student',
  verificationStatus: 'approved',
  isVerified: true,
  communicationSettings: { isGuideAvailable: true, videoCallsEnabled: true },
  presence: {
    isOnline: true,
    availabilityStatus: 'available',
    lastSeenAt: Timestamp.fromMillis(1_700_000_000_000),
  },
});

describe('computeMirrorPatch', () => {
  it('is a no-op when the mirror already matches (the per-heartbeat common case)', () => {
    const user = guideUser();
    const mirror = {
      displayName: 'Guide',
      verificationBadge: 'verified_student',
      verificationStatus: 'approved',
      isVerified: true,
      communicationSettings: { videoCallsEnabled: true, isGuideAvailable: true },
      presence: {
        availabilityStatus: 'available',
        isOnline: true,
        lastSeenAt: Timestamp.fromMillis(1_700_000_000_000),
      },
    };
    expect(computeMirrorPatch(user, mirror)).toBeNull();
  });

  it('repairs a legacy locked mirror: syncs availability + presence and strips PII', () => {
    // Written before the PII hardening: carries verifiedRealName, so every
    // client write since was rule-denied and it froze with guide mode off.
    const mirror = {
      displayName: 'Guide',
      verifiedRealName: 'Legal Name',
      verificationBadge: 'verified_student',
      verificationStatus: 'approved',
      isVerified: true,
      communicationSettings: { isGuideAvailable: false },
      presence: { isOnline: false, availabilityStatus: 'offline' },
    };
    const patch = computeMirrorPatch(guideUser(), mirror);
    expect(patch.set.communicationSettings.isGuideAvailable).toBe(true);
    expect(patch.set.presence.availabilityStatus).toBe('available');
    expect(patch.deleteKeys).toEqual(['verifiedRealName']);
  });

  it('copies verification onto a mirror that never received it', () => {
    const patch = computeMirrorPatch(guideUser(), { displayName: 'Guide' });
    expect(patch.set.verificationBadge).toBe('verified_student');
    expect(patch.set.verificationStatus).toBe('approved');
  });

  it('never copies private fields, even when the mirror is missing entirely', () => {
    const patch = computeMirrorPatch(guideUser(), null);
    for (const key of FORBIDDEN_PUBLIC_KEYS) {
      expect(patch.set).not.toHaveProperty(key);
    }
    expect(patch.set).not.toHaveProperty('displayName'); // outside the allowlist
    expect(Object.keys(patch.set).every((k) => MIRRORED_FIELDS.includes(k))).toBe(true);
  });

  it('does not invent fields the users doc lacks', () => {
    const patch = computeMirrorPatch({ isVerified: false }, { isVerified: true });
    expect(patch.set).toEqual({ isVerified: false });
  });

  it('propagates a revoked verification', () => {
    const user = { ...guideUser(), verificationStatus: 'rejected', verificationBadge: 'none' };
    const patch = computeMirrorPatch(user, guideUser());
    expect(patch.set.verificationStatus).toBe('rejected');
    expect(patch.set.verificationBadge).toBe('none');
  });
});

describe('deepEqual', () => {
  it('compares Firestore Timestamps by value', () => {
    expect(deepEqual(Timestamp.fromMillis(5000), Timestamp.fromMillis(5000))).toBe(true);
    expect(deepEqual(Timestamp.fromMillis(5000), Timestamp.fromMillis(6000))).toBe(false);
  });

  it('ignores key order and treats null/undefined alike', () => {
    expect(deepEqual({ a: 1, b: null }, { b: undefined, a: 1 })).toBe(true);
    expect(deepEqual({ a: [1, 2] }, { a: [2, 1] })).toBe(false);
  });
});
