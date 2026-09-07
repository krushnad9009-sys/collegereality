'use strict';

const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Default Cloud Storage bucket. `initializeApp()` with no options leaves
// `storageBucket` unset, and `getStorage().bucket()` then throws — so the
// AI verification agent (src/verification/storage.js) needs it named here.
// This project's bucket is `<projectId>.firebasestorage.app` (see
// lib/firebase_options.dart); GCLOUD_PROJECT is injected by the Functions
// runtime, with a literal fallback for local/test.
const projectId =
  process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || 'college-reality';
const storageBucket =
  process.env.STORAGE_BUCKET || `${projectId}.firebasestorage.app`;

if (getApps().length === 0) {
  initializeApp({ storageBucket });
}

const db = getFirestore();

module.exports = { db };
