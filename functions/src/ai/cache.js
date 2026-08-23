'use strict';

const crypto = require('crypto');
const { db } = require('../admin');
const { AI_CHAT_CONFIG } = require('./config');

/**
 * Builds a cache key from ONLY normalized, non-personal fields: the
 * question text and whatever college/filter context grounds it. uid is
 * deliberately never part of this — two different students asking the
 * same question about the same college should hit the same cache entry,
 * and nothing personal ever gets included in what's cached (satisfies the
 * "never cache personalized/private info" requirement by construction,
 * not by convention).
 */
function buildCacheKey({ question, collegeId, mode, filters }) {
  const normalizedQuestion = String(question || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ');
  const payload = JSON.stringify({
    q: normalizedQuestion,
    collegeId: collegeId || null,
    mode: mode || null,
    filters: filters || null,
  });
  return crypto.createHash('sha256').update(payload).digest('hex');
}

async function getCached(key) {
  const snap = await db.collection('aiChatCache').doc(key).get();
  if (!snap.exists) return null;
  const data = snap.data();
  const ageSeconds = (Date.now() - new Date(data.createdAt).getTime()) / 1000;
  if (ageSeconds > AI_CHAT_CONFIG.CACHE_TTL_SECONDS) return null;
  return data.text;
}

async function setCached(key, text) {
  await db.collection('aiChatCache').doc(key).set({
    text,
    createdAt: new Date().toISOString(),
  });
}

module.exports = { buildCacheKey, getCached, setCached };
