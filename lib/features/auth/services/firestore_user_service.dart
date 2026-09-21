import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/display_name_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/utils/firestore_auth_utils.dart';
import '../../../core/utils/firestore_error_utils.dart';
import '../models/user_model.dart';
import '../../onboarding/services/onboarding_location_resolver.dart'
    show kLocationNotProvided;
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
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, docId: doc.id);
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
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, docId: doc.id);
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
      ..remove('phone')
      // `verifiedRealName` is the user's legal name captured during student
      // verification. It is NOT part of any public model (readers use
      // `displayName` / `publicDisplayName`, which already respect the
      // user's anonymous-vs-real-name choice), so it must never reach the
      // authenticated-readable mirror — leaving it here would deanonymise
      // every user who picked an alias.
      ..remove('verifiedRealName')
      // Opaque free-form bag — never render it publicly; keep it on the
      // owner-only `users` doc.
      ..remove('metadata')
      // Browsing-behaviour tags used only to personalise the owner's own
      // Home feed — no reason for any other user to be able to read them.
      ..remove('preferredState')
      ..remove('preferredCategory')
      ..remove('categoryInteractionCounts');
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

  // Live "is this user currently verified" signal for CROSS-USER display
  // (review cards, etc. -- anywhere showing another user's badge, not just
  // their own profile). Reads the PII-free `public_profiles` mirror, which
  // any authenticated user may read; Firestore rules restrict the full
  // `users` doc to the owner or staff. Deliberately reads the two raw
  // fields directly rather than UserModel.fromJson(doc.data()) -- a
  // public_profiles doc never carries `email`, which UserModel.fromJson
  // requires non-nullably, so parsing it as a full UserModel would throw.
  Stream<String> watchPublicVerificationBadge(String uid) {
    if (uid.isEmpty) return Stream.value(VerificationConstants.badgeNone);
    return _firestore
        .collection(FirestoreConstants.publicProfilesCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) return VerificationConstants.badgeNone;
      final badge = data['verificationBadge'] as String?;
      final status = data['verificationStatus'] as String?;
      if (badge == null) return VerificationConstants.badgeNone;
      return VerificationConstants.isApprovedStudentOrAlumni(badge, status)
          ? badge
          : VerificationConstants.badgeNone;
    });
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
          return UserModel.fromJson(doc.data()!, docId: doc.id);
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

  // Finish the single post-login "Permissions & Terms" step in ONE atomic
  // update, so the account can never end up with terms accepted but the
  // step still looking incomplete (or vice versa) if the write is cut short.
  //
  // [recordTerms] / [recordPermissions] say which halves are still owed: an
  // account that accepted Terms under the old two-screen flow must not have
  // its original `termsAcceptedAt` overwritten by a later re-acceptance.
  //
  // Permissions are always recorded as "completed" whatever the user chose
  // (grant, deny, switch off) -- this flag means the step was shown and
  // answered, not that every permission was granted. [state]/[city] are the
  // reverse-geocoded values, or the 'Not Provided' sentinel.
  Future<void> completeOnboarding(
    String uid, {
    required bool recordTerms,
    required bool recordPermissions,
    String state = kLocationNotProvided,
    String city = kLocationNotProvided,
    bool locationGranted = false,
  }) async {
    if (!recordTerms && !recordPermissions) return;
    try {
      await FirestoreAuthUtils.ensureAuthenticated(expectedUid: uid);
      final now = DateTime.now().toIso8601String();
      await _firestore.collection(usersCollection).doc(uid).update({
        if (recordTerms) ...{
          'hasAcceptedTerms': true,
          'termsAcceptedAt': now,
        },
        if (recordPermissions) ...{
          'hasCompletedPermissionsOnboarding': true,
          'permissionsOnboardingCompletedAt': now,
          'state': state,
          'city': city,
          'locationGranted': locationGranted,
          // Seed the Home "Colleges Near You" preference from the detected
          // state. Never overwrite with the 'Not Provided' sentinel.
          if (locationGranted &&
              state.trim().isNotEmpty &&
              state != kLocationNotProvided)
            'preferredState': state,
        },
        'updatedAt': now,
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(
        e,
        collectionPath: usersCollection,
        documentPath: uid,
        action: 'complete onboarding',
      );
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException(
        message: 'Could not save your choices. Please try again.',
      );
    }
  }

  // Record one search/click on a stream (Engineering, Arts, ...) and refresh
  // the derived favourite. [category] MUST come from
  // CollegeConstants.collegeCategories: it is used as a Firestore field-path
  // segment, so it must never contain '.' or other path characters.
  // [preferredCategory] is the argmax the caller computed from the counts.
  // Deliberately leaves `updatedAt` alone -- this is behavioural telemetry,
  // not a profile edit.
  Future<void> recordCategoryInteraction(
    String uid, {
    required String category,
    required String preferredCategory,
  }) async {
    try {
      await FirestoreAuthUtils.ensureAuthenticated(expectedUid: uid);
      await _firestore.collection(usersCollection).doc(uid).update({
        'categoryInteractionCounts.$category': FieldValue.increment(1),
        'preferredCategory': preferredCategory,
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(
        e,
        collectionPath: usersCollection,
        documentPath: uid,
        action: 'record category interaction',
      );
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException(
        message: 'Could not save your preferences. Please try again.',
      );
    }
  }

  // Persist the state the user explicitly picked (e.g. in the search filter).
  Future<void> updatePreferredState(String uid, String state) async {
    try {
      await FirestoreAuthUtils.ensureAuthenticated(expectedUid: uid);
      await _firestore.collection(usersCollection).doc(uid).update({
        'preferredState': state,
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(
        e,
        collectionPath: usersCollection,
        documentPath: uid,
        action: 'save preferred state',
      );
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException(
        message: 'Could not save your preferences. Please try again.',
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
        final doc = querySnapshot.docs.first;
        return UserModel.fromJson(doc.data(), docId: doc.id);
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
