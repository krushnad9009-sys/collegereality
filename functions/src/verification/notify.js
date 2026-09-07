'use strict';

const { db } = require('../admin');

// Mirrors lib/.../firestore_engagement_service.dart createNotificationFromDraft:
// same doc shape, same dedupe id (`${uid}_${type}_${entityId}`). The dedupe
// id also makes this idempotent, which matters because a Firestore trigger
// can be retried — a re-run must not spam the user with a second copy.
function dedupeId(uid, type, entityId) {
  return `${uid}_${type}_${entityId}`;
}

/**
 * Writes a user_notifications doc as the trusted backend. Best-effort by
 * design: a notification failure must never fail (or retry) the whole
 * verification decision — the caller wraps this in try/catch.
 */
async function notifyUser({
  uid,
  type,
  category,
  title,
  body = '',
  entityType = '',
  entityId = '',
  actionRoute = '',
}) {
  const id = dedupeId(uid, type, entityId || uid);
  const ref = db.collection('user_notifications').doc(id);
  const existing = await ref.get();
  if (existing.exists) return;

  const searchText = [title, body, type, category]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();

  await ref.set({
    id,
    userId: uid,
    type,
    category,
    title,
    body,
    entityType,
    entityId: entityId || uid,
    actionRoute,
    isRead: false,
    searchText,
    createdAt: new Date().toISOString(),
  });
}

module.exports = { notifyUser };
