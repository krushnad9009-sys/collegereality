'use strict';

// Single source of truth for every AI-verification-agent knob. Mirrors the
// pattern of src/ai/config.js — change a value here and every enforcement
// point picks it up on next deploy. Nothing in this feature hard-codes a
// threshold anywhere else.
const VERIFICATION_CONFIG = {
  // Gemini model used for the vision + reasoning pass. Flash-Lite is
  // multimodal (accepts inline image/PDF parts) and is the cheapest
  // GA tier — same string src/ai/config.js already runs on. Swapping the
  // vendor means writing one module with geminiVision.js's shape.
  MODEL_NAME: 'gemini-3.5-flash-lite',

  // Vision analysis is a single, larger structured response than a chat
  // turn, and an image upload dominates latency — give it more room than
  // the 12s chat timeout.
  REQUEST_TIMEOUT_MS: 30000,
  MAX_RETRIES: 1,
  MAX_OUTPUT_TOKENS: 1024,
  // Near-deterministic: this is an extraction/scoring task, not creative.
  TEMPERATURE: 0.1,

  // Hard cap on the document bytes we will hand to the model. Storage
  // rules already cap uploads at 10MiB; this is the defensive server-side
  // ceiling (base64 inflates ~33%, and very large scans just waste tokens).
  MAX_DOC_BYTES: 7 * 1024 * 1024,

  // ── Student document decision thresholds ──────────────────────────────
  STUDENT: {
    // Overall confidence at/above this AND no disqualifier -> auto ACCEPT.
    AUTO_ACCEPT_CONFIDENCE: 0.82,
    // Overall confidence at/below this (or a hard disqualifier) -> auto
    // REJECT. Everything between the two bands -> FLAG for a human.
    AUTO_REJECT_CONFIDENCE: 0.3,
    // Per-signal minimums required for an ACCEPT.
    MIN_CLARITY: 0.55,
    MIN_NAME_MATCH: 0.7,
    MIN_DOC_TYPE_MATCH: 0.7,
    // Tamper score at/above this is always a hard disqualifier (REJECT).
    MAX_TAMPER_FOR_ACCEPT: 0.25,
    HARD_TAMPER_REJECT: 0.7,
  },

  // ── College listing decision thresholds ──────────────────────────────
  // Per the product decision: the agent AUTO-REJECTS spam/gibberish/
  // duplicates and FLAGS everything else with its score — it never
  // auto-approves a public directory entry.
  COLLEGE: {
    // Spam/authenticity score at/below this -> auto REJECT.
    AUTO_REJECT_CONFIDENCE: 0.22,
    WEBSITE_FETCH_TIMEOUT_MS: 6000,
    WEBSITE_SNIPPET_CHARS: 2500,
  },
};

// Stable identifier written into every request the agent touches, so
// admin UI / audit can tell an automated decision from a human one.
const AI_REVIEWER_ID = 'ai-agent';

// aiStatus lifecycle on a request doc.
const AI_STATUS = {
  PENDING: 'pending',
  PROCESSING: 'processing',
  DONE: 'done',
  ERROR: 'error',
};

// aiDecision values.
const AI_DECISION = {
  ACCEPT: 'accept',
  REJECT: 'reject',
  FLAG: 'flag',
};

module.exports = { VERIFICATION_CONFIG, AI_REVIEWER_ID, AI_STATUS, AI_DECISION };
