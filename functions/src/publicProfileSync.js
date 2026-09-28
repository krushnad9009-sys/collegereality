'use strict';

const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const { FieldValue } = require('firebase-admin/firestore');
const { db } = require('./admin');
const { computeMirrorPatch } = require('./publicProfileMirror');

/**
 * Server-side backstop for the client's own public_profiles mirroring (see
 * publicProfileMirror.js for why client mirror writes can be permanently
 * denied). On every users/{uid} write, re-derive the directory-relevant
 * fields and strip legacy PII keys from the mirror. Reads first and only
 * writes when something actually differs, so the common case (the client
 * already mirrored successfully, e.g. each presence heartbeat) costs one
 * read and no write.
 */
const onUserWriteSyncPublicProfile = onDocumentWritten(
  'users/{uid}',
  async (event) => {
    const after = event.data && event.data.after;
    if (!after || !after.exists) return; // deletion: requestAccountDeletion owns it

    const uid = event.params.uid;
    const mirrorRef = db.collection('public_profiles').doc(uid);
    const mirrorSnap = await mirrorRef.get();
    const patch = computeMirrorPatch(
      after.data(),
      mirrorSnap.exists ? mirrorSnap.data() : null,
    );
    if (!patch) return;

    const update = { ...patch.set };
    for (const key of patch.deleteKeys) update[key] = FieldValue.delete();
    await mirrorRef.set(update, { merge: true });

    logger.info('[publicProfileSync] repaired mirror', {
      uid,
      fields: Object.keys(patch.set),
      removedKeys: patch.deleteKeys,
    });
  },
);

module.exports = { onUserWriteSyncPublicProfile };
