'use strict';

const { VERIFICATION_CONFIG, AI_DECISION } = require('./config');
const { fetchWithHostGuard } = require('../util/safeFetch');

const T = VERIFICATION_CONFIG.COLLEGE;

const RESPONSE_SCHEMA = {
  type: 'object',
  properties: {
    isGibberishOrSpam: { type: 'boolean' },
    nameLooksLikeCollege: { type: 'number', description: '0..1 — reads like a real institution name' },
    collegePlausiblyExists: {
      type: 'number',
      description: '0..1 — a college by this name plausibly exists in this city/state (use general knowledge)',
    },
    addressPlausible: { type: 'number', description: '0..1 — plausible real Indian address for the stated city/state' },
    universityPlausible: {
      type: 'number',
      description: '0..1 — the stated affiliating university is a real Indian university (0.5 if none given)',
    },
    websiteVerdict: {
      type: 'string',
      description: "'not_provided' | 'unreachable' | 'parked_or_unrelated' | 'matches_college' | 'plausible'",
    },
    photoVerdict: {
      type: 'string',
      description: "'not_provided' | 'not_an_image' | 'stock_or_logo' | 'unrelated' | 'ai_generated' | 'plausible_campus'",
    },
    concerns: { type: 'array', items: { type: 'string' } },
    authenticityScore: {
      type: 'number',
      description: '0..1 overall confidence this is a genuine, non-spam new college submission',
    },
  },
  required: [
    'isGibberishOrSpam',
    'nameLooksLikeCollege',
    'collegePlausiblyExists',
    'addressPlausible',
    'universityPlausible',
    'websiteVerdict',
    'photoVerdict',
    'concerns',
    'authenticityScore',
  ],
};

function buildPrompt({
  name,
  city,
  state,
  address,
  website,
  universityName,
  notes,
  websiteSnippet,
  hasPhoto,
  duplicateOfName,
}) {
  const systemPrompt = [
    'You are an automated listing-verification analyst for an Indian college',
    'directory. A user has submitted a NEW college to be added. Assess whether',
    'it is a genuine institution worth a human reviewing, or spam/gibberish.',
    'Use your general knowledge of Indian higher education. Return strict JSON.',
    'Score every *score/plausible field 0.0 to 1.0. Be conservative: this feeds',
    'a public directory. If unsure, keep authenticityScore in the middle so a',
    'human decides — only very low scores auto-reject.',
  ].join(' ');

  const lines = [
    `College name: "${name}"`,
    `City / State: ${city || '?'} / ${state || '?'}`,
    `Address: ${address || '(none given)'}`,
    `Affiliating university: ${universityName || '(none given)'}`,
    `Website: ${website || '(none given)'}`,
    `Submitter notes: ${notes ? `"${String(notes).slice(0, 400)}"` : '(none)'}`,
    `Campus photo attached: ${hasPhoto ? 'yes (image follows)' : 'no'}`,
  ];
  if (duplicateOfName) {
    lines.push(
      `NOTE: our directory already contains a very similar entry "${duplicateOfName}" in the same city — weigh this as a likely duplicate.`,
    );
  }
  if (websiteSnippet) {
    lines.push('', 'Fetched website text (truncated):', '"""', websiteSnippet, '"""');
  } else if (website) {
    lines.push('', 'The website could not be fetched (unreachable / timed out).');
  }
  lines.push('', 'Return the JSON assessment.');

  return { systemPrompt, userPrompt: lines.join('\n'), responseSchema: RESPONSE_SCHEMA };
}

// ── Pure decision logic ────────────────────────────────────────────────
// Per product decision: NEVER auto-accept a directory entry. Only two
// outcomes here — 'reject' (spam / gibberish / duplicate / far too weak)
// or 'flag' (attach the score, a human decides).

function num(v, dflt = 0) {
  const n = Number(v);
  return Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : dflt;
}

/**
 * @param {object}  a               model analysis (RESPONSE_SCHEMA shape)
 * @param {object}  [ctx]
 * @param {boolean} [ctx.serverDetectedDuplicate]  exact name+city already in `colleges`
 */
