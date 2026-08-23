'use strict';

const logger = require('firebase-functions/logger');
const { AI_CHAT_CONFIG } = require('./config');
const { buildCacheKey, getCached, setCached } = require('./cache');
const { consumeDailyQuota } = require('./rateLimiter');
const { buildPrompt } = require('./promptBuilder');
const { getAiModelProvider } = require('./aiModelProvider');

const GENERAL_ADVICE_MARKER = 'as general guidance';

/**
 * Orchestrates one chat turn: cache -> rate limit -> prompt -> provider.
 * This is the "AiChatService" from the spec — everything above it (the
 * onCall handler) only deals with auth/HTTP concerns, everything below it
 * (aiModelProvider) only deals with talking to one specific LLM vendor.
 *
 * uid is required (the onCall handler already enforces authentication) and
 * is used ONLY for the rate-limit counter — never included in the cache
 * key or logged in full.
 */
async function answerChatTurn({ uid, question, mode, collegeId, collegeContext, candidateColleges, history, filters, apiKey }) {
  const startedAt = Date.now();
  const cacheKey = buildCacheKey({ question, collegeId, mode, filters });

  const cached = await getCached(cacheKey);
  if (cached != null) {
    logger.info('[aiChat] cache hit', {
      mode,
      hasCollegeId: !!collegeId,
      latencyMs: Date.now() - startedAt,
    });
    return {
      text: cached,
      cached: true,
      isGeneralAdvice: cached.toLowerCase().includes(GENERAL_ADVICE_MARKER),
    };
  }

  // Only an actual LLM call consumes quota — cache hits are free reuse.
  await consumeDailyQuota(uid);

  const { systemPrompt, userPrompt } = buildPrompt({
    question,
    mode,
    collegeContext,
    candidateColleges,
    history,
  });

  const provider = getAiModelProvider(apiKey);
  let result;
  try {
    result = await provider.complete({
      systemPrompt,
      userPrompt,
      maxOutputTokens: AI_CHAT_CONFIG.MAX_OUTPUT_TOKENS,
      temperature: AI_CHAT_CONFIG.TEMPERATURE,
    });
  } catch (err) {
    logger.error('[aiChat] provider failure', {
      mode,
      hasCollegeId: !!collegeId,
      errorCode: err && err.code,
      errorStatus: err && err.status,
      latencyMs: Date.now() - startedAt,
    });
    throw err;
  }

  await setCached(cacheKey, result.text);

  logger.info('[aiChat] llm success', {
    mode,
    hasCollegeId: !!collegeId,
    inputTokens: result.inputTokens,
    outputTokens: result.outputTokens,
    latencyMs: Date.now() - startedAt,
  });

  return {
    text: result.text,
    cached: false,
    isGeneralAdvice: result.text.toLowerCase().includes(GENERAL_ADVICE_MARKER),
  };
}

module.exports = { answerChatTurn };
