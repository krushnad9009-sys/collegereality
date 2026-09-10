'use strict';

// AI Automated Verification Agent — background processing for the Super
// Admin panel. Two Firestore-create triggers:
//
//   verification_requests/{id}  -> student document verification
//        (Vision AI extract + match vs profile -> ACCEPT / REJECT / FLAG,
//         full auto: ACCEPT grants the badge, REJECT records a reason,
//         FLAG leaves it in the admin queue).
//
//   college_requests/{id}       -> new-college listing verification
//        (address / website / campus photo / credentials + duplicate check
//         -> auto-REJECT spam & duplicates, FLAG everything else with a
//         full AI report; a human still imports the actual college doc).
//
// Nothing here is ever client-callable. All writes are via the Admin SDK
// (bypasses firestore.rules). Any internal failure -> FLAG, never a
// silent auto-reject.

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const { FieldValue } = require('firebase-admin/firestore');
const { db } = require('./admin');
const { GEMINI_API_KEY } = require('./params');
const {
  VERIFICATION_CONFIG,
  AI_REVIEWER_ID,
  AI_STATUS,
  AI_DECISION,
} = require('./verification/config');
const { analyzeJson } = require('./verification/geminiVision');
const { downloadObject, tryFetchImage } = require('./verification/storage');
const { assertOwnedStoragePath } = require('./util/safeFetch');
const { notifyUser } = require('./verification/notify');
const studentAgent = require('./verification/studentDocAgent');
const collegeAgent = require('./verification/collegeListingAgent');

const FN_OPTS = {
  secrets: [GEMINI_API_KEY],
  timeoutSeconds: 120,
  memory: '512MiB',
  // At-least-once: a transient crash (OOM, cold-start timeout mid-Gemini)
  // is redelivered by the platform. claimForProcessing's stale-claim
  // recovery + finalize*'s transactional guard make that safe & idempotent.
  retry: true,
};

// A claim older than this is assumed dead (function timeout is 120s) and
// may be re-claimed by a redelivery.
const STALE_CLAIM_MS = 3 * 60 * 1000;

const nowIso = () => new Date().toISOString();

/**
 * Claims a request doc for processing. Returns false if a verdict is
 * already recorded, or another invocation holds a *fresh* claim. A stale
 * `processing` claim (crashed run) can be re-claimed so redelivery
 * recovers it.
 */
async function claimForProcessing(ref) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return false;
    const d = snap.data();
    if (d.aiReviewedAt || d.aiStatus === AI_STATUS.DONE) return false;
    if (d.aiStatus === AI_STATUS.PROCESSING) {
      const claimedMs = Date.parse(d.aiClaimedAt || '') || 0;
      if (Date.now() - claimedMs < STALE_CLAIM_MS) return false; // fresh — someone else has it
    }
    tx.update(ref, { aiStatus: AI_STATUS.PROCESSING, aiClaimedAt: nowIso() });
    return true;
  });
}

/**
 * Applies `updates` to `ref` only if the doc has not already reached a
 * terminal AI verdict, and returns whether this call is the one that
 * transitioned it (so one-shot side effects — badge grant, college count
 * bump, notifications — run exactly once even under redelivery).
 */
async function finalizeOnce(ref, updates) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return false;
    const d = snap.data();
    // A human may have acted between our claim and now — never stomp that.
    if (d.reviewedBy && d.reviewedBy !== AI_REVIEWER_ID) return false;
    if (d.aiReviewedAt && d.aiStatus === AI_STATUS.DONE) return false;
    tx.update(ref, updates);
    return true;
  });
}

// ─────────────────────────────────────────────────────────────────────────
// 1. STUDENT DOCUMENT VERIFICATION
// ─────────────────────────────────────────────────────────────────────────

