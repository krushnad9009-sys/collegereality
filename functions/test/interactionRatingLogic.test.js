'use strict';

const {
  computeBadgeTier,
  isCallInteraction,
  recomputeGuideStats,
} = require('../src/interactionRatingLogic');

const NOW = '2026-09-29T10:00:00.000Z';
const opts = (isCall) => ({ incrementCall: isCall, incrementChat: !isCall, nowIso: NOW });

describe('recomputeGuideStats (port of Dart recomputeGuideStats)', () => {
  it('averages stars and rounds to one decimal', () => {
    const stats = recomputeGuideStats(
      {},
      [{ stars: 5 }, { stars: 4 }, { stars: 4 }],
      opts(true),
    );
    expect(stats.overallRating).toBe(4.3);
    expect(stats.totalRatings).toBe(3);
  });

  it('computes helpful / respectful / recommend percentages', () => {
    const stats = recomputeGuideStats(
      {},
      [
        { stars: 5, helpful: true, respectful: true, wouldRecommend: true },
        { stars: 3, helpful: false, respectful: true, wouldRecommend: false },
        { stars: 4, helpful: true, respectful: true, wouldRecommend: false },
      ],
      opts(true),
    );
    expect(stats.helpfulPercent).toBe(66.7);
    expect(stats.respectfulPercent).toBe(100);
    expect(stats.recommendPercent).toBe(33.3);
  });

  it('increments calls for call ratings and chats for chat ratings', () => {
    const current = { totalCalls: 4, totalChats: 2 };
    expect(recomputeGuideStats(current, [{ stars: 5 }], opts(true)))
      .toMatchObject({ totalCalls: 5, totalChats: 2 });
    expect(recomputeGuideStats(current, [{ stars: 5 }], opts(false)))
      .toMatchObject({ totalCalls: 4, totalChats: 3 });
  });

  it('keeps unrelated existing guideStats fields', () => {
    const stats = recomputeGuideStats(
      { avgResponseTimeMinutes: 7, consultationRating: 4.8 },
      [{ stars: 4 }],
      opts(true),
    );
    expect(stats.avgResponseTimeMinutes).toBe(7);
    expect(stats.consultationRating).toBe(4.8);
    expect(stats.lastActiveAt).toBe(NOW);
  });

  it('clamps out-of-range stars instead of skewing the average', () => {
    const stats = recomputeGuideStats({}, [{ stars: 50 }, { stars: -3 }], opts(true));
    expect(stats.overallRating).toBe(2.5);
  });

  it('assigns the badge tier from the new totals', () => {
    const current = { totalCalls: 4 };
    expect(recomputeGuideStats(current, [{ stars: 4 }], opts(true)).badgeTier).toBe('bronze');
  });
});

describe('computeBadgeTier (mirrors Dart computeBadgeTier)', () => {
  it.each([
    [{ overallRating: 4.6, totalCalls: 50 }, 'gold'],
    [{ overallRating: 4.6, totalCalls: 49 }, 'silver'],
    [{ overallRating: 4.0, totalCalls: 20 }, 'silver'],
    [{ overallRating: 3.5, totalCalls: 5 }, 'bronze'],
    [{ overallRating: 3.4, totalCalls: 100 }, 'none'],
  ])('%o -> %s', (stats, tier) => {
    expect(computeBadgeTier(stats)).toBe(tier);
  });
});

describe('isCallInteraction', () => {
  it('treats voice/video as calls and anything else as chat', () => {
    expect(isCallInteraction('voice_call')).toBe(true);
    expect(isCallInteraction('video_call')).toBe(true);
    expect(isCallInteraction('chat')).toBe(false);
  });
});
