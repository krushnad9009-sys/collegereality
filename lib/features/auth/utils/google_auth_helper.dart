import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/display_name_constants.dart';
import '../providers/user_provider.dart';
import '../repositories/user_repository.dart';

Future<void> syncGoogleUserToFirestore(WidgetRef ref, User firebaseUser) async {
  final userRepository = ref.read(userRepositoryProvider);
  final exists = await userRepository.userExists(firebaseUser.uid);

  if (!exists) {
    final realName = firebaseUser.displayName?.trim();
    await userRepository.createUser(
      createUserModelFromFirebaseUser(firebaseUser).copyWith(
        verifiedRealName: realName,
        displayNameSetupComplete: false,
        displayNameMode: DisplayNameConstants.modeRealName,
      ),
    );
    return;
  }

  await userRepository.updateUserProfile(
    uid: firebaseUser.uid,
    displayName: firebaseUser.displayName,
    verifiedRealName: firebaseUser.displayName?.trim(),
    photoURL: firebaseUser.photoURL,
  );
  ref.invalidate(currentUserDetailProvider);
}
