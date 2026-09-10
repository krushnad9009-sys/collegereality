'use strict';

const {
  computeConsultationAggregate,
  computeStudentConsultationSummary,
} = require('../src/consultationRatingLogic');

const rating = ({ overall, communication = 5, c2 = 5, c3 = 5, c4 = 5 }) => ({
  overall,
  criteria: { communication, criterion2: c2, criterion3: c3, criterion4: c4 },
});

describe('computeConsultationAggregate', () => {
  it('returns all-zero for no ratings', () => {
    expect(computeConsultationAggregate([])).toEqual({
      completedConsultations: 0,
      consultationRatingAvg: 0,
      communicationAvg: 0,
      helpfulOrRespectfulAvg: 0,
      knowledgeOrSeriousnessAvg: 0,
      genuineOrAppropriateAvg: 0,
    });
  });

  it('a single rating sets every average to that rating', () => {
    const agg = computeConsultationAggregate([
      rating({ overall: 4, communication: 5, c2: 4, c3: 3, c4: 5 }),
    ]);
    expect(agg).toEqual({
      completedConsultations: 1,
      consultationRatingAvg: 4,
      communicationAvg: 5,
      helpfulOrRespectfulAvg: 4,
      knowledgeOrSeriousnessAvg: 3,
      genuineOrAppropriateAvg: 5,
    });
  });

  it('averages multiple ratings and rounds to 2 dp', () => {
    const agg = computeConsultationAggregate([
      rating({ overall: 5, communication: 5, c2: 4, c3: 4, c4: 5 }),
      rating({ overall: 4, communication: 4, c2: 5, c3: 3, c4: 4 }),
      rating({ overall: 5, communication: 3, c2: 3, c3: 5, c4: 5 }),
    ]);
    expect(agg.completedConsultations).toBe(3);
    expect(agg.consultationRatingAvg).toBe(4.67); // 14/3
    expect(agg.communicationAvg).toBe(4); // 12/3
    expect(agg.helpfulOrRespectfulAvg).toBe(4); // 12/3
    expect(agg.knowledgeOrSeriousnessAvg).toBe(4); // 12/3
    expect(agg.genuineOrAppropriateAvg).toBe(4.67); // 14/3
  });

  it('treats a missing criteria map / non-numeric fields as 0', () => {
    const agg = computeConsultationAggregate([
      { overall: 4 },
      { overall: 'x', criteria: { communication: null } },
    ]);
    expect(agg.completedConsultations).toBe(2);
    expect(agg.consultationRatingAvg).toBe(2); // (4 + 0) / 2
    expect(agg.communicationAvg).toBe(0);
  });

  it('is order-independent and idempotent for the same set', () => {
    const set = [
      rating({ overall: 3 }),
      rating({ overall: 5 }),
      rating({ overall: 4 }),
    ];
    const a = computeConsultationAggregate(set);
    const b = computeConsultationAggregate([...set].reverse());
    expect(a).toEqual(b);
    expect(a.consultationRatingAvg).toBe(4);
  });
});

describe('computeStudentConsultationSummary', () => {
  it('re-keys the aggregate to the student-facing shape', () => {
    const s = computeStudentConsultationSummary([
      rating({ overall: 5, communication: 5, c2: 4, c3: 5, c4: 5 }),
      rating({ overall: 4, communication: 4, c2: 4, c3: 4, c4: 4 }),
    ]);
    expect(s).toEqual({
      totalRatings: 2,
      overallAvg: 4.5,
      communicationAvg: 4.5,
      respectfulAvg: 4, // criterion2
      seriousnessAvg: 4.5, // criterion3
      appropriateAvg: 4.5, // criterion4
    });
  });

  it('is the zero summary for no ratings', () => {
    expect(computeStudentConsultationSummary([])).toEqual({
      totalRatings: 0,
      overallAvg: 0,
      communicationAvg: 0,
      respectfulAvg: 0,
      seriousnessAvg: 0,
      appropriateAvg: 0,
    });
  });
});
