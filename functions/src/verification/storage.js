'use strict';

const { getStorage } = require('firebase-admin/storage');
const { VERIFICATION_CONFIG } = require('./config');

/**
 * Downloads a Cloud Storage object (given its bucket-relative path, the
 * `storagePath` the Flutter uploader stores on the request doc) into memory.
 *
 * @param {string} storagePath  e.g. "verification_documents/<uid>/<id>.jpg"
 * @returns {Promise<{ buffer: Buffer, contentType: string, size: number }>}
 * @throws  if the object is missing, or larger than MAX_DOC_BYTES.
 */
async function downloadObject(storagePath) {
  if (typeof storagePath !== 'string' || !storagePath.trim()) {
    throw new Error('downloadObject: empty storagePath');
  }
  const file = getStorage().bucket().file(storagePath.trim());

  const [exists] = await file.exists();
  if (!exists) {
    const err = new Error(`Storage object not found: ${storagePath}`);
    err.code = 'verify/document-missing';
    throw err;
  }

  const [meta] = await file.getMetadata();
  const size = Number(meta.size || 0);
  if (size > VERIFICATION_CONFIG.MAX_DOC_BYTES) {
    const err = new Error(
      `Document too large for automated review (${size} bytes)`,
    );
    err.code = 'verify/document-too-large';
    throw err;
  }

  const [buffer] = await file.download();
  return {
    buffer,
    contentType: meta.contentType || 'application/octet-stream',
    size: buffer.length,
  };
}

/**
 * Best-effort fetch of a possibly-remote image URL (college campus photo)
 * into memory. Returns null on any failure — a missing/broken photo is a
 * verification signal, never an error that should stop the pipeline.
 *
 * Accepts:
 *   - a bucket-relative Storage path  -> downloadObject
 *   - an https:// URL                 -> plain fetch, bounded
 * @returns {Promise<{ buffer: Buffer, contentType: string }|null>}
 */
async function tryFetchImage(urlOrPath) {
  if (typeof urlOrPath !== 'string' || !urlOrPath.trim()) return null;
  const value = urlOrPath.trim();

  try {
    if (!/^https?:\/\//i.test(value)) {
      const { buffer, contentType } = await downloadObject(value);
      if (!contentType.startsWith('image/')) return null;
      return { buffer, contentType };
    }

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 8000);
    const res = await fetch(value, { signal: controller.signal });
    clearTimeout(timer);
    if (!res.ok) return null;
    const contentType = res.headers.get('content-type') || '';
    if (!contentType.startsWith('image/')) return null;
    const arr = await res.arrayBuffer();
    const buffer = Buffer.from(arr);
    if (buffer.length > VERIFICATION_CONFIG.MAX_DOC_BYTES) return null;
    return { buffer, contentType: contentType.split(';')[0] };
  } catch (_) {
    return null;
  }
}

module.exports = { downloadObject, tryFetchImage };
