'use strict';

// Single source of truth for every AI-chat cost/behaviour knob. Nothing in
// this feature hard-codes a limit anywhere else — change a value here and
// every enforcement point (rate limiter, prompt builder, provider call)
// picks it up on next deploy.
const AI_CHAT_CONFIG = {
  // Per-user daily cap on LLM calls (cache hits and DB-only answers don't
  // count against this — see aiChatService.js). Generous enough for real
  // usage, low enough that a runaway client loop can't run up a real bill.
  DAILY_REQUEST_LIMIT: 40,

  // Gemini model. "Flash-Lite" is the cheapest generally-available Gemini
  // tier suitable for short, grounded conversational replies — swapping
  // this string (or the whole provider, via ai_model_provider.js) never
  // requires touching aiChatService.js or the Flutter client.
  //
  // gemini-2.5-flash-lite was retired for new users (confirmed live via a
  // 404 from the Gemini API on 2026-08-31: "no longer available to new
  // users... use models/gemini-3.5-flash-lite"); switched per that
  // response, which is the authoritative source for the current
  // replacement model name.
  MODEL_NAME: 'gemini-3.5-flash-lite',

  // Keep replies short and concise per spec — also directly controls
  // per-request cost, since output tokens are billed.
  MAX_OUTPUT_TOKENS: 260,
  TEMPERATURE: 0.35,

  // Bounds the whole outbound call (network + generation) so a slow/stuck
  // upstream response can never hang a request indefinitely.
  REQUEST_TIMEOUT_MS: 12000,
  // One retry only, and only for retryable (5xx/network) failures — never
  // retries on a bad request or an auth failure, and never loops.
  MAX_RETRIES: 1,

  // Cached answers are reused for this long before being treated as stale
  // and regenerated. Safe because cache entries never contain user-
  // specific data (see aiChatService.js's cache-key normalisation).
  CACHE_TTL_SECONDS: 12 * 60 * 60,

  // Cost/context-size ceilings — the client is expected to already send
  // compact, pre-retrieved, pre-ranked data (never the full 45,020+
  // college directory); these are a defensive second layer server-side.
  MAX_CANDIDATE_COLLEGES: 10,
  MAX_REVIEW_EXCERPTS: 3,
  MAX_HISTORY_TURNS: 4,
  MAX_INPUT_CHARS: 6000,
};

module.exports = { AI_CHAT_CONFIG };
