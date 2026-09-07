'use strict';

const { VERIFICATION_CONFIG } = require('./config');

const GEMINI_BASE_URL =
  'https://generativelanguage.googleapis.com/v1beta/models';

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// 4xx (bad key / bad request / quota) is never worth retrying — same
// failure, double the cost. Network + 5xx are transient: one retry.
function isRetryable(err) {
  if (err && err.name === 'AbortError') return true;
  if (err && typeof err.status === 'number') return err.status >= 500;
  return true;
}

/**
 * One multimodal Gemini call that returns STRICT JSON.
 *
 * @param {object}   opts
 * @param {string}   opts.apiKey        Secret Manager value (never logged).
 * @param {string}   opts.systemPrompt
 * @param {string}   opts.userPrompt
 * @param {Array<{mimeType:string, base64:string}>} [opts.files]  inline docs
 * @param {object}   opts.responseSchema  Gemini responseSchema (required — the
 *                    whole point is a machine-parseable verdict).
 * @returns {Promise<{ data:object, raw:string, inputTokens:number|null,
 *                     outputTokens:number|null }>}
 * @throws  on missing key, timeout, non-2xx, empty/invalid JSON.
 */
async function analyzeJson({
  apiKey,
  systemPrompt,
  userPrompt,
  files = [],
  responseSchema,
}) {
  if (!apiKey) {
    const err = new Error('Gemini API key not configured');
    err.code = 'ai/not-configured';
    throw err;
  }
  if (!responseSchema || typeof responseSchema !== 'object') {
    throw new Error('analyzeJson requires a responseSchema');
  }

  const url =
    `${GEMINI_BASE_URL}/${VERIFICATION_CONFIG.MODEL_NAME}:generateContent?key=${apiKey}`;

  const parts = [{ text: userPrompt }];
  for (const f of files) {
    if (!f || !f.base64 || !f.mimeType) continue;
    parts.push({ inlineData: { mimeType: f.mimeType, data: f.base64 } });
  }

  const body = {
    systemInstruction: { parts: [{ text: systemPrompt }] },
    contents: [{ role: 'user', parts }],
    generationConfig: {
      maxOutputTokens: VERIFICATION_CONFIG.MAX_OUTPUT_TOKENS,
      temperature: VERIFICATION_CONFIG.TEMPERATURE,
      responseMimeType: 'application/json',
      responseSchema,
    },
  };

  let lastErr;
  const attempts = 1 + VERIFICATION_CONFIG.MAX_RETRIES;
  for (let attempt = 0; attempt < attempts; attempt++) {
    const controller = new AbortController();
    const timer = setTimeout(
      () => controller.abort(),
      VERIFICATION_CONFIG.REQUEST_TIMEOUT_MS,
    );
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        signal: controller.signal,
      });
      clearTimeout(timer);

      if (!res.ok) {
        const errText = await res.text().catch(() => '');
        const err = new Error(
          `Gemini vision API ${res.status}: ${errText.slice(0, 300)}`,
        );
        err.status = res.status;
        throw err;
      }

      const json = await res.json();
      const candidate = json.candidates && json.candidates[0];
      const raw =
        candidate &&
        candidate.content &&
        candidate.content.parts &&
        candidate.content.parts.map((p) => p.text || '').join('').trim();

      if (!raw) {
        const err = new Error('Gemini returned no usable text');
        err.code = 'ai/empty-response';
        throw err;
      }

      let data;
      try {
        data = JSON.parse(raw);
      } catch (_) {
        const err = new Error('Gemini response was not valid JSON');
        err.code = 'ai/bad-json';
        err.raw = raw.slice(0, 500);
        throw err;
      }

      const usage = json.usageMetadata || {};
      return {
        data,
        raw,
        inputTokens: usage.promptTokenCount ?? null,
        outputTokens: usage.candidatesTokenCount ?? null,
      };
    } catch (err) {
      clearTimeout(timer);
      lastErr = err;
      if (attempt < attempts - 1 && isRetryable(err)) {
        await sleep(400 * (attempt + 1));
        continue;
      }
      throw err;
    }
  }
  throw lastErr;
}

module.exports = { analyzeJson };
