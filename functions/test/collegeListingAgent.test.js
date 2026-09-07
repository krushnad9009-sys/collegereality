'use strict';

const {
  decideCollege,
  buildPrompt,
  htmlToSnippet,
} = require('../src/verification/collegeListingAgent');

function plausible(overrides = {}) {
  return {
    isGibberishOrSpam: false,
    nameLooksLikeCollege: 0.9,
    collegePlausiblyExists: 0.7,
    addressPlausible: 0.8,
    universityPlausible: 0.8,
    websiteVerdict: 'matches_college',
    photoVerdict: 'plausible_campus',
    concerns: [],
    authenticityScore: 0.8,
    ...overrides,
  };
}

describe('collegeListingAgent.decideCollege', () => {
  test('never returns "accept" — plausible submissions flag for a human', () => {
    const r = decideCollege(plausible());
    expect(r.decision).toBe('flag');
  });

  test('gibberish / spam -> reject', () => {
    const r = decideCollege(plausible({
      isGibberishOrSpam: true,
      nameLooksLikeCollege: 0.05,
      authenticityScore: 0.05,
      concerns: ['Name is random characters'],
    }));
    expect(r.decision).toBe('reject');
    expect(r.reason).toMatch(/spam or gibberish/i);
  });

  test('very low authenticity -> reject', () => {
    const r = decideCollege(plausible({ authenticityScore: 0.1, nameLooksLikeCollege: 0.5, collegePlausiblyExists: 0.1 }));
    expect(r.decision).toBe('reject');
  });

  test('server-detected directory duplicate -> reject regardless of score', () => {
    const r = decideCollege(plausible(), { serverDetectedDuplicate: true });
    expect(r.decision).toBe('reject');
    expect(r.reason).toMatch(/already exists/i);
    expect(r.flags).toContain('possible_duplicate');
  });

  test('unreachable website + stock photo -> still flag, with flags recorded', () => {
    const r = decideCollege(plausible({
      websiteVerdict: 'unreachable',
      photoVerdict: 'stock_or_logo',
    }));
    expect(r.decision).toBe('flag');
    expect(r.flags).toEqual(expect.arrayContaining(['website_unverified', 'photo_unverified']));
  });

  test('doubtful address and affiliation are flagged but not auto-rejected on their own', () => {
    const r = decideCollege(plausible({ addressPlausible: 0.2, universityPlausible: 0.2 }));
    expect(r.decision).toBe('flag');
    expect(r.flags).toEqual(expect.arrayContaining(['address_doubtful', 'affiliation_doubtful']));
  });

  test('missing / empty analysis -> reject, never throws', () => {
    expect(() => decideCollege(undefined)).not.toThrow();
    expect(decideCollege({}).decision).toBe('reject');
  });

  test('checks object carries verdicts and scores', () => {
    const r = decideCollege(plausible());
    expect(r.checks).toMatchObject({
      websiteVerdict: 'matches_college',
      photoVerdict: 'plausible_campus',
      serverDetectedDuplicate: false,
    });
  });
});

describe('collegeListingAgent.buildPrompt', () => {
  test('embeds submission fields and the fetched website snippet', () => {
    const { userPrompt } = buildPrompt({
      name: 'Acme Institute of Technology',
      city: 'Pune',
      state: 'Maharashtra',
      address: '123 MG Road',
      website: 'acme.edu.in',
      universityName: 'SPPU',
      notes: 'new campus',
      websiteSnippet: 'Acme Institute of Technology admissions 2026',
      hasPhoto: true,
      duplicateOfName: null,
    });
    expect(userPrompt).toContain('Acme Institute of Technology');
    expect(userPrompt).toContain('Pune');
    expect(userPrompt).toContain('SPPU');
    expect(userPrompt).toContain('admissions 2026');
    expect(userPrompt).toMatch(/photo attached: yes/i);
  });

  test('flags a known duplicate name to the model', () => {
    const { userPrompt } = buildPrompt({
      name: 'X College',
      city: 'Y',
      state: 'Z',
      duplicateOfName: 'X College',
    });
    expect(userPrompt).toMatch(/already contains a very similar entry/i);
  });
});

describe('collegeListingAgent.htmlToSnippet', () => {
  test('strips tags, scripts and styles', () => {
    const html =
      '<html><head><style>a{}</style></head><body><script>x()</script>' +
      '<h1>Acme College</h1><p>Best   college</p></body></html>';
    expect(htmlToSnippet(html)).toBe('Acme College Best college');
  });

  test('truncates to the char budget', () => {
    const long = '<p>' + 'a'.repeat(5000) + '</p>';
    expect(htmlToSnippet(long, 100).length).toBe(100);
  });

  test('non-string input -> empty string', () => {
    expect(htmlToSnippet(null)).toBe('');
  });
});
