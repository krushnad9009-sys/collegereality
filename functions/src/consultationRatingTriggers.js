'use strict';

// onConsultationRatingCreated — fires once per `consultation_ratings`
// document create (student->guide AND guide->student).
//
// For a STUDENT->GUIDE rating it does the two denormalisations the client
// used to attempt itself:
//   1. writes the PII-free public copy at `guide_reviews/{consultationId}`
//      (no raterId), and
//   2. recomputes the guide's consultation aggregate from ALL of their
//      student ratings and mirrors it onto `users/{guideId}.guideStats`
//      and `public_profiles/{guideId}.guideStats`.
//
// Why server-side: the old client path wrote the absolute rating count and
// firestore.rules required it to equal `old + 1`. Two students rating the
// same guide within the recompute window made the second write fail
// permanently (and every later rating for that guide). This trigger is
// serialised per document and recomputes from scratch, so it is
// idempotent and race-free. All writes use the Admin SDK (bypass rules).
//
// A GUIDE->STUDENT rating needs no denormalisation — the student summary
// is computed on demand (see ConsultationService.getStudentConsultationSummary).

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const { db } = require('./admin');
const {
  computeConsultationAggregate,
  computeStudentConsultationSummary,
  toNum,
} = require('./consultationRatingLogic');

const MAX_COMMENT = 1000;
const MAX_COLLEGE_NAME = 120;
const nowIso = () => new Date().toISOString();

async function writeGuideReviewCopy({ consultationId, guideId, rating }) {
  let collegeName = '';
  try {
    const raterSnap = await db.collection('users').doc(rating.raterId).get();
    if (raterSnap.exists) {
      collegeName = String(raterSnap.data().collegeName || '');
    }
  } catch (err) {
    logger.warn('[consultationRating] rater college lookup failed', {
      consultationId,
      message: err && err.message,
    });
  }

  const comment =
    typeof rating.comment === 'string' ? rating.comment.slice(0, MAX_COMMENT) : '';

  await db.collection('guide_reviews').doc(consultationId).set({
    consultationId,
    guideId,
    overall: toNum(rating.overall),
    comment,
    collegeName: collegeName.slice(0, MAX_COLLEGE_NAME),
    createdAt: rating.createdAt || nowIso(),
  });
}

async function recomputeGuideAggregate(guideId) {
  const snap = await db
    .collection('consultation_ratings')
    .where('rateeId', '==', guideId)
    .where('raterRole', '==', 'student')
    .get();

  const agg = computeConsultationAggregate(snap.docs.map((d) => d.data()));

  // Deep-merge only the consultation.* sub-fields — every other
  // guideStats key (overallRating, totalChats, badgeTier, …) is left
  // untouched. `set(..., {merge:true})` recurses into nested maps and
  // does not fail if the target doc is missing.
  const guideStatsPatch = {
    guideStats: {
      consultationRatingAvg: agg.consultationRatingAvg,
      completedConsultations: agg.completedConsultations,
      communicationAvg: agg.communicationAvg,
      helpfulOrRespectfulAvg: agg.helpfulOrRespectfulAvg,
      knowledgeOrSeriousnessAvg: agg.knowledgeOrSeriousnessAvg,
      genuineOrAppropriateAvg: agg.genuineOrAppropriateAvg,
    },
    updatedAt: nowIso(),
  };

  await Promise.all([
    db.collection('users').doc(guideId).set(guideStatsPatch, { merge: true }),
    db
      .collection('public_profiles')
      .doc(guideId)
      .set(guideStatsPatch, { merge: true }),
  ]);

  return agg;
}

const onConsultationRatingCreated = onDocumentCreated(
  {
    document: 'consultation_ratings/{ratingId}',
    // Idempotent (recompute-from-scratch + idempotent set writes), so a
    // redelivery on transient failure is safe and desirable.
    retry: true,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const rating = snap.data();
    if (!rating) return;

    const rateeId = rating.rateeId;
    const consultationId = rating.consultationId;
    if (!rateeId || !consultationId) {
      logger.warn('[consultationRating] missing rateeId/consultationId', {
        ratingId: event.params.ratingId,
      });
      return;
    }

    // guide -> student: maintain the PII-free student summary doc that a
    // guide reads before/around a consultation (no rater identity, no
    // comments — just the averages + count).
    if (rating.raterRole === 'guide') {
      const q = await db
        .collection('consultation_ratings')
        .where('rateeId', '==', rateeId)
        .where('raterRole', '==', 'guide')
        .get();
      const summary = computeStudentConsultationSummary(
        q.docs.map((d) => d.data()),
      );
      await db
        .collection('student_consultation_summaries')
        .doc(rateeId)
        .set({ studentId: rateeId, ...summary, updatedAt: nowIso() });
      logger.info('[consultationRating] student summary updated', {
        studentId: rateeId,
        totalRatings: summary.totalRatings,
      });
      return;
    }

    if (rating.raterRole !== 'student') return;
    const guideId = rateeId;

    // Best-effort: a failed public-copy write must not block the
    // aggregate (which is the source of truth for the guide's card).
    try {
      await writeGuideReviewCopy({ consultationId, guideId, rating });
    } catch (err) {
      logger.error('[consultationRating] guide_reviews copy failed', {
        consultationId,
        message: err && err.message,
      });
    }

    const agg = await recomputeGuideAggregate(guideId);
    logger.info('[consultationRating] aggregate updated', {
      guideId,
      completedConsultations: agg.completedConsultations,
      consultationRatingAvg: agg.consultationRatingAvg,
    });
  },
);

module.exports = { onConsultationRatingCreated };
