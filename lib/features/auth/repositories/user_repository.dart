import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../../communication/models/guide_stats_model.dart';
import '../../community/models/user_presence_model.dart';
import '../services/firestore_user_service.dart';

abstract class UserRepository {
  Future<void> createUser(UserModel user);
  Future<UserModel?> getUser(String uid);
  Stream<UserModel?> getUserStream(String uid);
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
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
  });
  Future<void> verifyEmail(String uid);
  Future<void> verifyPhone(String uid, {String? phone});
  Future<void> deleteUser(String uid);
  Future<bool> userExists(String uid);
  Future<UserModel?> getUserByEmail(String email);
}

class UserRepositoryImpl implements UserRepository {
  final FirestoreUserService _firestoreUserService;

  UserRepositoryImpl(this._firestoreUserService);

  @override
  Future<void> createUser(UserModel user) async {
    await _firestoreUserService.createOrUpdateUser(user);
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    return _firestoreUserService.getUserByUID(uid);
  }

  @override
  Stream<UserModel?> getUserStream(String uid) {
    return _firestoreUserService.getUserStream(uid);
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
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
    await _firestoreUserService.updateUserProfile(
      uid: uid,
      displayName: displayName,
      photoURL: photoURL,
      coverPhotoURL: coverPhotoURL,
      phone: phone,
      collegeId: collegeId,
      collegeName: collegeName,
      course: course,
      branch: branch,
      batchYear: batchYear,
      aboutMe: aboutMe,
      interests: interests,
      languagesKnown: languagesKnown,
      communicationSettings: communicationSettings,
      subscriptionTier: subscriptionTier,
      presence: presence,
      metadata: metadata,
    );
  }

  @override
  Future<void> verifyEmail(String uid) async {
    await _firestoreUserService.verifyEmail(uid);
  }

  @override
  Future<void> verifyPhone(String uid, {String? phone}) async {
    await _firestoreUserService.verifyPhone(uid, phone: phone);
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _firestoreUserService.deleteUser(uid);
  }

  @override
  Future<bool> userExists(String uid) async {
    return _firestoreUserService.userExists(uid);
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    return _firestoreUserService.getUserByEmail(email);
  }
}

// Helper function to create UserModel from Firebase User
UserModel createUserModelFromFirebaseUser(User firebaseUser) {
  return UserModel(
    uid: firebaseUser.uid,
    email: firebaseUser.email ?? '',
    displayName: firebaseUser.displayName,
    photoURL: firebaseUser.photoURL,
    isEmailVerified: firebaseUser.emailVerified,
    createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
