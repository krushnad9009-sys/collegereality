'use strict';

const { db } = require('../admin');
const { AI_CHAT_CONFIG } = require('./config');

function todayKey() {
  // UTC date is fine for a daily cap — doesn't need to match any user's
  // local midnight exactly, just needs to reset once a day, every day.
  return new Date().toISOString().slice(0, 10); // YYYY-MM-DD
}

/**
 * Atomically checks and increments a per-user daily LLM-call counter.
 * Throws (does not increment) once the caller has hit
 * AI_CHAT_CONFIG.DAILY_REQUEST_LIMIT for the current UTC day. Cache hits
 * and DB-only answers must never call this — only an actual LLM call
 * counts against the limit.
 */
async function consumeDailyQuota(uid) {
  const ref = db.collection('aiUsage').doc(`${uid}_${todayKey()}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = snap.exists ? snap.data().count || 0 : 0;
    if (current >= AI_CHAT_CONFIG.DAILY_REQUEST_LIMIT) {
      const err = new Error('Daily AI chat limit reached');
      err.code = 'ai/rate-limited';
      throw err;
    }
    tx.set(
      ref,
      { count: current + 1, updatedAt: new Date().toISOString() },
      { merge: true },
    );
    return current + 1;
  });
}

module.exports = { consumeDailyQuota };