const onVerificationRequestCreated = onDocumentCreated(
  { document: 'verification_requests/{requestId}', ...FN_OPTS },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const ref = snap.ref;
    const req = snap.data();
    const requestId = event.params.requestId;

    // Only act on a fresh client submission awaiting review.
    if (!['pending_review', 'flagged'].includes(req.status)) return;
    if (!(await claimForProcessing(ref))) {
      logger.info(`[verifyDoc ${requestId}] already claimed/done — skipping`);
      return;
    }

    try {
      const userSnap = await db.collection('users').doc(req.userId).get();
      const user = userSnap.exists ? userSnap.data() : {};
      const expectedName =
        (user.verifiedRealName || user.displayName || '').toString().trim();
      const expectedCollege =
        (req.collegeName || user.collegeName || '').toString().trim();

      // The submitter chose `storagePath`; it MUST be one of their own
      // uploads. Without this a request could name any object in the
      // bucket (another user's ID doc / resume) and read the extracted
      // fields back off its own doc — see util/safeFetch.js.
      let ownedPath;
      try {
        ownedPath = assertOwnedStoragePath(
          req.storagePath,
          req.userId,
          ['verification_documents'],
        );
        for (const p of Array.isArray(req.storagePaths) ? req.storagePaths : []) {
          assertOwnedStoragePath(p, req.userId, ['verification_documents']);
        }
      } catch (pathErr) {
        logger.warn(`[verifyDoc ${requestId}] rejected foreign storagePath`, {
          userId: req.userId,
        });
        await finalizeStudent(ref, req, {
          decision: AI_DECISION.FLAG,
          confidence: 0,
          reason: 'Document path does not belong to the submitter.',
          flags: ['invalid_path'],
          checks: {},
          extracted: {},
          model: VERIFICATION_CONFIG.MODEL_NAME,
        });
        return;
      }

      const { buffer, contentType } = await downloadObject(ownedPath);
      const mimeType = contentType.startsWith('image/')
        ? contentType
        : contentType === 'application/pdf'
          ? 'application/pdf'
          : null;

      if (!mimeType) {
        await finalizeStudent(ref, req, {
          decision: AI_DECISION.FLAG,
          confidence: 0,
          reason: `Unsupported file type for automated review (${contentType}).`,
          flags: ['invalid_format'],
          checks: { contentType },
          extracted: {},
          model: VERIFICATION_CONFIG.MODEL_NAME,
        });
        return;
      }

      const { systemPrompt, userPrompt, responseSchema } = studentAgent.buildPrompt({
        documentType: req.documentType,
        expectedName,
        expectedCollege,
        role: req.verificationRole,
      });

      const { data: analysis, inputTokens, outputTokens } = await analyzeJson({
        apiKey: GEMINI_API_KEY.value(),
        systemPrompt,
        userPrompt,
        files: [{ mimeType, base64: buffer.toString('base64') }],
        responseSchema,
      });

      const verdict = studentAgent.decide(analysis);
      logger.info(`[verifyDoc ${requestId}] ${verdict.decision}`, {
        confidence: verdict.confidence,
        documentType: req.documentType,
        inputTokens,
        outputTokens,
      });

      await finalizeStudent(ref, req, {
        decision: verdict.decision,
        confidence: verdict.confidence,
        reason: verdict.reason,
        flags: verdict.flags,
        checks: verdict.checks,
        extracted: {
          name: safeStr(analysis.extractedName),
          college: safeStr(analysis.extractedCollege),
          idNumberMasked: safeStr(analysis.idNumberMasked),
          documentKind: safeStr(analysis.documentKind),
        },
        model: VERIFICATION_CONFIG.MODEL_NAME,
      });
    } catch (err) {
      logger.error(`[verifyDoc ${requestId}] agent failed — flagging for manual review`, {
        errorCode: err && err.code,
        errorType: err && err.constructor && err.constructor.name,
        errorMessage: err && err.message,
      });
      await finalizeStudent(ref, req, {
        decision: AI_DECISION.FLAG,
        confidence: 0,
        reason: 'Automated review could not complete. Needs a human reviewer.',
        flags: [],
        checks: { error: (err && err.code) || 'unknown' },
        extracted: {},
        model: VERIFICATION_CONFIG.MODEL_NAME,
        errored: true,
      });
    }
  },
);

/**
 * Writes the AI fields on every outcome, then applies the side effects for
 * ACCEPT / REJECT (FLAG just parks it in the queue). Mirrors
 * VerificationFirestoreService.approveRequest / rejectRequest in Dart.
 */
