'use strict';

// Weekly Lead Analytics (Super Admin panel). Rolls each
// lead_activity_events/{eventId} doc (written by the Flutter client --
// see lib/features/leads/services/lead_activity_service.dart -- from a
// college search-by-faculty, a college detail view, or tapping "Call" on
// a college) into a single per-user summary doc, lead_summaries/{uid}, so
// the admin panel's query never has to join lead_activity_events against
// users/{uid} for contact details -- it reads one collection.
//
// "Weekly" is approximated, not a true rolling 7-day window: rather than
// per-day buckets (which would need a scheduled cleanup function and a
// heavier read/write shape), facultyCounts resets to empty whenever the
// PREVIOUS event was more than 7 days ago, then accumulates from there.
// For a student who's actually been dormant and comes back, this is
// exactly a fresh week. For a continuously-active student, topFaculty
// reflects everything since their last >7-day gap, not strictly the
// trailing 7 days -- a reasonable trade-off given what a scheduled-reset
// alternative would cost, but worth knowing if the numbers ever look off
// for a long-tenured, highly active account.

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const { FieldValue } = require('firebase-admin/firestore');
const { db } = require('./admin');

const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

const onLeadActivityEventCreated = onDocumentCreated(
  'lead_activity_events/{eventId}',
  async (event) => {
    const data = event.data.data();
    const userId = data.userId;
    if (!userId) return;

    const faculty = data.faculty || null;
    const eventType = data.eventType || 'unknown';
    const collegeName = data.collegeName || null;
    const createdAt = data.createdAt || new Date().toISOString();

    const userSnap = await db.collection('users').doc(userId).get();
    const user = userSnap.exists ? userSnap.data() : {};

    const summaryRef = db.collection('lead_summaries').doc(userId);

    try {
      await db.runTransaction(async (tx) => {
        const summarySnap = await tx.get(summaryRef);
        const existing = summarySnap.exists ? summarySnap.data() : {};

        const lastActiveMs = existing.lastActiveAt
          ? Date.parse(existing.lastActiveAt)
          : null;
        const isStale =
          lastActiveMs === null || Date.now() - lastActiveMs > WEEK_MS;

        const facultyCounts = isStale ? {} : { ...(existing.facultyCounts || {}) };
        if (faculty) {
          facultyCounts[faculty] = (facultyCounts[faculty] || 0) + 1;
        }

        let topFaculty = existing.topFaculty || null;
        let topCount = -1;
        for (const [key, count] of Object.entries(facultyCounts)) {
          if (count > topCount) {
            topCount = count;
            topFaculty = key;
          }
        }
        // Every count reset to zero (a stale doc, no faculty on this
        // event either) -- don't keep pointing at a faculty with no
        // actual count behind it this window.
        if (Object.keys(facultyCounts).length === 0) topFaculty = faculty || null;

        tx.set(
          summaryRef,
          {
            userId,
            name:
              user.displayName || user.publicDisplayName || user.customDisplayName || '',
            phone: user.phone || '',
            email: user.email || '',
            city: user.city || '',
            state: user.state || '',
            facultyCounts,
            topFaculty,
            lastEventType: eventType,
            lastCollegeName: collegeName,
            lastActiveAt: createdAt,
            eventCount: FieldValue.increment(1),
            updatedAt: new Date().toISOString(),
          },
          { merge: true },
        );
      });
    } catch (e) {
      // Best-effort -- a summary hiccup must not retry-storm the trigger
      // or block anything else; the raw event doc is still there if this
      // ever needs backfilling.
      logger.warn('[leadActivity] summary upsert failed', {
        userId,
        error: e && e.message,
      });
    }
  },
);

module.exports = { onLeadActivityEventCreated };