function decideCollege(a, ctx = {}) {
  a = a || {};
  const spam = a.isGibberishOrSpam === true;
  const nameScore = num(a.nameLooksLikeCollege);
  const existsScore = num(a.collegePlausiblyExists);
  const addressScore = num(a.addressPlausible, 0.5);
  const universityScore = num(a.universityPlausible, 0.5);
  const authenticity = num(a.authenticityScore);
  const websiteVerdict = String(a.websiteVerdict || 'not_provided');
  const photoVerdict = String(a.photoVerdict || 'not_provided');
  const concerns = Array.isArray(a.concerns)
    ? a.concerns.filter((s) => typeof s === 'string' && s.trim()).slice(0, 8)
    : [];

  const flags = [];
  if (websiteVerdict === 'parked_or_unrelated' || websiteVerdict === 'unreachable') {
    flags.push('website_unverified');
  }
  if (['stock_or_logo', 'unrelated', 'ai_generated', 'not_an_image'].includes(photoVerdict)) {
    flags.push('photo_unverified');
  }
  if (addressScore < 0.4) flags.push('address_doubtful');
  if (universityScore < 0.4) flags.push('affiliation_doubtful');
  if (ctx.serverDetectedDuplicate) flags.push('possible_duplicate');

  const checks = {
    nameScore,
    existsScore,
    addressScore,
    universityScore,
    websiteVerdict,
    photoVerdict,
    authenticity,
    serverDetectedDuplicate: !!ctx.serverDetectedDuplicate,
    concerns,
  };

  const confidence = Math.round(
    (0.5 * authenticity + 0.3 * nameScore + 0.2 * existsScore) * 100,
  ) / 100;

  if (ctx.serverDetectedDuplicate) {
    return {
      decision: AI_DECISION.REJECT,
      confidence,
      reason: 'A college with this name already exists in the directory for this city.',
      flags: dedupe(flags),
      checks,
    };
  }
  if (spam || nameScore < 0.25 || confidence <= T.AUTO_REJECT_CONFIDENCE) {
    return {
      decision: AI_DECISION.REJECT,
      confidence,
      reason: spam
        ? 'Submission looks like spam or gibberish, not a real institution.'
        : `Automated checks scored this submission too low (${concerns[0] || 'not recognisable as a real college'}).`,
      flags: dedupe(flags),
      checks,
    };
  }

  return {
    decision: AI_DECISION.FLAG,
    confidence,
    reason:
      concerns[0] ||
      (flags.length
        ? `Plausible but ${flags.length} check(s) need a human.`
        : 'Plausible submission — confirm details before importing.'),
    flags: dedupe(flags),
    checks,
  };
}

/**
 * Strip a fetched HTML page down to a short plain-text snippet for the
 * prompt. Deliberately crude — we just need enough for the model to tell a
 * real college site from a parked domain.
 */
function htmlToSnippet(html, maxChars = T.WEBSITE_SNIPPET_CHARS) {
  if (typeof html !== 'string') return '';
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, maxChars);
}

async function fetchWebsiteSnippet(rawUrl) {
  if (typeof rawUrl !== 'string' || !rawUrl.trim()) return null;
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), T.WEBSITE_FETCH_TIMEOUT_MS);
    // The submitter chose this URL — vet it (and every redirect hop) so it
    // can't point the fetch at localhost / a private host / cloud
    // metadata. See util/safeFetch.js.
    const res = await fetchWithHostGuard(rawUrl, {
      signal: controller.signal,
      headers: { 'User-Agent': 'CollegeRealityVerifier/1.0' },
    });
    clearTimeout(timer);
    if (!res.ok) return null;
    const ct = res.headers.get('content-type') || '';
    if (!ct.includes('text/html') && !ct.includes('text/plain')) return null;
    const html = await res.text();
    const snippet = htmlToSnippet(html);
    return snippet || null;
  } catch (_) {
    return null;
  }
}

function dedupe(arr) {
  return [...new Set(arr)];
}

module.exports = {
  buildPrompt,
  decideCollege,
  htmlToSnippet,
  fetchWebsiteSnippet,
  RESPONSE_SCHEMA,
};