async function finalizeStudent(ref, req, r) {
  const aiFields = {
    aiStatus: r.errored ? AI_STATUS.ERROR : AI_STATUS.DONE,
    aiDecision: r.decision,
    aiConfidence: r.confidence,
    aiSummary: r.reason,
    aiFlags: r.flags,
    aiChecks: r.checks,
    aiExtracted: r.extracted,
    aiModel: r.model,
    aiReviewedAt: nowIso(),
  };

  if (r.decision === AI_DECISION.ACCEPT) {
    const isAlumni =
      req.verificationRole === 'alumni' ||
      req.documentType === 'final_year_marksheet';
    const badge = isAlumni ? 'verified_alumni' : 'verified_student';

    const applied = await finalizeOnce(ref, {
      ...aiFields,
      status: 'approved',
      adminNote: `Auto-approved by AI agent — ${r.reason}`,
      reviewedBy: AI_REVIEWER_ID,
      reviewedAt: nowIso(),
      requiresManualReview: false,
    });
    if (!applied) return; // already decided (redelivery / human) — no double side-effects

    const userUpdate = {
      verificationBadge: badge,
      verificationStatus: 'approved',
      isVerified: true,
      updatedAt: nowIso(),
    };
    if (req.collegeId) {
      userUpdate.collegeId = req.collegeId;
      userUpdate.collegeName = req.collegeName || '';
    }
    await db.collection('users').doc(req.userId).set(userUpdate, { merge: true });
    // PII-free mirror (these fields carry no email/phone).
    await db
      .collection('public_profiles')
      .doc(req.userId)
      .set(userUpdate, { merge: true })
      .catch((e) => logger.warn('[verifyDoc] public_profiles mirror failed', { e: e && e.message }));

    if (req.collegeId && String(req.collegeId).trim()) {
      const countField = badge === 'verified_alumni'
        ? 'verifiedAlumniCount'
        : 'verifiedStudentCount';
      await db
        .collection('colleges')
        .doc(String(req.collegeId).trim())
        .set({ [countField]: FieldValue.increment(1), updatedAt: nowIso() }, { merge: true })
        .catch((e) => logger.warn('[verifyDoc] college count bump failed', { e: e && e.message }));
    }

    await safeNotify({
      uid: req.userId,
      type: 'verification_update',
      category: 'colleges',
      title: 'Verification approved',
      body: req.collegeName || '',
      entityType: 'verification',
      entityId: req.userId,
      actionRoute: '/verification',
    });
    return;
  }

  if (r.decision === AI_DECISION.REJECT) {
    const applied = await finalizeOnce(ref, {
      ...aiFields,
      status: 'rejected',
      adminNote: r.reason,
      reviewedBy: AI_REVIEWER_ID,
      reviewedAt: nowIso(),
      requiresManualReview: false,
    });
    if (!applied) return;

    await db.collection('users').doc(req.userId).set(
      { verificationStatus: 'rejected', updatedAt: nowIso() },
      { merge: true },
    );
    await safeNotify({
      uid: req.userId,
      type: 'verification_update',
      category: 'colleges',
      title: 'Verification rejected',
      body: r.reason,
      entityType: 'verification',
      entityId: req.userId,
      actionRoute: '/verification',
    });
    return;
  }

  // FLAG — stays in the human review queue with the AI notes attached.
  await finalizeOnce(ref, {
    ...aiFields,
    status: 'flagged',
    requiresManualReview: true,
  });
}

// ─────────────────────────────────────────────────────────────────────────
// 2. COLLEGE LISTING VERIFICATION
// ─────────────────────────────────────────────────────────────────────────

