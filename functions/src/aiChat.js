'use strict';

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const { GEMINI_API_KEY } = require('./params');
const { answerChatTurn } = require('./ai/aiChatService');
const { AI_CHAT_CONFIG } = require('./ai/config');

function sanitizeString(value, maxLen) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  return trimmed.slice(0, maxLen);
}

function sanitizeCollegeContext(raw) {
  if (!raw || typeof raw !== 'object') return null;
  return {
    name: sanitizeString(raw.name, 200),
    city: sanitizeString(raw.city, 100),
    state: sanitizeString(raw.state, 100),
    category: sanitizeString(raw.category, 60),
    crScore: typeof raw.crScore === 'number' ? raw.crScore : null,
    feesMin: typeof raw.feesMin === 'number' ? raw.feesMin : null,
    feesMax: typeof raw.feesMax === 'number' ? raw.feesMax : null,
    avgPackageLpa: typeof raw.avgPackageLpa === 'number' ? raw.avgPackageLpa : null,
    highestPackageLpa: typeof raw.highestPackageLpa === 'number' ? raw.highestPackageLpa : null,
    placementPct: typeof raw.placementPct === 'number' ? raw.placementPct : null,
    hostelAvailable: typeof raw.hostelAvailable === 'boolean' ? raw.hostelAvailable : null,
    reviewExcerpts: Array.isArray(raw.reviewExcerpts)
      ? raw.reviewExcerpts.filter((x) => typeof x === 'string').slice(0, 5)
      : [],
    verifiedAnswerExcerpts: Array.isArray(raw.verifiedAnswerExcerpts)
      ? raw.verifiedAnswerExcerpts.filter((x) => typeof x === 'string').slice(0, 5)
      : [],
  };
}

function sanitizeCandidates(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .slice(0, AI_CHAT_CONFIG.MAX_CANDIDATE_COLLEGES)
    .filter((c) => c && typeof c === 'object' && typeof c.name === 'string')
    .map((c) => ({
      id: sanitizeString(c.id, 100),
      name: sanitizeString(c.name, 200),
      city: sanitizeString(c.city, 100),
      state: sanitizeString(c.state, 100),
      crScore: typeof c.crScore === 'number' ? c.crScore : null,
      avgPackageLpa: typeof c.avgPackageLpa === 'number' ? c.avgPackageLpa : null,
      placementPct: typeof c.placementPct === 'number' ? c.placementPct : null,
      feesMin: typeof c.feesMin === 'number' ? c.feesMin : null,
    }));
}

function sanitizeHistory(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .slice(-AI_CHAT_CONFIG.MAX_HISTORY_TURNS)
    .filter((h) => h && (h.role === 'user' || h.role === 'assistant') && typeof h.text === 'string')
    .map((h) => ({ role: h.role, text: h.text.slice(0, 500) }));
}

/**
 * Flutter -> this callable -> Gemini. The only place the Gemini API key is
 * ever read (Secret Manager, injected at invocation time) — it never
 * reaches the client. See functions/README.md for required setup.
 *
 * Request shape: { question, mode: 'college'|'explore', collegeId?,
 *   collegeContext?, candidateColleges?, history?, filters? }
 * Response shape: { text, cached, isGeneralAdvice }
 */
const aiChatComplete = onCall(
  { secrets: [GEMINI_API_KEY], timeoutSeconds: 30, memory: '256MiB' },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const data = request.data || {};
    const question = sanitizeString(data.question, 1000);
    if (!question) throw new HttpsError('invalid-argument', 'question is required.');

    const mode = data.mode === 'college' ? 'college' : 'explore';
    const collegeId = sanitizeString(data.collegeId, 100);
    const collegeContext = mode === 'college' ? sanitizeCollegeContext(data.collegeContext) : null;
    const candidateColleges = mode === 'explore' ? sanitizeCandidates(data.candidateColleges) : [];
    const history = sanitizeHistory(data.history);
    const filters = data.filters && typeof data.filters === 'object'
      ? {
          city: sanitizeString(data.filters.city, 100),
          state: sanitizeString(data.filters.state, 100),
          course: sanitizeString(data.filters.course, 100),
        }
      : null;

    try {
      const result = await answerChatTurn({
        uid,
        question,
        mode,
        collegeId,
        collegeContext,
        candidateColleges,
        history,
        filters,
        apiKey: GEMINI_API_KEY.value(),
      });
      return result;
    } catch (err) {
      if (err && err.code === 'ai/rate-limited') {
        throw new HttpsError(
          'resource-exhausted',
          "You've reached today's AI chat limit. Please try again tomorrow.",
        );
      }
      // Never leak raw provider errors (could contain request internals)
      // to the client — full detail is already in the server-side log
      // from aiChatService.js.
      logger.error('[aiChatComplete] unhandled failure', {
        mode,
        errorType: err && err.constructor && err.constructor.name,
      });
      throw new HttpsError('unavailable', 'AI assistant is temporarily unavailable.');
    }
  },
);

module.exports = { aiChatComplete };
