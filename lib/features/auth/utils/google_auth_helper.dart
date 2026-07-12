import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../repositories/user_repository.dart';

Future<void> syncGoogleUserToFirestore(WidgetRef ref, User firebaseUser) async {
  final userRepository = ref.read(userRepositoryProvider);
  final exists = await userRepository.userExists(firebaseUser.uid);

  if (!exists) {
    await userRepository.createUser(
      createUserModelFromFirebaseUser(firebaseUser),
    );
    return;
  }

  await userRepository.updateUserProfile(
    uid: firebaseUser.uid,
    displayName: firebaseUser.displayName,
    photoURL: firebaseUser.photoURL,
  );
  ref.invalidate(currentUserDetailProvider);
}
