'use strict';

const { buildPrompt } = require('../src/ai/promptBuilder');
const { buildCacheKey } = require('../src/ai/cache');
const { AI_CHAT_CONFIG } = require('../src/ai/config');

describe('buildPrompt', () => {
  it('grounds a college-mode question in only the given college data', () => {
    const { systemPrompt, userPrompt } = buildPrompt({
      question: 'How are placements?',
      mode: 'college',
      collegeContext: {
        name: 'Test Engineering College',
        city: 'Pune',
        state: 'Maharashtra',
        category: 'Engineering',
        avgPackageLpa: 6,
        placementPct: 80,
      },
    });
    expect(systemPrompt).toContain('ONLY');
    expect(userPrompt).toContain('Test Engineering College');
    expect(userPrompt).toContain('Pune');
    expect(userPrompt).toContain('80%');
    expect(userPrompt).toContain('How are placements?');
  });

  it('never includes colleges beyond the given candidate list in explore mode', () => {
    const { userPrompt } = buildPrompt({
      question: 'Best colleges in Pune',
      mode: 'explore',
      candidateColleges: [
        { name: 'Pune Engineering College', city: 'Pune', state: 'Maharashtra', crScore: 82 },
      ],
    });
    expect(userPrompt).toContain('Pune Engineering College');
    expect(userPrompt).not.toContain('Mumbai');
    expect(userPrompt).not.toContain('Nagpur');
  });

  it('says explicitly when nothing matched instead of leaving it ambiguous', () => {
    const { userPrompt } = buildPrompt({
      question: 'Best colleges in Mumbai',
      mode: 'explore',
      candidateColleges: [],
    });
    expect(userPrompt).toContain('none matched');
  });

  it('caps history to the configured number of recent turns', () => {
    const history = Array.from({ length: 10 }, (_, i) => ({
      role: i % 2 === 0 ? 'user' : 'assistant',
      text: `turn ${i}`,
    }));
    const { userPrompt } = buildPrompt({ question: 'q', mode: 'explore', history });
    expect(userPrompt).not.toContain('turn 0');
    expect(userPrompt).toContain(`turn ${history.length - 1}`);
    const keptTurns = history.slice(-AI_CHAT_CONFIG.MAX_HISTORY_TURNS);
    keptTurns.forEach((h) => expect(userPrompt).toContain(h.text));
  });

  it('truncates a very long question rather than sending it unbounded', () => {
    const longQuestion = 'a'.repeat(5000);
    const { userPrompt } = buildPrompt({ question: longQuestion, mode: 'explore' });
    expect(userPrompt.length).toBeLessThan(longQuestion.length);
  });
});

describe('buildCacheKey', () => {
  it('is stable for the same normalized question and context', () => {
    const a = buildCacheKey({ question: 'How are placements?', collegeId: 'c1', mode: 'college' });
    const b = buildCacheKey({ question: '  How are placements?  ', collegeId: 'c1', mode: 'college' });
    expect(a).toBe(b);
  });

  it('is case-insensitive on the question text', () => {
    const a = buildCacheKey({ question: 'Best colleges in Pune', mode: 'explore' });
    const b = buildCacheKey({ question: 'best colleges in pune', mode: 'explore' });
    expect(a).toBe(b);
  });

  it('differs by college id so answers about different colleges never collide', () => {
    const a = buildCacheKey({ question: 'How are placements?', collegeId: 'c1', mode: 'college' });
    const b = buildCacheKey({ question: 'How are placements?', collegeId: 'c2', mode: 'college' });
    expect(a).not.toBe(b);
  });

  it('ignores an extraneous uid field so two students get the same cache entry', () => {
    // buildCacheKey only destructures {question, collegeId, mode, filters}
    // -- passing uid alongside must not change the key, guarding against a
    // future edit accidentally making the cache personal.
    const a = buildCacheKey({ question: 'q', collegeId: 'c1', mode: 'college', uid: 'student-a' });
    const b = buildCacheKey({ question: 'q', collegeId: 'c1', mode: 'college', uid: 'student-b' });
    expect(a).toBe(b);
  });
});
