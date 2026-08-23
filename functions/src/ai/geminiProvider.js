'use strict';

const { AI_CHAT_CONFIG } = require('./config');

const GEMINI_BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models';

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Whether a failure is worth retrying once. 4xx (bad key, bad request,
 * quota) never is — retrying those just doubles cost for the same
 * guaranteed failure. Network errors and 5xx are transient and worth one
 * retry.
 */
function isRetryable(err) {
  if (err && err.name === 'AbortError') return true; // our own timeout
  if (err && typeof err.status === 'number') return err.status >= 500;
  return true; // network-level failure (fetch threw before a response)
}

function getGeminiProvider(apiKey) {
  return {
    async complete({ systemPrompt, userPrompt, maxOutputTokens, temperature }) {
      if (!apiKey) {
        const err = new Error('Gemini API key not configured');
        err.code = 'ai/not-configured';
        throw err;
      }

      const url =
        `${GEMINI_BASE_URL}/${AI_CHAT_CONFIG.MODEL_NAME}:generateContent?key=${apiKey}`;

      const body = {
        systemInstruction: { parts: [{ text: systemPrompt }] },
        contents: [{ role: 'user', parts: [{ text: userPrompt }] }],
        generationConfig: {
          maxOutputTokens: maxOutputTokens || AI_CHAT_CONFIG.MAX_OUTPUT_TOKENS,
          temperature: temperature ?? AI_CHAT_CONFIG.TEMPERATURE,
        },
      };

      let lastErr;
      const attempts = 1 + AI_CHAT_CONFIG.MAX_RETRIES;
      for (let attempt = 0; attempt < attempts; attempt++) {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), AI_CHAT_CONFIG.REQUEST_TIMEOUT_MS);
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
            const err = new Error(`Gemini API ${res.status}: ${errText.slice(0, 300)}`);
            err.status = res.status;
            throw err;
          }

          const json = await res.json();
          const candidate = json.candidates && json.candidates[0];
          const text = candidate &&
            candidate.content &&
            candidate.content.parts &&
            candidate.content.parts.map((p) => p.text || '').join('').trim();

          if (!text) {
            const err = new Error('Gemini returned no usable text');
            err.code = 'ai/empty-response';
            throw err;
          }

          const usage = json.usageMetadata || {};
          return {
            text,
            inputTokens: usage.promptTokenCount ?? null,
            outputTokens: usage.candidatesTokenCount ?? null,
          };
        } catch (err) {
          clearTimeout(timer);
          lastErr = err;
          if (attempt < attempts - 1 && isRetryable(err)) {
            await sleep(300 * (attempt + 1));
            continue;
          }
          throw err;
        }
      }
      throw lastErr;
    },
  };
}

module.exports = { getGeminiProvider };
