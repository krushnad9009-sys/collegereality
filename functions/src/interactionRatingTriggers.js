'use strict';

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const { db } = require('./admin');
const { isCallInteraction, recomputeGuideStats } = require('./interactionRatingLogic');

/**
 * Recomputes the ratee's guideStats whenever a free call/chat rating is
 * filed. The client now only writes the interaction_ratings doc (rules:
 * raterId == auth.uid); this trigger does the aggregate with the Admin
 * SDK, so it needs no cross-user client permissions and can't be broken
 * by users/public_profiles drift. Same shape as onConsultationRatingCreated.
 *
 * Idempotent: the rating doc is stamped `aggregatedAt` inside the same
 * transaction, so an event redelivery can't double-count totalCalls.
 */
const onInteractionRatingCreated = onDocumentCreated(
  'interaction_ratings/{ratingId}',
  async (event) => {
    const rating = event.data && event.data.data();
    if (!rating) return;
    const { raterId, rateeId, sessionId } = rating;
    if (!raterId || !rateeId || raterId === rateeId) return;

    // Only count ratings from a real participant of the rated session --
    // otherwise anyone could file ratings against anyone.
    if (sessionId) {
      const session = await db.collection('call_sessions').doc(sessionId).get();
      if (session.exists) {
        const s = session.data();
        const participants = [s.callerId, s.calleeId];
        if (!participants.includes(raterId) || !participants.includes(rateeId)) {
          logger.warn('[interactionRating] rater/ratee not in session; ignored', {
            ratingId: event.params.ratingId,
          });
          return;
        }
      }
    }

    const ratingRef = event.data.ref;
    const userRef = db.collection('users').doc(rateeId);
    const mirrorRef = db.collection('public_profiles').doc(rateeId);
    const allRatings = db.collection('interaction_ratings').where('rateeId', '==', rateeId);

    await db.runTransaction(async (tx) => {
      const [ratingSnap, userSnap, ratingsSnap] = await Promise.all([
        tx.get(ratingRef),
        tx.get(userRef),
        tx.get(allRatings),
      ]);
      if (!ratingSnap.exists || ratingSnap.data().aggregatedAt) return;
      if (!userSnap.exists) return;

      const isCall = isCallInteraction(rating.interactionType);
      const guideStats = recomputeGuideStats(
        userSnap.data().guideStats || {},
        ratingsSnap.docs.map((d) => d.data()),
        { incrementCall: isCall, incrementChat: !isCall, nowIso: new Date().toISOString() },
      );
      const patch = { guideStats, updatedAt: new Date().toISOString() };
      tx.set(userRef, patch, { merge: true });
      tx.set(mirrorRef, patch, { merge: true });
      tx.update(ratingRef, { aggregatedAt: new Date().toISOString() });
    });
  },
);

module.exports = { onInteractionRatingCreated };
