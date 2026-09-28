'use strict';

// READ-ONLY diagnostic: why does the guide directory ("Talk to a Verified
// Student/Alumni") say "No guides are online right now"?
//
// For every user with guide mode ON in their own `users` doc, compares it
// with the `public_profiles` mirror that the directory actually queries.
// Prints flags, field NAMES and ages only -- never names, emails, phones.
// Writes nothing.
//
// Run from functions/ with credentials for the project, e.g.:
//   gcloud auth application-default login
//   node scripts/diagnoseGuideDirectory.js

const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { FORBIDDEN_PUBLIC_KEYS } = require('../src/publicProfileMirror');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'college-reality';
const STALE_AFTER_MS = 5 * 60 * 1000; // ConsultationConstants.presenceStaleAfter

initializeApp({ projectId: PROJECT_ID });
const db = getFirestore();

const isVerified = (d) =>
  d.verificationStatus === 'approved' &&
  ['verified_student', 'verified_alumni'].includes(d.verificationBadge);

function lastSeenAgeSec(presence) {
  const raw = presence && presence.lastSeenAt;
  if (!raw) return null;
  const ms = typeof raw.toMillis === 'function' ? raw.toMillis() : Date.parse(raw);
  return Number.isFinite(ms) ? Math.round((Date.now() - ms) / 1000) : null;
}

function liveOnline(d) {
  const p = d.presence || {};
  const age = lastSeenAgeSec(p);
  return p.availabilityStatus === 'available' && age !== null && age * 1000 < STALE_AFTER_MS;
}

async function main() {
  const [usersSnap, mirrorSnap] = await Promise.all([
    db.collection('users').where('communicationSettings.isGuideAvailable', '==', true).get(),
    db.collection('public_profiles')
      .where('communicationSettings.isGuideAvailable', '==', true).get(),
  ]);

  console.log(`project: ${PROJECT_ID}`);
  console.log(`users with guide mode ON:           ${usersSnap.size}`);
  console.log(`public_profiles with guide mode ON: ${mirrorSnap.size}  <- what the directory sees\n`);

  const rows = [];
  for (const doc of usersSnap.docs) {
    const u = doc.data();
    const m = (await db.collection('public_profiles').doc(doc.id).get()).data() || null;
    rows.push({
      uid: `${doc.id.slice(0, 6)}…`,
      mirrorExists: !!m,
      mirrorGuideOn: !!(m && m.communicationSettings && m.communicationSettings.isGuideAvailable),
      verifiedUsers: isVerified(u),
      verifiedMirror: !!m && isVerified(m),
      lockedByKeys: m ? FORBIDDEN_PUBLIC_KEYS.filter((k) => k in m).join(',') || '-' : 'n/a',
      availUsers: (u.presence && u.presence.availabilityStatus) || '-',
      availMirror: (m && m.presence && m.presence.availabilityStatus) || '-',
      seenAgoMirrorSec: m ? lastSeenAgeSec(m.presence) : null,
      liveOnlineForViewers: !!m && liveOnline(m),
    });
  }
  console.table(rows);
  console.log(
    '\nReading it: mirrorGuideOn=false or availMirror != availUsers means the mirror is\n' +
    'stale; a non-"-" lockedByKeys means firestore.rules reject every client write to\n' +
    'that mirror (onUserWriteSyncPublicProfile repairs it on the guide\'s next write).',
  );
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
