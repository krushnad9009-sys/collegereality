'use strict';

/**
 * Provider abstraction so aiChatService.js never talks to a specific LLM
 * vendor directly. Swapping providers later (or adding a second one and
 * A/B-ing) means writing one new module with this same shape and changing
 * getAiModelProvider()'s single return statement — nothing else in the
 * codebase (Flutter included, which never sees a provider at all) changes.
 *
 * Implementations must expose:
 *   async complete({ systemPrompt, userPrompt, maxOutputTokens, temperature })
 *     -> { text: string, inputTokens: number|null, outputTokens: number|null }
 *
 *   Must throw on failure (network, timeout, non-2xx, malformed response)
 *   so aiChatService.js's single retry/fallback logic handles every
 *   provider uniformly.
 */

const { getGeminiProvider } = require('./geminiProvider');

function getAiModelProvider(apiKey) {
  // Only one implementation today (Gemini Flash-Lite, per spec's preferred
  // initial provider) — this function is the one place that would change
  // to add/switch providers.
  return getGeminiProvider(apiKey);
}

module.exports = { getAiModelProvider };
