'use strict';

// `requestAccountDeletion` — user-initiated erasure of a College Reality
// account. Callable, auth required, and it deletes the caller's OWN
// account only (uid comes from the verified ID token, never from the
// payload).
//
// Why a Cloud Function and not the client: firestore.rules deliberately
// forbid a client from touching other users' content or most collections,
// a client cannot recursively delete subcollections, and it cannot sweep
// Cloud Storage. All writes here use the Admin SDK (bypasses rules).
//
// The plan (what is deleted vs anonymised vs retained) lives in
// accountDeletionPlan.js and is unit-tested there. This module is the
// executor: best-effort, idempotent, and safe to retry — every step is
// "delete if present" or "overwrite with a fixed value".

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');
const { FieldPath } = require('firebase-admin/firestore');
const { db } = require('./admin');
const plan = require('./accountDeletionPlan');
const { newCorrelationId } = require('./util/guards');

// The ID token must have been minted this recently for a deletion to be
// allowed — the same protection Firebase's own `user.delete()` enforces
// via `requires-recent-login`. A stale long-lived session cannot nuke an
// account; the user re-authenticates first.
const FRESH_AUTH_WINDOW_MS = 10 * 60 * 1000;

const PAGE = 300;
const nowIso = () => new Date().toISOString();

/** Delete every doc a query matches, paging so we never hold a huge set. */
async function deleteByQuery(baseQuery) {
  let total = 0;
  for (;;) {
    const snap = await baseQuery.limit(PAGE).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    total += snap.size;
    if (snap.size < PAGE) break;
  }
  return total;
}

/** Merge `patch` into every doc a query matches, paged. */
async function patchByQuery(baseQuery, patch) {
  let total = 0;
  for (;;) {
    const snap = await baseQuery.limit(PAGE).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.set(d.ref, patch, { merge: true }));
    await batch.commit();
    total += snap.size;
    if (snap.size < PAGE) break;
  }
  return total;
}

/**
 * Runs every phase of the plan for `uid`. Never throws for a Firestore /
 * Storage phase failure — it records the error and moves on, so one bad
 * collection cannot strand a half-deleted account. Returns
 * `{ summary, errors }`.
 */
async function eraseUserData(uid) {
  const summary = {};
  const errors = [];
  const step = async (name, fn) => {
    try {
      const n = await fn();
      if (typeof n === 'number' && n > 0) summary[name] = n;
    } catch (err) {
      logger.error(`[requestAccountDeletion] step "${name}" failed`, {
        uid,
        code: err && err.code,
        message: err && err.message,
      });
      errors.push({ step: name, message: (err && err.message) || 'unknown' });
    }
  };

  // 1. Docs whose id IS the uid.
  for (const col of plan.DELETE_DOC_BY_UID) {
    await step(`doc:${col}`, async () => {
      await db.collection(col).doc(uid).delete();
      return 1;
    });
  }
  for (const col of plan.DELETE_RECURSIVE_DOC_BY_UID) {
    await step(`docRecursive:${col}`, async () => {
      await db.recursiveDelete(db.collection(col).doc(uid));
      return 1;
    });
  }

  // 2. aiUsage/{uid}_{date} — documentId() prefix scan.
  await step('aiUsage', async () => {
    const { start, end } = plan.aiUsageIdRange(uid);
    const q = db
      .collection('aiUsage')
      .orderBy(FieldPath.documentId())
      .startAt(start)
      .endAt(end);
    return deleteByQuery(q);
  });

  // 3. Flat collections, delete where field == uid.
  for (const { collection, field } of plan.DELETE_BY_FIELD) {
    await step(`delete:${collection}.${field}`, () =>
      deleteByQuery(db.collection(collection).where(field, '==', uid)),
    );
  }

  // 4. Recurse: delete matching docs AND their subcollections.
  for (const { collection, field } of plan.DELETE_RECURSIVE_BY_FIELD) {
    await step(`deleteRecursive:${collection}.${field}`, async () => {
      let total = 0;
      for (;;) {
        const snap = await db
          .collection(collection)
          .where(field, '==', uid)
          .limit(50)
          .get();
        if (snap.empty) break;
        for (const d of snap.docs) {
          await db.recursiveDelete(d.ref);
          total += 1;
        }
        if (snap.size < 50) break;
      }
      return total;
    });
  }

  // 5. Anonymise flat collections (keep the row for others).
  for (const { collection, field, patch } of plan.ANONYMISE_BY_FIELD) {
    await step(`anon:${collection}.${field}`, () =>
      patchByQuery(db.collection(collection).where(field, '==', uid), {
        ...patch,
        updatedAt: nowIso(),
      }),
    );
  }

  // 6. Anonymise answers/replies on OTHER people's questions
  //    (collection-group; needs the authorId index — see
  //    firestore.indexes.json).
  for (const { group, field, patch } of plan.ANONYMISE_GROUP_BY_FIELD) {
    await step(`anonGroup:${group}.${field}`, () =>
      patchByQuery(db.collectionGroup(group).where(field, '==', uid), {
        ...patch,
        updatedAt: nowIso(),
      }),
    );
  }

  // 7. guide_reviews — PII-free public copies keyed by consultationId, so
  //    they can only be reached by walking the user's consultations.
  //    RETAIN consultations + payments themselves (financial record); we
  //    only touch the free-text review copy.
  await step('guideReviews', async () => {
    let touched = 0;
    // As the reviewing student: blank the comment they wrote.
    const asStudent = await db
      .collection('consultations')
      .where('studentId', '==', uid)
      .get();
    for (const c of asStudent.docs) {
      await db
        .collection('guide_reviews')
        .doc(c.id)
        .set({ comment: '', updatedAt: nowIso() }, { merge: true })
        .then(() => (touched += 1))
        .catch(() => {});
    }
    // As the guide being reviewed: the profile is gone, drop the review.
    const asGuide = await db
      .collection('consultations')
      .where('guideId', '==', uid)
      .get();
    for (const c of asGuide.docs) {
      await db
        .collection('guide_reviews')
        .doc(c.id)
        .delete()
        .then(() => (touched += 1))
        .catch(() => {});
    }
    return touched;
  });

  // 8. Cloud Storage object trees owned solely by this user.
  await step('storage', async () => {
    const bucket = getStorage().bucket();
    let prefixes = 0;
    for (const prefix of plan.storagePrefixesForUid(uid)) {
      try {
        await bucket.deleteFiles({ prefix, force: true });
        prefixes += 1;
      } catch (err) {
        logger.warn('[requestAccountDeletion] storage prefix failed', {
          prefix,
          message: err && err.message,
        });
      }
    }
    return prefixes;
  });

  return { summary, errors };
}

