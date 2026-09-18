'use strict';

// Shared FCM push-sending helper for the three triggers in
// pushNotificationTriggers.js (badge verified, chat message, incoming
// call). Every one of those already has a working IN-APP notification
// path (Firestore `user_notifications` docs, written by
// notifyUser()/notify.js) -- this module is purely the PUSH half: getting
// something onto the device when the app isn't in the foreground to see
// that Firestore write happen live.

const { getMessaging } = require('firebase-admin/messaging');
const { logger } = require('firebase-functions');
const { db } = require('./admin');

/**
 * Sends one FCM push to a user by uid, reading their token from
 * `users/{uid}.fcmToken` -- written by the Flutter client on login (see
 * FirebaseMessagingService.initialize() / FirestoreEngagementService.
 * saveFcmToken in lib/features/engagement/services/).
 *
 * Deliberately a DATA-ONLY message (no top-level `notification` block).
 * The Flutter app already renders every push itself via
 * flutter_local_notifications on its own 'college_reality_alerts' channel
 * -- both from the background isolate entry point
 * (firebaseMessagingBackgroundHandler) and the foreground listener (see
 * lib/features/engagement/services/firebase_messaging_service.dart). A
 * `notification` block here would let the OS auto-display it as well,
 * double-showing it and bypassing that channel/styling. The `data` shape
 * below (userId/type/category/title/body/entityType/entityId/actionRoute)
 * is exactly what that handler already expects -- not invented for this
 * feature, reused from the existing in-app-notification convention.
 *
 * Best-effort by design: every caller here is a Firestore trigger, and a
 * push failure must never fail (and so retry) the write that triggered
 * it. A dead/rotated token is routine (reinstall, sign-out on that
 * device) -- clear it so later sends stop hitting the same dead token,
 * but every other failure is just logged.
 */
async function sendPushToUser({
  uid,
  title,
  body,
  type,
  category = '',
  entityType = '',
  entityId = '',
  actionRoute = '',
  highPriority = false,
}) {
  try {
    const snap = await db.collection('users').doc(uid).get();
    const token = snap.exists ? snap.data().fcmToken : null;
    if (!token) return;

    await getMessaging().send({
      token,
      data: {
        userId: uid,
        type,
        category,
        title,
        body,
        entityType,
        entityId: entityId || uid,
        actionRoute,
      },
      android: {
        // Data messages need explicit high priority to be delivered
        // promptly rather than batched -- every push here (a badge, a
        // chat message, a call) is time-relevant enough to warrant it,
        // not just the call case.
        priority: 'high',
      },
      apns: {
        headers: {
          // A ringing call needs to interrupt immediately; a badge/chat
          // push can tolerate APNs' normal best-effort delivery.
          'apns-priority': highPriority ? '10' : '5',
        },
        payload: {
          // content-available wakes a backgrounded/killed iOS app for a
          // silent (data-only, no alert/sound at the OS level) push --
          // required for firebaseMessagingBackgroundHandler to run there
          // the same way it does on Android.
          aps: { 'content-available': 1 },
        },
      },
    });
  } catch (e) {
    const code = e && e.code;
    if (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-argument'
    ) {
      await db
        .collection('users')
        .doc(uid)
        .set({ fcmToken: null }, { merge: true })
        .catch(() => {});
    }
    logger.warn('[push] sendPushToUser failed', {
      uid,
      type,
      error: e && e.message,
    });
  }
}

module.exports = { sendPushToUser };
