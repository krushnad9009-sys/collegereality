'use strict';

const { VERIFICATION_CONFIG, AI_DECISION } = require('./config');

const T = VERIFICATION_CONFIG.STUDENT;

// Human-readable label per document-type id (mirrors VerificationConstants
// in Dart — kept here so the prompt names the document the way the user
// was asked to upload it).
const DOC_TYPE_LABELS = {
  college_id: 'College / Institute ID card',
  bonafide_certificate: 'Bonafide certificate issued by the college',
  fee_receipt: 'College fee payment receipt',
  admission_letter: 'College admission / offer letter',
  final_year_marksheet: 'Final-year degree marksheet (for alumni)',
};

function docTypeLabel(id) {
  return DOC_TYPE_LABELS[id] || id || 'a student verification document';
}

// The strict JSON contract we force Gemini to return (generationConfig
// .responseSchema). Every field is required so `decide()` never has to
// guess at a missing value.
const RESPONSE_SCHEMA = {
  type: 'object',
  properties: {
    documentKind: {
      type: 'string',
      description:
        "What the image actually is, e.g. 'college id card', 'aadhaar card', " +
        "'marksheet', 'selfie photo', 'blank page', 'screenshot', 'unrelated'.",
    },
    matchesExpectedDocType: { type: 'number', description: '0..1' },
    extractedName: { type: 'string', description: 'Full name on the document, or "" if none.' },
    nameMatchScore: { type: 'number', description: '0..1 vs the expected name' },
    extractedCollege: { type: 'string' },
    collegeMatchScore: { type: 'number', description: '0..1 vs the expected college' },
    idNumberMasked: {
      type: 'string',
      description:
        'Any government/college ID number found, MASKED to the last 4 chars only ' +
        '(e.g. "XXXX XXXX 1234"). Never return a full Aadhaar/ID number.',
    },
    clarityScore: { type: 'number', description: '0..1 legibility / focus / lighting' },
    tamperScore: {
      type: 'number',
      description: '0..1 likelihood of digital editing, splicing, font mismatch, or a template',
    },
    isBlankOrPlaceholder: { type: 'boolean' },
    isScreenshotOrPhotoOfScreen: { type: 'boolean' },
    concerns: {
      type: 'array',
      items: { type: 'string' },
      description: 'Short phrases describing anything wrong or suspicious.',
    },
    overallAuthenticity: { type: 'number', description: '0..1 overall confidence this is a genuine, valid document for this person' },
  },
  required: [
    'documentKind',
    'matchesExpectedDocType',
    'extractedName',
    'nameMatchScore',
    'extractedCollege',
    'collegeMatchScore',
    'idNumberMasked',
    'clarityScore',
    'tamperScore',
    'isBlankOrPlaceholder',
    'isScreenshotOrPhotoOfScreen',
    'concerns',
    'overallAuthenticity',
  ],
};

function buildPrompt({ documentType, expectedName, expectedCollege, role }) {
  const systemPrompt = [
    'You are an automated document-verification analyst for an Indian college',
    'review platform. You examine a single uploaded document image (or PDF) and',
    'return a strict JSON assessment. You are cautious and precise.',
    '',
    'RULES:',
    '- Judge only what is visible. Do not invent details.',
    '- Score every *Score field from 0.0 (no) to 1.0 (yes/certain).',
    '- NEVER output a full Aadhaar number, PAN, or any complete government ID.',
    '  Mask everything except the last 4 characters.',
    '- A photo/screenshot of a screen, an obvious template, a blank page, or an',
    '  unrelated image must get a low overallAuthenticity.',
    '- Minor blur is fine; illegible key fields are not.',
  ].join(' ');

  const userPrompt = [
    `Verification role: ${role === 'alumni' ? 'Current student is claiming ALUMNI status' : 'Current student'}.`,
    `Expected document type: ${docTypeLabel(documentType)}.`,
    `Expected full name of the person: ${expectedName ? `"${expectedName}"` : '(not provided — score nameMatchScore 0.5)'}.`,
    `Expected college / institute: ${expectedCollege ? `"${expectedCollege}"` : '(not provided — score collegeMatchScore 0.5)'}.`,
    '',
    'Assess the attached document and return the JSON assessment.',
  ].join('\n');

  return { systemPrompt, userPrompt, responseSchema: RESPONSE_SCHEMA };
}

