import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/display_name_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/utils/firestore_auth_utils.dart';
import '../../../core/utils/public_display_name_utils.dart';
import '../models/user_model.dart';
import '../utils/validation_util.dart';
import 'display_name_diagnostics.dart';

class DisplayNameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _displayNames =>
      _firestore.collection(FirestoreConstants.displayNamesCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreConstants.usersCollection);

  String _usersPath(String uid) =>
      '${FirestoreConstants.usersCollection}/$uid';

  String _displayNamePath(String key) =>
      '${FirestoreConstants.displayNamesCollection}/$key';

  Future<bool> isCustomDisplayNameAvailable(
    String customName, {
    String? excludeUid,
  }) async {
    final authUser = await FirestoreAuthUtils.ensureAuthenticated(
      expectedUid: excludeUid,
    );

    final key = normalizeCustomDisplayNameKey(customName);
    if (key.isEmpty) return false;

    final path = _displayNamePath(key);
    DisplayNameDiagnostics.logStart(
      operation: 'isCustomDisplayNameAvailable.get',
      firestorePath: path,
      userModelUid: excludeUid,
    );
    debugPrint('[DisplayName] authUid=${authUser.uid}');

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
    final authUser = await FirestoreAuthUtils.ensureAuthenticated(
      expectedUid: user.uid,
    );
    final usersPath = _usersPath(user.uid);

    DisplayNameDiagnostics.logStart(
      operation: 'updateDisplayNameSettings',
      firestorePath: usersPath,
      userModelUid: user.uid,
    );
    debugPrint('[DisplayName] mode=$displayNameMode isInitialSetup=$isInitialSetup');
    debugPrint('[DisplayName] authUid=${authUser.uid}');

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

    var verifiedRealName = user.verifiedRealName ?? user.displayName;
    if ((verifiedRealName == null || verifiedRealName.trim().isEmpty) &&
        isInitialSetup) {
      final emailLocal = user.email.split('@').first.trim();
      if (emailLocal.isNotEmpty) {
        verifiedRealName = emailLocal;
      }
    }

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

    await _ensureUserProfile(user);

    final userRef = _users.doc(user.uid);
    final userSnap = await userRef.get();
    if (!userSnap.exists) {
      throw DisplayNameException(
        message: 'User profile not found. Please try again.',
      );
    }

    if (nextCustomKey != null && nextCustomKey.isNotEmpty) {
      final displayPath = _displayNamePath(nextCustomKey);
      DisplayNameDiagnostics.logStart(
        operation: 'preWrite.displayNameCheck',
        firestorePath: displayPath,
        userModelUid: user.uid,
      );
      final existing = await _displayNames.doc(nextCustomKey).get();
      if (existing.exists && existing.data()?['uid'] != user.uid) {
        throw DisplayNameException(
          message:
              'This display name is already taken. Please choose another.',
        );
      }
    }

    DisplayNameDiagnostics.logStart(
      operation: 'writeBatch',
      firestorePath: usersPath +
          (nextCustomKey != null ? ' + ${_displayNamePath(nextCustomKey)}' : ''),
      userModelUid: user.uid,
    );

    final batch = _firestore.batch();

    if (previousCustomKey != null &&
        previousCustomKey.isNotEmpty &&
        previousCustomKey != nextCustomKey) {
      final oldRef = _displayNames.doc(previousCustomKey);
      final oldSnap = await oldRef.get();
      if (oldSnap.exists && oldSnap.data()?['uid'] == user.uid) {
        batch.delete(oldRef);
      }
    }

    if (nextCustomKey != null &&
        nextCustomKey.isNotEmpty &&
        nextCustomKey != previousCustomKey) {
      final newRef = _displayNames.doc(nextCustomKey);
      final newSnap = await newRef.get();
      if (newSnap.exists && newSnap.data()?['uid'] != user.uid) {
        throw DisplayNameException(
          message:
              'This display name is already taken. Please choose another.',
        );
      }
      if (!newSnap.exists) {
        batch.set(newRef, {
          'uid': user.uid,
          'displayName': trimmedCustom,
          'updatedAt': now.toIso8601String(),
        });
      }
    }

    final updateData = <String, dynamic>{
      'publicDisplayName': publicName,
      'displayNameMode': displayNameMode,
      'displayNameSetupComplete': true,
      if (!isInitialSetup && modeChanged)
        'displayNameChangedAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    if (trimmedCustom != null) {
      updateData['customDisplayName'] = trimmedCustom;
    } else if (previousCustomKey != null) {
      updateData['customDisplayName'] = FieldValue.delete();
    }

    if (isInitialSetup &&
        displayNameMode == DisplayNameConstants.modeRealName &&
        verifiedRealName != null &&
        verifiedRealName.trim().isNotEmpty) {
      final existingVerified = userSnap.data()?['verifiedRealName'] as String?;
      if (existingVerified == null || existingVerified.trim().isEmpty) {
        updateData['verifiedRealName'] = verifiedRealName.trim();
        updateData['displayName'] = verifiedRealName.trim();
      }
    }

    batch.update(userRef, updateData);
    await batch.commit();

    debugPrint('[DisplayName] updateDisplayNameSettings succeeded for $usersPath');
  }

  Future<void> setVerifiedRealName({
    required String uid,
    required String realName,
  }) async {
    final authUser = await FirestoreAuthUtils.ensureAuthenticated(
      expectedUid: uid,
    );
    final path = _usersPath(uid);

    DisplayNameDiagnostics.logStart(
      operation: 'setVerifiedRealName',
      firestorePath: path,
      userModelUid: uid,
    );
    debugPrint('[DisplayName] authUid=${authUser.uid}');

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

  Future<void> _ensureUserProfile(UserModel user) async {
    final path = _usersPath(user.uid);
    DisplayNameDiagnostics.logStart(
      operation: '_ensureUserProfile',
      firestorePath: path,
      userModelUid: user.uid,
    );

    final userRef = _users.doc(user.uid);
    final snap = await userRef.get();
    if (snap.exists) return;

    debugPrint('[DisplayName] creating missing user doc at $path');
    await userRef.set(
      {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'verifiedRealName': user.verifiedRealName,
        'displayNameSetupComplete': false,
        'displayNameMode': user.displayNameMode,
        'userType': user.userType,
        'createdAt': user.createdAt.toIso8601String(),
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
