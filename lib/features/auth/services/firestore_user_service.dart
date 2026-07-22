import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/display_name_constants.dart';
import '../models/user_model.dart';
import '../../communication/models/guide_stats_model.dart';
import '../../community/models/user_presence_model.dart';

class FirestoreUserService {
  static const String usersCollection = 'users';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update user document
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore.collection(usersCollection).doc(user.uid).set(
            user.toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw FirestoreException(
        message: 'Failed to create/update user: $e',
      );
    }
  }

  // Get user by UID
  Future<UserModel?> getUserByUID(String uid) async {
    try {
      final doc =
          await _firestore.collection(usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw FirestoreException(
        message: 'Failed to fetch user: $e',
      );
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
        message: 'Failed to stream user: $e',
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
    } catch (e) {
      throw FirestoreException(
        message: 'Failed to update user profile: $e',
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
        message: 'Failed to verify email: $e',
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
        message: 'Failed to verify phone: $e',
      );
    }
  }

  // Delete user document (when user deletes account)
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(usersCollection).doc(uid).delete();
    } catch (e) {
      throw FirestoreException(
        message: 'Failed to delete user: $e',
      );
    }
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      final doc =
          await _firestore.collection(usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw FirestoreException(
        message: 'Failed to check user existence: $e',
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
        message: 'Failed to fetch user by email: $e',
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
