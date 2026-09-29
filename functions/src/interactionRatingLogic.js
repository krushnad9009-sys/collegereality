'use strict';

// Pure recompute of a user's guideStats from their free call/chat
// interaction_ratings -- the server-side port of the Dart
// recomputeGuideStats (lib/features/communication/utils/
// guide_stats_calculator.dart), which used to run on the RATER's phone
// and write the ratee's users + public_profiles docs directly. That
// cross-user client write needed a read of every rating for the ratee
// (rules only let you read ratings you gave/received -> PERMISSION_DENIED)
// and an exact `totalRatings == old + 1` match on BOTH docs (any drift
// between them -> the mirror write was denied). See
// interactionRatingTriggers.js.

const round1 = (n) => Math.round(n * 10) / 10;

function toNum(v, fallback = 0) {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

/** Mirrors computeBadgeTier in guide_stats_calculator.dart. */
function computeBadgeTier({ overallRating, totalCalls }) {
  if (overallRating >= 4.5 && totalCalls >= 50) return 'gold';
  if (overallRating >= 4.0 && totalCalls >= 20) return 'silver';
  if (overallRating >= 3.5 && totalCalls >= 5) return 'bronze';
  return 'none';
}

function isCallInteraction(type) {
  return type === 'voice_call' || type === 'video_call';
}

/**
 * @param {object} current   existing guideStats map (may be {})
 * @param {object[]} ratings every interaction_ratings doc for the ratee
 * @param {{incrementCall: boolean, incrementChat: boolean, nowIso: string}} opts
 * @returns {object} the full new guideStats map
 */
function recomputeGuideStats(current, ratings, { incrementCall, incrementChat, nowIso }) {
  const totalRatings = ratings.length;
  let starSum = 0;
  let helpful = 0;
  let respectful = 0;
  let recommend = 0;
  for (const r of ratings) {
    starSum += Math.min(Math.max(toNum(r.stars), 0), 5);
    if (r.helpful === true) helpful++;
    if (r.respectful === true) respectful++;
    if (r.wouldRecommend === true) recommend++;
  }
  const pct = (count) => (totalRatings === 0 ? 0 : round1((count / totalRatings) * 100));

  const next = {
    ...current,
    overallRating: totalRatings === 0 ? 0 : round1(starSum / totalRatings),
    totalRatings,
    totalCalls: toNum(current.totalCalls) + (incrementCall ? 1 : 0),
    totalChats: toNum(current.totalChats) + (incrementChat ? 1 : 0),
    helpfulPercent: pct(helpful),
    respectfulPercent: pct(respectful),
    recommendPercent: pct(recommend),
    lastActiveAt: nowIso,
  };
  next.badgeTier = computeBadgeTier(next);
  return next;
}

module.exports = { computeBadgeTier, isCallInteraction, recomputeGuideStats, toNum };
