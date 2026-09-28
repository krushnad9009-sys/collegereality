'use strict';

// Pure policy for keeping `public_profiles/{uid}` (the PII-free mirror every
// cross-user screen reads -- guide directory, guide profile, presence) in
// step with the source-of-truth `users/{uid}` doc. No Firestore handles, so
// it is unit-testable (test/publicProfileMirror.test.js).
//
// Why this exists: the client mirrors its own writes
// (FirestoreUserService.syncPublicProfile), but firestore.rules evaluate
// the MERGED resulting mirror doc. A mirror written before the 2026-09-10
// PII hardening still carries e.g. `verifiedRealName`, so every later
// owner write to it -- `communicationSettings.isGuideAvailable`, the
// online toggle, heartbeats -- is denied, and syncPublicProfile swallows
// the error. The guide sees themselves online; everyone else sees a frozen
// mirror and "No guides are online right now". The server (Admin SDK,
// bypasses rules) repairs that from `users` on the next write.

// Fields the guide directory / presence / call gating depend on. Deliberately
// an allowlist, not "users minus PII": `users` also carries private,
// owner-only fields that must never be copied out wholesale.
const MIRRORED_FIELDS = Object.freeze([
  'communicationSettings',
  'presence',
  'verificationBadge',
  'verificationStatus',
  'isVerified',
]);

// Must never exist on the mirror (same list FirestoreUserService
// .syncPublicProfile strips; the first four are also rejected by
// firestore.rules). Present only on legacy docs -- deleted when found.
const FORBIDDEN_PUBLIC_KEYS = Object.freeze([
  'email',
  'phone',
  'verifiedRealName',
  'metadata',
  'preferredState',
  'preferredCategory',
  'categoryInteractionCounts',
]);

/** Structural equality that understands Firestore Timestamps / Dates. */
function deepEqual(a, b) {
  if (a === b) return true;
  if (a == null || b == null) return a == b; // null vs undefined: equal
  if (typeof a !== 'object' || typeof b !== 'object') return false;
  if (typeof a.isEqual === 'function') {
    try {
      return a.isEqual(b);
    } catch (_) {
      return false;
    }
  }
  if (a instanceof Date || b instanceof Date) {
    return a instanceof Date && b instanceof Date && a.getTime() === b.getTime();
  }
  if (Array.isArray(a) !== Array.isArray(b)) return false;
  if (Array.isArray(a)) {
    return a.length === b.length && a.every((v, i) => deepEqual(v, b[i]));
  }
  const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
  for (const k of keys) {
    if (!deepEqual(a[k], b[k])) return false;
  }
  return true;
}

/**
 * What must change on the mirror to match `users`, or null if it already
 * does. `set` is merged into the mirror; `deleteKeys` are removed from it.
 *
 * @param {object} userData   users/{uid} data (source of truth)
 * @param {object|null} mirrorData public_profiles/{uid} data, null if missing
 */
function computeMirrorPatch(userData, mirrorData) {
  const mirror = mirrorData || {};
  const set = {};
  for (const field of MIRRORED_FIELDS) {
    if (!(field in userData)) continue; // never invent a field users lacks
    if (!deepEqual(userData[field], mirror[field])) set[field] = userData[field];
  }
  const deleteKeys = FORBIDDEN_PUBLIC_KEYS.filter((k) => k in mirror);
  if (Object.keys(set).length === 0 && deleteKeys.length === 0) return null;
  return { set, deleteKeys };
}

module.exports = {
  MIRRORED_FIELDS,
  FORBIDDEN_PUBLIC_KEYS,
  deepEqual,
  computeMirrorPatch,
};
