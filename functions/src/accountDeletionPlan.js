'use strict';

// Declarative plan for `requestAccountDeletion` (see accountDeletion.js).
// Kept as a pure module — no Firestore/Storage/Auth handles — so the
// policy (what gets deleted vs anonymised vs retained) is reviewable and
// unit-testable on its own (test/accountDeletionPlan.test.js).
//
// ── Policy ───────────────────────────────────────────────────────────
//  DELETE     — data that is purely the departing user's and has no
//               value to anyone else once they are gone.
//  ANONYMISE  — content/records that must stay for OTHER people
//               (a college's review score, a guide's rating average, a
//               moderation record) but must no longer identify the user.
//  RETAIN     — `consultations` + `payments`: financial source-of-truth,
//               needed for reconciliation / refunds / disputes / tax.
//               They carry only opaque uids + amounts + gateway ids — no
//               name, email or phone — so the uid is left as an opaque
//               key. This is a deliberate, documented exception.

// Placeholder identity stamped onto anything we anonymise.
const ANON = Object.freeze({
  uid: 'deleted-account',
  name: '[deleted user]',
});

// `<collection>/<uid>` — the doc id IS the uid. Deleted outright (flat,
// no subcollections).
const DELETE_DOC_BY_UID = Object.freeze([
  'users',
  'public_profiles',
  'email_otps',
  'notification_preferences',
  'student_resumes',
]);

// `<collection>/<uid>` — doc id IS the uid, AND recurse into
// subcollections (`guide_earnings/{uid}/entries/*`).
const DELETE_RECURSIVE_DOC_BY_UID = Object.freeze([
  'guide_earnings',
]);

// Delete every doc in `collection` where `field == uid`. Flat collections
// only (no subcollections to worry about).
const DELETE_BY_FIELD = Object.freeze([
  { collection: 'verification_document_hashes', field: 'userId' },
  { collection: 'user_notifications', field: 'userId' },
  { collection: 'user_blocks', field: 'blockerId' },
  { collection: 'user_blocks', field: 'blockedId' },
  { collection: 'interaction_ratings', field: 'raterId' },
  { collection: 'student_chat_intents', field: 'seekerId' },
  { collection: 'student_chat_intents', field: 'peerId' },
  { collection: 'college_analytics_events', field: 'userId' },
  { collection: 'saved_scholarships', field: 'userId' },
  { collection: 'saved_internships', field: 'userId' },
  { collection: 'saved_jobs', field: 'userId' },
  { collection: 'saved_events', field: 'userId' },
  { collection: 'saved_entrance_exams', field: 'userId' },
  { collection: 'saved_questions', field: 'userId' },
  { collection: 'display_names', field: 'uid' },
]);

// Delete every doc where `field == uid` AND recurse into its
// subcollections. `college_questions` fans out to answers/replies/votes;
// `placement_submissions` carries a `private` subcollection.
const DELETE_RECURSIVE_BY_FIELD = Object.freeze([
  { collection: 'college_questions', field: 'authorId' },
  { collection: 'college_requests', field: 'userId' },
  { collection: 'verification_requests', field: 'userId' },
  { collection: 'placement_submissions', field: 'userId' },
]);

// Keep the row; overwrite the departing user's identity + free text.
const ANONYMISE_BY_FIELD = Object.freeze([
  {
    collection: 'reviews',
    field: 'userId',
    patch: {
      userId: ANON.uid,
      anonymousAlias: ANON.name,
      isAnonymous: true,
      course: null,
      batchYear: null,
    },
  },
  {
    // Private student<->guide rating. The scores stay (they feed the
    // counterparty's rating average); the free-text comment and the
    // rater's identity go.
    collection: 'consultation_ratings',
    field: 'raterId',
    patch: { raterId: ANON.uid, comment: '' },
  },
  {
    // Moderation record — retained for safety, reporter de-identified.
    collection: 'user_reports',
    field: 'reporterId',
    patch: { reporterId: ANON.uid },
  },
]);

// Collection-group anonymise: answers / replies the user wrote on OTHER
// people's questions (their own questions are recursively deleted above,
// which takes their answers/replies with them). Needs a collection-group
// single-field index on `authorId` (see firestore.indexes.json).
const ANONYMISE_GROUP_BY_FIELD = Object.freeze([
  {
    group: 'answers',
    field: 'authorId',
    patch: { authorId: ANON.uid, authorDisplayName: ANON.name, isAnonymous: true },
  },
  {
    group: 'replies',
    field: 'authorId',
    patch: { authorId: ANON.uid, authorDisplayName: ANON.name, isAnonymous: true },
  },
]);

// Cloud Storage object trees owned solely by this user. Each entry is a
// prefix under the default bucket; every object beneath it is deleted.
function storagePrefixesForUid(uid) {
  if (typeof uid !== 'string' || !uid.trim()) {
    throw new Error('storagePrefixesForUid: uid required');
  }
  const u = uid.trim();
  return [
    `verification_documents/${u}/`,
    `profile_images/${u}/`,
    `review_media/${u}/`,
    `college_requests/${u}/`,
    `placement_documents/${u}/`,
    `resumes/${u}/`,
    `faculty_documents/${u}/`,
    `college_claim_documents/${u}/`,
  ];
}

// aiUsage doc ids are `${uid}_${utcDate}`. Deleted via a documentId()
// prefix scan: startAt(start) .. endAt(end); `end` appends U+F8FF, a
// very-high private-use code point that sorts after any real suffix.
function aiUsageIdRange(uid) {
  if (typeof uid !== 'string' || !uid.trim()) {
    throw new Error('aiUsageIdRange: uid required');
  }
  const u = uid.trim();
  return { start: `${u}_`, end: `${u}_` };
}

module.exports = {
  ANON,
  DELETE_DOC_BY_UID,
  DELETE_RECURSIVE_DOC_BY_UID,
  DELETE_BY_FIELD,
  DELETE_RECURSIVE_BY_FIELD,
  ANONYMISE_BY_FIELD,
  ANONYMISE_GROUP_BY_FIELD,
  storagePrefixesForUid,
  aiUsageIdRange,
};