const requestAccountDeletion = onCall(
  { timeoutSeconds: 540, memory: '512MiB' },
  async (request) => {
    const auth = request.auth;
    const uid = auth && auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    // Recent-login gate (see FRESH_AUTH_WINDOW_MS).
    const authTimeSec = auth.token && auth.token.auth_time;
    const authTimeMs = typeof authTimeSec === 'number' ? authTimeSec * 1000 : 0;
    if (!authTimeMs || Date.now() - authTimeMs > FRESH_AUTH_WINDOW_MS) {
      throw new HttpsError(
        'failed-precondition',
        'For your security, sign out and sign back in, then delete your account.',
        { reason: 'requires-recent-login' },
      );
    }

    const confirm = request.data && request.data.confirm;
    if (confirm !== true) {
      throw new HttpsError(
        'invalid-argument',
        'Deletion must be explicitly confirmed.',
      );
    }

    logger.info('[requestAccountDeletion] start', { uid });

    const { summary, errors } = await eraseUserData(uid);

    // PII-free tombstone: uid + counts only. Lets support see that an
    // account was self-deleted (and when) without retaining anything
    // about the person.
    try {
      await db.collection('deleted_accounts').doc(uid).set({
        uid,
        deletedAt: nowIso(),
        summary,
        errorCount: errors.length,
        schemaVersion: 1,
      });
    } catch (err) {
      logger.warn('[requestAccountDeletion] tombstone write failed', {
        uid,
        message: err && err.message,
      });
    }

    // Auth user LAST — once this succeeds the credential is gone and the
    // client can only sign out. Treat "already gone" as success so a
    // retried call still resolves cleanly.
    try {
      await getAuth().deleteUser(uid);
    } catch (err) {
      if (err && err.code === 'auth/user-not-found') {
        logger.info('[requestAccountDeletion] auth user already removed', { uid });
      } else {
        const correlationId = newCorrelationId();
        logger.error('[requestAccountDeletion] auth deleteUser failed', {
          correlationId,
          uid,
          code: err && err.code,
        });
        throw new HttpsError(
          'internal',
          'Your data was removed but the login could not be deleted. '
            + 'Please try again.',
          { correlationId },
        );
      }
    }

    logger.info('[requestAccountDeletion] done', {
      uid,
      steps: Object.keys(summary).length,
      errorCount: errors.length,
    });

    return { ok: true, summary, hadErrors: errors.length > 0 };
  },
);

module.exports = { requestAccountDeletion, eraseUserData };
