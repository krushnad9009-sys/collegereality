import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/display_name_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/utils/public_display_name_utils.dart';
import '../models/user_model.dart';
import '../utils/validation_util.dart';

class DisplayNameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _displayNames =>
      _firestore.collection(FirestoreConstants.displayNamesCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreConstants.usersCollection);

  Future<bool> isCustomDisplayNameAvailable(
    String customName, {
    String? excludeUid,
  }) async {
    final key = normalizeCustomDisplayNameKey(customName);
    if (key.isEmpty) return false;

    final doc = await _displayNames.doc(key).get();
    if (!doc.exists) return true;

    final ownerUid = doc.data()?['uid'] as String?;
    return ownerUid == excludeUid;
  }

  Future<void> updateDisplayNameSettings({
    required UserModel user,
    required String displayNameMode,
    String? customDisplayName,
    bool isInitialSetup = false,
  }) async {
    if (!DisplayNameConstants.allModes.contains(displayNameMode)) {
      throw DisplayNameException(message: 'Invalid display name mode.');
    }

    if (displayNameMode == DisplayNameConstants.modeAnonymousVerifiedStudent &&
        user.verificationBadge != VerificationConstants.badgeVerifiedStudent) {
      throw DisplayNameException(
        message: 'Anonymous Verified Student requires student verification.',
      );
    }

    if (displayNameMode == DisplayNameConstants.modeAnonymousVerifiedAlumni &&
        user.verificationBadge != VerificationConstants.badgeVerifiedAlumni) {
      throw DisplayNameException(
        message: 'Anonymous Verified Alumni requires alumni verification.',
      );
    }

    String? trimmedCustom;
    if (displayNameMode == DisplayNameConstants.modeCustom) {
      trimmedCustom = customDisplayName?.trim();
      final validationError = ValidationUtil.validateCustomDisplayName(
        trimmedCustom,
      );
      if (validationError != null) {
        throw DisplayNameException(message: validationError);
      }

      final available = await isCustomDisplayNameAvailable(
        trimmedCustom!,
        excludeUid: user.uid,
      );
      if (!available) {
        throw DisplayNameException(
          message: 'This display name is already taken. Please choose another.',
        );
      }
    }

    final modeChanged = displayNameMode != user.displayNameMode ||
        (displayNameMode == DisplayNameConstants.modeCustom &&
            trimmedCustom != user.customDisplayName);

    if (!isInitialSetup && modeChanged) {
      if (!canChangeDisplayName(user.displayNameChangedAt)) {
        final daysLeft = daysUntilDisplayNameChange(user.displayNameChangedAt);
        throw DisplayNameException(
          message:
              'Display name can only be changed once every ${DisplayNameConstants.changeCooldownDays} days. Try again in $daysLeft day(s).',
        );
      }
    }

    final verifiedRealName = user.verifiedRealName ?? user.displayName;
    if (displayNameMode == DisplayNameConstants.modeRealName &&
        (verifiedRealName == null || verifiedRealName.trim().isEmpty)) {
      throw DisplayNameException(
        message: 'Please add your verified real name before using Real Name mode.',
      );
    }

    final publicName = computePublicDisplayName(
      userId: user.uid,
      verifiedRealName: verifiedRealName,
      displayNameMode: displayNameMode,
      customDisplayName: trimmedCustom,
      verificationBadge: user.verificationBadge,
    );

    final now = DateTime.now();
    final previousCustomKey = user.customDisplayName == null
        ? null
        : normalizeCustomDisplayNameKey(user.customDisplayName!);
    final nextCustomKey = trimmedCustom == null
        ? null
        : normalizeCustomDisplayNameKey(trimmedCustom);

    await _firestore.runTransaction((transaction) async {
      final userRef = _users.doc(user.uid);
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw DisplayNameException(message: 'User profile not found.');
      }

      if (previousCustomKey != null &&
          previousCustomKey.isNotEmpty &&
          previousCustomKey != nextCustomKey) {
        final oldRef = _displayNames.doc(previousCustomKey);
        final oldSnap = await transaction.get(oldRef);
        if (oldSnap.exists && oldSnap.data()?['uid'] == user.uid) {
          transaction.delete(oldRef);
        }
      }

      if (nextCustomKey != null &&
          nextCustomKey.isNotEmpty &&
          nextCustomKey != previousCustomKey) {
        final newRef = _displayNames.doc(nextCustomKey);
        final newSnap = await transaction.get(newRef);
        if (newSnap.exists && newSnap.data()?['uid'] != user.uid) {
          throw DisplayNameException(
            message: 'This display name is already taken. Please choose another.',
          );
        }
        transaction.set(newRef, {
          'uid': user.uid,
          'displayName': trimmedCustom,
          'updatedAt': now.toIso8601String(),
        });
      }

      transaction.update(userRef, {
        'publicDisplayName': publicName,
        'displayNameMode': displayNameMode,
        'customDisplayName': trimmedCustom,
        'displayNameSetupComplete': true,
        if (!isInitialSetup && modeChanged)
          'displayNameChangedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
    });
  }

  Future<void> setVerifiedRealName({
    required String uid,
    required String realName,
  }) async {
    final validationError = ValidationUtil.validateDisplayName(realName);
    if (validationError != null) {
      throw DisplayNameException(message: validationError);
    }

    final trimmed = realName.trim();
    await _users.doc(uid).set(
      {
        'displayName': trimmed,
        'verifiedRealName': trimmed,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }
}

class DisplayNameException implements Exception {
  final String message;

  DisplayNameException({required this.message});

  @override
  String toString() => message;
}
