import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/display_name_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/utils/firestore_auth_utils.dart';
import '../../../core/utils/firestore_error_utils.dart';
import '../models/user_model.dart';
import '../../communication/models/guide_stats_model.dart';
import '../../community/models/user_presence_model.dart';

class FirestoreUserService {
  static const String usersCollection = 'users';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update user document
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await FirestoreAuthUtils.ensureAuthenticated(expectedUid: user.uid);
      await _firestore.collection(usersCollection).doc(user.uid).set(
            user.toJson(),
            SetOptions(merge: true),
          );
      await syncPublicProfile(user.uid, user.toJson());
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(
        e,
        collectionPath: usersCollection,
        documentPath: user.uid,
        action: 'create/update user',
      );
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException(
        message: 'Could not save your profile. Please try again.',
      );
    }
  }

  // Get user by UID (any authenticated user may read public profile docs)
  Future<UserModel?> getUserByUID(String uid) async {
    try {
      await FirestoreAuthUtils.ensureAuthenticated();
      final doc =
          await _firestore.collection(usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(
        e,
        collectionPath: usersCollection,
        documentPath: uid,
        action: 'fetch user',
      );
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException(
        message: 'Could not load your profile. Please try again.',
      );
    }
  }

  // Get another user's PII-free public profile (safe for cross-user reads —
  // guide directory, connectable students, call setup). Use getUserByUID
  // only for the current user's own document.
  Future<UserModel?> getPublicProfileByUID(String uid) async {
    try {
      await FirestoreAuthUtils.ensureAuthenticated();
      final doc = await _firestore
          .collection(FirestoreConstants.publicProfilesCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(
        e,
        collectionPath: FirestoreConstants.publicProfilesCollection,
        documentPath: uid,
        action: 'fetch public profile',
      );
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException(
        message: 'Could not load this profile. Please try again.',
      );
    }
  }

  // Mirrors non-PII fields from a `users` write into public_profiles so
  // other users can discover/view this profile without ever reading
  // email/phone. Safe to call with a full user JSON or a partial update
  // map — email/phone are stripped either way.
  Future<void> syncPublicProfile(String uid, Map<String, dynamic> data) async {
    final safeFields = Map<String, dynamic>.from(data)
      ..remove('email')
      ..remove('phone');
    if (safeFields.isEmpty) return;
    try {
      await _firestore
          .collection(FirestoreConstants.publicProfilesCollection)
          .doc(uid)
          .set(safeFields, SetOptions(merge: true));
    } catch (_) {
      // Best-effort mirror; the source-of-truth `users` write already
      // succeeded, so a mirror hiccup should not fail the caller's action.
    }
  }

  // Get user stream
  Stream<UserModel?> getUserStream(String uid) {
    try {
      return _firestore
          .collection(usersCollection)
          .doc(uid)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return UserModel.fromJson(doc.data()!);
        }
        return null;
      });
    } catch (e) {
      throw FirestoreException(
        message: 'Could not load your profile. Please try again.',
      );
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? verifiedRealName,
    String? photoURL,
    String? coverPhotoURL,
    String? phone,
    String? collegeId,
    String? collegeName,
    String? course,
    String? branch,
    int? batchYear,
    String? aboutMe,
    List<String>? interests,
    List<String>? languagesKnown,
    GuideCommunicationSettings? communicationSettings,
    String? subscriptionTier,
    UserPresenceModel? presence,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await FirestoreAuthUtils.ensureAuthenticated(expectedUid: uid);
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (displayName != null) {
        updateData['displayName'] = displayName;
      }
      if (verifiedRealName != null) {
        updateData['verifiedRealName'] = verifiedRealName;
      }
      if (photoURL != null) {
        updateData['photoURL'] = photoURL;
      }
      if (coverPhotoURL != null) {
        updateData['coverPhotoURL'] = coverPhotoURL;
      }
      if (phone != null) {
        updateData['phone'] = phone;
      }
      if (collegeId != null) {
        updateData['collegeId'] = collegeId;
      }
      if (collegeName != null) {
        updateData['collegeName'] = collegeName;
      }
      if (course != null) {
        updateData['course'] = course;
      }
      if (branch != null) {
        updateData['branch'] = branch;
      }
      if (batchYear != null) {
        updateData['batchYear'] = batchYear;
      }
      if (aboutMe != null) {
        updateData['aboutMe'] = aboutMe;
      }
      if (interests != null) {
        updateData['interests'] = interests;
      }
      if (languagesKnown != null) {
        updateData['languagesKnown'] = languagesKnown;
      }
      if (communicationSettings != null) {
        updateData['communicationSettings'] = communicationSettings.toJson();
      }
      if (subscriptionTier != null) {
        updateData['subscriptionTier'] = subscriptionTier;
      }
      if (presence != null) {
        updateData['presence'] = presence.toJson();
      }
      if (metadata != null) {
        updateData['metadata'] = metadata;
      }

      if (displayName != null || verifiedRealName != null) {
        final userDoc = await _firestore.collection(usersCollection).doc(uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final mode = data['displayNameMode'] as String? ??
              DisplayNameConstants.modeRealName;
          if (mode == DisplayNameConstants.modeRealName) {
            final realName = (verifiedRealName ?? displayName)?.trim();
            if (realName != null && realName.isNotEmpty) {
              updateData['publicDisplayName'] = realName;
            }
          }
        }
      }

      await _firestore
          .collection(usersCollection)
          .doc(uid)
          .update(updateData);
      await syncPublicProfile(uid, updateData);
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(
        e,
        collectionPath: usersCollection,
        documentPath: uid,
        action: 'update user profile',
      );
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException(
        message: 'Could not update your profile. Please try again.',
      );
    }
  }

  // Verify email
  Future<void> verifyEmail(String uid) async {
    try {
      await _firestore.collection(usersCollection).doc(uid).update({
        'isEmailVerified': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw FirestoreException(
        message: 'Could not verify email. Please try again.',
      );
    }
  }

  // Verify phone
  Future<void> verifyPhone(String uid, {String? phone}) async {
    try {
      final updateData = <String, dynamic>{
        'isPhoneVerified': true,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (phone != null && phone.isNotEmpty) {
        updateData['phone'] = phone;
      }
      await _firestore.collection(usersCollection).doc(uid).update(updateData);
    } catch (e) {
      throw FirestoreException(
        message: 'Could not verify phone. Please try again.',
      );
    }
  }

  // Delete user document (when user deletes account)
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(usersCollection).doc(uid).delete();
    } catch (e) {
      throw FirestoreException(
        message: 'Could not delete account. Please try again.',
      );
    }
    try {
      // Best-effort: the source-of-truth `users` doc is already gone,
      // which is what account deletion requires. Without this, the
      // public_profiles mirror would keep showing a deleted account in
      // the guide directory / connectable-students list indefinitely.
      await _firestore
          .collection(FirestoreConstants.publicProfilesCollection)
          .doc(uid)
          .delete();
    } catch (_) {}
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      await FirestoreAuthUtils.ensureAuthenticated();
      final doc =
          await _firestore.collection(usersCollection).doc(uid).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(
        e,
        collectionPath: usersCollection,
        documentPath: uid,
        action: 'check user existence',
      );
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException(
        message: 'Could not load your profile. Please try again.',
      );
    }
  }

  // Get user by email (helper function)
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw FirestoreException(
        message: 'Could not find account. Please try again.',
      );
    }
  }
}

class FirestoreException implements Exception {
  final String message;

  FirestoreException({required this.message});

  @override
  String toString() => message;
}

FirestoreException _mapFirestoreError(
  FirebaseException error, {
  required String collectionPath,
  required String documentPath,
  required String action,
}) {
  if (FirestoreErrorUtils.isPermissionDenied(error)) {
    return FirestoreException(
      message: FirestoreErrorUtils.permissionException(
        collectionPath: collectionPath,
        documentPath: documentPath,
      ).message,
    );
  }
  if (FirestoreErrorUtils.isQuotaExceeded(error)) {
    return FirestoreException(message: kFirestoreQuotaUserMessage);
  }
  return FirestoreException(
    message: 'Could not complete this action. Please try again.',
  );
}