// ── Pure decision logic ────────────────────────────────────────────────
// No I/O. Given the model's analysis object, produce the final verdict.
// Flag codes double as the `aiFlags` written to the request doc; the ones
// that overlap VerificationConstants (Dart) reuse those exact strings so
// the admin UI's existing flag chips render unchanged.

function num(v, dflt = 0) {
  const n = Number(v);
  return Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : dflt;
}

/**
 * @param {object} a  model analysis (RESPONSE_SCHEMA shape; may be partial)
 * @returns {{
 *   decision: 'accept'|'reject'|'flag',
 *   confidence: number,
 *   reason: string,
 *   flags: string[],
 *   checks: object,
 * }}
 */
function decide(a) {
  a = a || {};
  const clarity = num(a.clarityScore);
  const tamper = num(a.tamperScore);
  const nameMatch = num(a.nameMatchScore, 0.5);
  const collegeMatch = num(a.collegeMatchScore, 0.5);
  const docTypeMatch = num(a.matchesExpectedDocType);
  const authenticity = num(a.overallAuthenticity);
  const blank = a.isBlankOrPlaceholder === true;
  const screenPhoto = a.isScreenshotOrPhotoOfScreen === true;
  const concerns = Array.isArray(a.concerns)
    ? a.concerns.filter((s) => typeof s === 'string' && s.trim()).slice(0, 8)
    : [];

  const flags = [];
  const hardReject = [];

  if (blank) hardReject.push('The upload is blank or a placeholder.');
  if (docTypeMatch < 0.35) {
    hardReject.push(
      `The document does not look like the requested type (detected: ${a.documentKind || 'unknown'}).`,
    );
    flags.push('invalid_format');
  }
  if (nameMatch < 0.35) {
    hardReject.push('The name on the document does not match the profile name.');
    flags.push('suspicious_document');
  }
  if (tamper >= T.HARD_TAMPER_REJECT) {
    hardReject.push('Strong signs of digital editing or a forged template.');
    flags.push('possible_manipulation');
  }

  if (tamper >= T.MAX_TAMPER_FOR_ACCEPT && tamper < T.HARD_TAMPER_REJECT) {
    flags.push('possible_manipulation');
  }
  if (clarity < T.MIN_CLARITY) flags.push('low_quality');
  if (screenPhoto) flags.push('suspicious_document');
  if (collegeMatch < 0.4) flags.push('suspicious_document');

  const checks = {
    documentKind: a.documentKind || 'unknown',
    docTypeMatch,
    nameMatch,
    collegeMatch,
    clarity,
    tamper,
    authenticity,
    isBlankOrPlaceholder: blank,
    isScreenshotOrPhotoOfScreen: screenPhoto,
    concerns,
  };

  // Composite confidence: authenticity is the model's own holistic call;
  // we lightly penalise the weakest sub-signal so a great-looking fake
  // with a mismatched name can't ride authenticity alone.
  const weakest = Math.min(nameMatch, docTypeMatch, clarity, 1 - tamper);
  const confidence = round2(0.6 * authenticity + 0.4 * weakest);

  if (hardReject.length > 0 || confidence <= T.AUTO_REJECT_CONFIDENCE) {
    return {
      decision: AI_DECISION.REJECT,
      confidence,
      reason:
        (hardReject[0] || 'Automated checks scored this document too low to accept.') +
        (concerns.length ? ` (${concerns[0]})` : ''),
      flags: dedupe(flags),
      checks,
    };
  }

  const acceptable =
    confidence >= T.AUTO_ACCEPT_CONFIDENCE &&
    clarity >= T.MIN_CLARITY &&
    nameMatch >= T.MIN_NAME_MATCH &&
    docTypeMatch >= T.MIN_DOC_TYPE_MATCH &&
    tamper < T.MAX_TAMPER_FOR_ACCEPT &&
    !screenPhoto &&
    flags.length === 0;

  if (acceptable) {
    return {
      decision: AI_DECISION.ACCEPT,
      confidence,
      reason: 'Document is legitimate, legible, and matches the profile.',
      flags: [],
      checks,
    };
  }

  return {
    decision: AI_DECISION.FLAG,
    confidence,
    reason: concerns[0]
      ? `Needs a human: ${concerns[0]}`
      : 'Borderline automated score — needs a human reviewer.',
    flags: dedupe(flags),
    checks,
  };
}

function round2(n) {
  return Math.round(n * 100) / 100;
}
function dedupe(arr) {
  return [...new Set(arr)];
}

module.exports = { buildPrompt, decide, RESPONSE_SCHEMA, docTypeLabel };
