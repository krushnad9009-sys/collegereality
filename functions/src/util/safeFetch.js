'use strict';

// Guards for the two places a Cloud Function fetches something a CLIENT
// named: the AI college-listing agent (a submitter's `website` / campus
// `photoUrl`) and the student-doc agent (a submitter's `storagePath`).
// Without these, a submitter can:
//   - point `storagePath` / a bucket-path `photoUrl` at ANY object in the
//     bucket (another user's ID doc, resume, …) — the Admin SDK bypasses
//     Storage rules — and read the extracted contents back off their own
//     request doc  → IDOR / PII exfiltration.
//   - point `website` at an internal address (link-local metadata, a
//     private RFC1918 host, localhost) → SSRF.

const { HttpsError } = require('firebase-functions/v2/https');

/**
 * A Cloud Storage object path a request doc carries must live under that
 * requester's own folder. Throws (caller turns it into a FLAG) otherwise.
 *
 * @param {string} path       e.g. "verification_documents/<uid>/<file>"
 * @param {string} ownerUid   the request doc's userId
 * @param {string[]} roots    allowed top-level folders for this feature
 */
function assertOwnedStoragePath(path, ownerUid, roots) {
  if (typeof path !== 'string' || !path.trim()) {
    throw new HttpsError('invalid-argument', 'Missing document path.');
  }
  const clean = path.trim().replace(/^\/+/, '');
  if (clean.includes('..')) {
    throw new HttpsError('permission-denied', 'Invalid document path.');
  }
  const parts = clean.split('/');
  if (parts.length < 3 || !roots.includes(parts[0]) || parts[1] !== ownerUid) {
    throw new HttpsError(
      'permission-denied',
      'Document path does not belong to the requester.',
    );
  }
  return clean;
}

// Hostnames / IP-literals that must never be fetched server-side.
const BLOCKED_HOST_EXACT = new Set([
  'localhost',
  'metadata',
  'metadata.google.internal',
  'metadata.goog',
  '0.0.0.0',
  '::1',
  '[::1]',
]);

function isPrivateIpv4(host) {
  const m = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(host);
  if (!m) return false;
  const [a, b] = [Number(m[1]), Number(m[2])];
  if (a === 10 || a === 127 || a === 0) return true; // private / loopback / this-host
  if (a === 169 && b === 254) return true; // link-local (cloud metadata)
  if (a === 172 && b >= 16 && b <= 31) return true; // private
  if (a === 192 && b === 168) return true; // private
  if (a === 100 && b >= 64 && b <= 127) return true; // CGNAT
  return false;
}

/**
 * Parse + vet a client-supplied URL for a server-side `fetch`. Returns the
 * normalised `URL`. Throws on a non-http(s) scheme or a non-public host.
 * NOTE: this validates the URL as written — callers that follow redirects
 * must re-run this on every hop (see fetchWithHostGuard).
 */
function assertPublicHttpUrl(rawUrl) {
  if (typeof rawUrl !== 'string' || !rawUrl.trim()) {
    throw new HttpsError('invalid-argument', 'Missing URL.');
  }
  let url;
  try {
    const withScheme = /^[a-z][a-z0-9+.-]*:\/\//i.test(rawUrl.trim())
      ? rawUrl.trim()
      : `https://${rawUrl.trim()}`;
    url = new URL(withScheme);
  } catch {
    throw new HttpsError('invalid-argument', 'Malformed URL.');
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    throw new HttpsError('permission-denied', 'Only http(s) URLs are allowed.');
  }
  const host = url.hostname.toLowerCase().replace(/^\[|\]$/g, '');
  if (
    BLOCKED_HOST_EXACT.has(host) ||
    host.endsWith('.internal') ||
    host.endsWith('.local') ||
    host === 'metadata.google.internal' ||
    isPrivateIpv4(host) ||
    host.startsWith('fe80:') || // ipv6 link-local
    host.startsWith('fc') || host.startsWith('fd') || // ipv6 ULA
    host === ''
  ) {
    throw new HttpsError('permission-denied', 'That host is not reachable.');
  }
  return url;
}

/**
 * `fetch` that re-validates the host on every redirect hop (so an
 * allowed apex can't 302 to `http://169.254.169.254/…`). Returns the final
 * `Response`, or throws if a hop points somewhere non-public / too many
 * hops. Timeout + abort handled by the caller's `signal`.
 */
async function fetchWithHostGuard(rawUrl, init = {}, maxHops = 3) {
  let current = assertPublicHttpUrl(rawUrl).toString();
  for (let hop = 0; hop <= maxHops; hop++) {
    const res = await fetch(current, { ...init, redirect: 'manual' });
    if (res.status >= 300 && res.status < 400 && res.headers.get('location')) {
      const next = new URL(res.headers.get('location'), current).toString();
      assertPublicHttpUrl(next); // throws if the redirect target is private
      current = next;
      continue;
    }
    return res;
  }
  throw new HttpsError('deadline-exceeded', 'Too many redirects.');
}

module.exports = {
  assertOwnedStoragePath,
  assertPublicHttpUrl,
  fetchWithHostGuard,
  isPrivateIpv4,
};
