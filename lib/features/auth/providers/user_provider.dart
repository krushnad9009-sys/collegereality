import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';
import '../services/firestore_user_service.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

// Firestore user service provider
final firestoreUserServiceProvider = Provider<FirestoreUserService>((ref) {
  return FirestoreUserService();
});

// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestoreUserService = ref.watch(firestoreUserServiceProvider);
  return UserRepositoryImpl(firestoreUserService);
});

// Get user by UID provider
final userByUIDProvider =
    FutureProvider.family<UserModel?, String>((ref, uid) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getUser(uid);
});

// Get user stream provider
final userStreamProvider =
    StreamProvider.family<UserModel?, String>((ref, uid) {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getUserStream(uid);
});

// Current user detail provider (combines auth state with user data)
final currentUserDetailProvider = FutureProvider<UserModel?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);

  if (authState != null) {
    final userRepository = ref.watch(userRepositoryProvider);
    return userRepository.getUser(authState.uid);
  }

  return null;
});

// Note: authStateProvider is imported from auth_provider.dart
// We need to import it in the providers that use it
// This is a forward reference that will be resolved through proper imports

// User creation provider
final createUserProvider =
    FutureProvider.family<void, UserModel>((ref, user) async {
  final userRepository = ref.watch(userRepositoryProvider);
  await userRepository.createUser(user);
});

// Update user profile provider
final updateUserProfileProvider = FutureProvider.family<void, UpdateUserProfileParams>((ref, params) async {
  final userRepository = ref.watch(userRepositoryProvider);
  await userRepository.updateUserProfile(
    uid: params.uid,
    displayName: params.displayName,
    photoURL: params.photoURL,
    phone: params.phone,
    collegeId: params.collegeId,
    collegeName: params.collegeName,
    course: params.course,
    batchYear: params.batchYear,
    metadata: params.metadata,
  );
});

class UpdateUserProfileParams {
  final String uid;
  final String? displayName;
  final String? photoURL;
  final String? phone;
  final String? collegeId;
  final String? collegeName;
  final String? course;
  final int? batchYear;
  final Map<String, dynamic>? metadata;

  UpdateUserProfileParams({
    required this.uid,
    this.displayName,
    this.photoURL,
    this.phone,
    this.collegeId,
    this.collegeName,
    this.course,
    this.batchYear,
    this.metadata,
  });
}
