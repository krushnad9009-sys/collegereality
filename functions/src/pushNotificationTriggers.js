'use strict';

// Three FCM push triggers, each reacting to a write that already happens
// today via the normal client (or the AI verification agent) -- none of
// these require any client code to call a new endpoint. See push.js for
// the actual admin.messaging().send() call and why it's data-only.

const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const { db } = require('./admin');
const { sendPushToUser } = require('./push');

/**
 * Badge verified/granted push.
 *
 * Fires on the `false -> true` (or "never set" -> true) transition of
 * `users/{uid}.isVerified`, from EITHER of the two paths that set it:
 *   - Super Admin panel's manual override
 *     (AdminUserModerationService.setStudentVerified)
 *   - The AI document-verification agent's auto-ACCEPT path
 *     (functions/src/verificationTriggers.js)
 * Both write the exact same isVerified/verificationBadge/verificationStatus
 * fields to the same document, so one trigger here covers both instead of
 * duplicating a "send the badge push" call in two separate places (one
 * Dart, one JS). Explicitly requires the false/absent -> true transition
 * (not just "isVerified is true after this write") so an unrelated
 * profile edit on an already-verified user doesn't re-fire it.
 */
const onUserVerificationBadgeGranted = onDocumentUpdated(
  'users/{uid}',
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};
    const uid = event.params.uid;

    const wasVerified = before.isVerified === true;
    const nowVerified = after.isVerified === true;
    if (wasVerified || !nowVerified) return;

    const badge = after.verificationBadge || 'verified_student';
    const badgeName =
      badge === 'verified_alumni' ? 'Verified Alumni badge' : 'Verified Student badge';
    const name =
      after.displayName || after.publicDisplayName || after.customDisplayName || 'there';

    await sendPushToUser({
      uid,
      title: `🏆 Congratulations ${name}!`,
      body: `Your ${badgeName} has been successfully verified! Click here to view your badge.`,
      type: 'verification_approved',
      category: 'colleges',
      entityType: 'user',
      entityId: uid,
      actionRoute: '/profile',
    });
  },
);

/**
 * 1-on-1 chat message push.
 *
 * `community_messages` is a top-level collection (each doc carries its
 * own `conversationId`, not a subcollection of `community_conversations`)
 * -- see CommunityFirestoreService.sendMessage /
 * FirestoreConstants.communityMessagesCollection. Only private
 * (1-on-1) conversations get a push here; group/college/branch/ask-
 * seniors/Q&A conversations already have their own in-app notification
 * path and would need very different fan-out (multiple recipients, likely
 * rate-limited) that's out of scope for what was asked.
 */
const onChatMessageCreated = onDocumentCreated(
  'community_messages/{messageId}',
  async (event) => {
    const msg = event.data.data();
    const conversationId = msg.conversationId;
    const senderId = msg.senderId;
    if (!conversationId || !senderId) return;

    const convoSnap = await db.collection('community_conversations').doc(conversationId).get();
    if (!convoSnap.exists) return;
    const convo = convoSnap.data();
    if (convo.type !== 'private') return;

    const participantIds = convo.participantIds || [];
    const recipientId = participantIds.find((id) => id !== senderId);
    if (!recipientId) return;

    const messageType = msg.messageType;
    let body;
    if (messageType === 'image') {
      body = 'Sent you an image';
    } else if (messageType === 'pdf') {
      body = 'Sent you a file';
    } else {
      body = msg.text || '';
    }

    await sendPushToUser({
      uid: recipientId,
      title: msg.senderName || 'New message',
      body,
      type: 'new_chat_message',
      category: 'chat',
      entityType: 'conversation',
      entityId: conversationId,
      actionRoute: `/community/chat/${conversationId}`,
    });
  },
);

/**
 * Incoming voice/video call push -- high priority (rings through even
 * with the app backgrounded/killed, unlike the in-app-only
 * IncomingCallBanner, which only ever shows while the app is already
 * open and watching incomingCallsProvider).
 *
 * Fires only on a session's initial creation with status 'requested'
 * (CommunicationConstants.callStatusRequested) -- the moment
 * CommunicationService.requestCall() first writes it -- not on later
 * transitions (accepted/ended/etc), which aren't "someone is calling you".
 */
const onCallSessionCreated = onDocumentCreated(
  'call_sessions/{sessionId}',
  async (event) => {
    const call = event.data.data();
    const sessionId = event.params.sessionId;
    if (call.status !== 'requested') return;
    if (!call.calleeId) return;

    await sendPushToUser({
      uid: call.calleeId,
      title: 'Incoming Call',
      body: `${call.callerAlias || 'Someone'} is calling you...`,
      type: 'incoming_call',
      category: 'calls',
      entityType: 'call_session',
      entityId: sessionId,
      actionRoute: `/call/${sessionId}`,
      highPriority: true,
    });

    logger.info('[push] incoming call push sent', { sessionId, calleeId: call.calleeId });
  },
);

module.exports = {
  onUserVerificationBadgeGranted,
  onChatMessageCreated,
  onCallSessionCreated,
};