const onCollegeRequestCreated = onDocumentCreated(
  { document: 'college_requests/{requestId}', ...FN_OPTS },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const ref = snap.ref;
    const req = snap.data();
    const requestId = event.params.requestId;

    if (req.status !== 'pending_review') return;
    if (!(await claimForProcessing(ref))) {
      logger.info(`[verifyCollege ${requestId}] already claimed/done — skipping`);
      return;
    }

    try {
      const serverDetectedDuplicate = await hasDirectoryDuplicate(
        req.nameLower,
        req.cityLower,
      );

      const [websiteSnippet, photo] = await Promise.all([
        collegeAgent.fetchWebsiteSnippet(req.website),
        req.photoUrl
          ? tryFetchImage(req.photoUrl, {
              ownerUid: req.userId,
              roots: ['college_requests'],
            })
          : Promise.resolve(null),
      ]);

      const { systemPrompt, userPrompt, responseSchema } = collegeAgent.buildPrompt({
        name: req.name,
        city: req.city,
        state: req.state,
        address: req.address,
        website: req.website,
        universityName: req.universityName,
        notes: req.notes,
        websiteSnippet,
        hasPhoto: !!photo,
        duplicateOfName: serverDetectedDuplicate ? req.name : null,
      });

      const files = photo
        ? [{ mimeType: photo.contentType, base64: photo.buffer.toString('base64') }]
        : [];

      const { data: analysis, inputTokens, outputTokens } = await analyzeJson({
        apiKey: GEMINI_API_KEY.value(),
        systemPrompt,
        userPrompt,
        files,
        responseSchema,
      });

      const verdict = collegeAgent.decideCollege(analysis, { serverDetectedDuplicate });
      logger.info(`[verifyCollege ${requestId}] ${verdict.decision}`, {
        confidence: verdict.confidence,
        serverDetectedDuplicate,
        inputTokens,
        outputTokens,
      });

      await finalizeCollege(ref, req, {
        ...verdict,
        model: VERIFICATION_CONFIG.MODEL_NAME,
      });
    } catch (err) {
      logger.error(`[verifyCollege ${requestId}] agent failed — flagging`, {
        errorCode: err && err.code,
        errorType: err && err.constructor && err.constructor.name,
        errorMessage: err && err.message,
      });
      await finalizeCollege(ref, req, {
        decision: AI_DECISION.FLAG,
        confidence: 0,
        reason: 'Automated review could not complete. Needs a human reviewer.',
        flags: [],
        checks: { error: (err && err.code) || 'unknown' },
        model: VERIFICATION_CONFIG.MODEL_NAME,
        errored: true,
      });
    }
  },
);

async function hasDirectoryDuplicate(nameLower, cityLower) {
  if (!nameLower) return false;
  const q = await db
    .collection('colleges')
    .where('nameLower', '==', nameLower)
    .limit(5)
    .get();
  if (q.empty) return false;
  if (!cityLower) return true;
  return q.docs.some((d) => (d.data().cityLower || '') === cityLower);
}

async function finalizeCollege(ref, req, r) {
  const aiFields = {
    aiStatus: r.errored ? AI_STATUS.ERROR : AI_STATUS.DONE,
    aiDecision: r.decision,
    aiConfidence: r.confidence,
    aiSummary: r.reason,
    aiFlags: r.flags,
    aiChecks: r.checks,
    aiModel: r.model,
    aiReviewedAt: nowIso(),
  };

  if (r.decision === AI_DECISION.REJECT) {
    const applied = await finalizeOnce(ref, {
      ...aiFields,
      status: 'rejected',
      adminNotes: `Auto-rejected by AI agent — ${r.reason}`,
      updatedAt: nowIso(),
    });
    if (!applied) return;

    // Free the name/city slot in the public duplicate index (mirrors
    // EcosystemFirestoreService._duplicateRequestDocId: `${name}_${city}`
    // with any "/" replaced by "_").
    if (req.nameLower && req.cityLower) {
      const dupId = `${req.nameLower}_${req.cityLower}`.replace(/\//g, '_');
      await db
        .collection('college_request_duplicates')
        .doc(dupId)
        .delete()
        .catch(() => {});
    }
    await safeNotify({
      uid: req.userId,
      type: 'college_request_update',
      category: 'colleges',
      title: 'College request rejected',
      body: r.reason,
      entityType: 'college_request',
      entityId: ref.id,
      actionRoute: '/ecosystem/request-college',
    });
    return;
  }

  // FLAG — stays pending_review; the AI report rides along for the admin.
  await finalizeOnce(ref, { ...aiFields, updatedAt: nowIso() });
}

// ── shared helpers ────────────────────────────────────────────────────
function safeStr(v) {
  return typeof v === 'string' ? v.slice(0, 200) : '';
}
async function safeNotify(payload) {
  try {
    await notifyUser(payload);
  } catch (e) {
    logger.warn('[verify] notifyUser failed (non-fatal)', { e: e && e.message });
  }
}

module.exports = { onVerificationRequestCreated, onCollegeRequestCreated };
