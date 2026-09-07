'use strict';

const { decide, buildPrompt } = require('../src/verification/studentDocAgent');

// A "clean pass" analysis object — every signal strong. Individual tests
// clone this and weaken one thing.
function cleanAnalysis(overrides = {}) {
  return {
    documentKind: 'college id card',
    matchesExpectedDocType: 0.95,
    extractedName: 'Asha Kumari',
    nameMatchScore: 0.95,
    extractedCollege: 'COEP Technological University',
    collegeMatchScore: 0.9,
    idNumberMasked: 'XXXX 4821',
    clarityScore: 0.9,
    tamperScore: 0.03,
    isBlankOrPlaceholder: false,
    isScreenshotOrPhotoOfScreen: false,
    concerns: [],
    overallAuthenticity: 0.92,
    ...overrides,
  };
}

describe('studentDocAgent.decide', () => {
  test('clean, matching, legible document -> accept', () => {
    const r = decide(cleanAnalysis());
    expect(r.decision).toBe('accept');
    expect(r.confidence).toBeGreaterThanOrEqual(0.82);
    expect(r.flags).toEqual([]);
  });

  test('wrong document kind -> reject with a specific reason', () => {
    const r = decide(cleanAnalysis({
      documentKind: 'aadhaar card',
      matchesExpectedDocType: 0.05,
      concerns: ['This is an Aadhaar card, not a college ID'],
    }));
    expect(r.decision).toBe('reject');
    expect(r.reason).toMatch(/does not look like the requested type/i);
    expect(r.flags).toContain('invalid_format');
  });

  test('name mismatch -> reject', () => {
    const r = decide(cleanAnalysis({ nameMatchScore: 0.1, extractedName: 'Someone Else' }));
    expect(r.decision).toBe('reject');
    expect(r.reason).toMatch(/name on the document does not match/i);
  });

  test('strong tamper signal -> reject', () => {
    const r = decide(cleanAnalysis({ tamperScore: 0.85, concerns: ['Font mismatch in the name field'] }));
    expect(r.decision).toBe('reject');
    expect(r.flags).toContain('possible_manipulation');
  });

  test('blank / placeholder upload -> reject', () => {
    const r = decide(cleanAnalysis({ isBlankOrPlaceholder: true, overallAuthenticity: 0.2 }));
    expect(r.decision).toBe('reject');
  });

  test('low clarity but otherwise fine -> flag, not reject', () => {
    const r = decide(cleanAnalysis({ clarityScore: 0.35, overallAuthenticity: 0.7 }));
    expect(r.decision).toBe('flag');
    expect(r.flags).toContain('low_quality');
  });

  test('photo of a screen -> flag', () => {
    const r = decide(cleanAnalysis({ isScreenshotOrPhotoOfScreen: true, overallAuthenticity: 0.7 }));
    expect(r.decision).toBe('flag');
    expect(r.flags).toContain('suspicious_document');
  });

  test('borderline confidence -> flag', () => {
    const r = decide(cleanAnalysis({
      overallAuthenticity: 0.55,
      nameMatchScore: 0.6,
      matchesExpectedDocType: 0.6,
      concerns: ['Partial name visible only'],
    }));
    expect(r.decision).toBe('flag');
    expect(r.reason).toMatch(/human/i);
  });

  test('mild tamper (in the grey band) flags without rejecting', () => {
    const r = decide(cleanAnalysis({ tamperScore: 0.4, overallAuthenticity: 0.7 }));
    expect(r.decision).toBe('flag');
    expect(r.flags).toContain('possible_manipulation');
  });

  test('missing / empty analysis -> flag, never throws', () => {
    expect(() => decide(undefined)).not.toThrow();
    expect(decide({}).decision).toBe('reject'); // no signal at all scores ~0
  });

  test('checks object always carries the sub-scores', () => {
    const r = decide(cleanAnalysis());
    expect(r.checks).toMatchObject({
      nameMatch: 0.95,
      clarity: 0.9,
      docTypeMatch: 0.95,
    });
  });
});

describe('studentDocAgent.buildPrompt', () => {
  test('includes the expected name, college and a human doc-type label', () => {
    const { systemPrompt, userPrompt, responseSchema } = buildPrompt({
      documentType: 'college_id',
      expectedName: 'Asha Kumari',
      expectedCollege: 'COEP',
      role: 'student',
    });
    expect(userPrompt).toContain('Asha Kumari');
    expect(userPrompt).toContain('COEP');
    expect(userPrompt).toMatch(/ID card/i);
    expect(systemPrompt).toMatch(/NEVER output a full Aadhaar/i);
    expect(responseSchema.required).toContain('overallAuthenticity');
  });

  test('alumni role is surfaced in the prompt', () => {
    const { userPrompt } = buildPrompt({
      documentType: 'final_year_marksheet',
      expectedName: 'X',
      expectedCollege: 'Y',
      role: 'alumni',
    });
    expect(userPrompt).toMatch(/ALUMNI/i);
  });
});
