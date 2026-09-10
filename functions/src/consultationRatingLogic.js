'use strict';

// Pure aggregation for the guide-facing consultation rating stats.
// Ported 1:1 from the (now-removed) Dart `recomputeConsultationStats` in
// lib/features/consultations/utils/consultation_rating_calculator.dart —
// the client no longer computes this; onConsultationRatingCreated does,
// server-side and serialised, so two students rating the same guide can
// never race each other's write (the bug that motivated this move).

function toNum(v) {
  return typeof v === 'number' && Number.isFinite(v) ? v : 0;
}

/**
 * @param {Array<{overall:number, criteria?:object}>} studentRatings
 *   Every `consultation_ratings` doc where this guide is the ratee and
 *   raterRole === 'student'.
 * @returns {{
 *   completedConsultations:number, consultationRatingAvg:number,
 *   communicationAvg:number, helpfulOrRespectfulAvg:number,
 *   knowledgeOrSeriousnessAvg:number, genuineOrAppropriateAvg:number
 * }}  All averages rounded to 2 dp; zeros when there are no ratings.
 */
function computeConsultationAggregate(studentRatings) {
  const list = Array.isArray(studentRatings) ? studentRatings : [];
  const total = list.length;
  if (total === 0) {
    return {
      completedConsultations: 0,
      consultationRatingAvg: 0,
      communicationAvg: 0,
      helpfulOrRespectfulAvg: 0,
      knowledgeOrSeriousnessAvg: 0,
      genuineOrAppropriateAvg: 0,
    };
  }

  let overall = 0;
  let communication = 0;
  let c2 = 0;
  let c3 = 0;
  let c4 = 0;
  for (const r of list) {
    overall += toNum(r && r.overall);
    const cr = (r && r.criteria) || {};
    communication += toNum(cr.communication);
    c2 += toNum(cr.criterion2);
    c3 += toNum(cr.criterion3);
    c4 += toNum(cr.criterion4);
  }

  const avg2 = (sum) => Math.round((sum / total) * 100) / 100;

  return {
    completedConsultations: total,
    consultationRatingAvg: avg2(overall),
    communicationAvg: avg2(communication),
    helpfulOrRespectfulAvg: avg2(c2),
    knowledgeOrSeriousnessAvg: avg2(c3),
    genuineOrAppropriateAvg: avg2(c4),
  };
}

/**
 * The mirror of the above for the OTHER direction: a student's summary of
 * the ratings guides have given them. Same maths, student-facing key
 * names — matches Dart `StudentConsultationSummary`.
 *
 * @param {Array<{overall:number, criteria?:object}>} guideRatings
 *   Every `consultation_ratings` doc where this student is the ratee and
 *   raterRole === 'guide'.
 */
function computeStudentConsultationSummary(guideRatings) {
  const agg = computeConsultationAggregate(guideRatings);
  return {
    totalRatings: agg.completedConsultations,
    overallAvg: agg.consultationRatingAvg,
    communicationAvg: agg.communicationAvg,
    respectfulAvg: agg.helpfulOrRespectfulAvg, // criterion2
    seriousnessAvg: agg.knowledgeOrSeriousnessAvg, // criterion3
    appropriateAvg: agg.genuineOrAppropriateAvg, // criterion4
  };
}

module.exports = {
  computeConsultationAggregate,
  computeStudentConsultationSummary,
  toNum,
};
