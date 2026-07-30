import 'package:college_reality_india/core/services/auth_service.dart';
import 'package:college_reality_india/core/services/preferences_service.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/auth/providers/auth_provider.dart';
import 'package:college_reality_india/features/auth/providers/user_provider.dart';
import 'package:college_reality_india/features/auth/repositories/user_repository.dart';
import 'package:college_reality_india/features/communication/models/guide_stats_model.dart';
import 'package:college_reality_india/features/community/models/user_presence_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory preferences for widget/integration tests.
class FakePreferencesService extends PreferencesService {
  bool rememberMe = false;
  String? savedEmail;

  @override
  Future<bool> getRememberMe() async => rememberMe;

  @override
  Future<void> setRememberMe(bool value) async {
    rememberMe = value;
  }

  @override
  Future<String?> getSavedEmail() async => savedEmail;

  @override
  Future<void> saveEmail(String email) async {
    savedEmail = email;
  }

  @override
  Future<void> clearSavedEmail() async {
    savedEmail = null;
  }
}

/// In-memory user store so auth screens never hit Firestore in tests.
class FakeUserRepository implements UserRepository {
  final Map<String, UserModel> users = {};
  int createCalls = 0;

  @override
  Future<void> createUser(UserModel user) async {
    createCalls++;
    users[user.uid] = user;
  }

  @override
  Future<UserModel?> getUser(String uid) async => users[uid];

  @override
  Stream<UserModel?> getUserStream(String uid) =>
      Stream.value(users[uid]);

  @override
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
    final existing = users[uid];
    if (existing == null) return;
    users[uid] = existing.copyWith(
      displayName: displayName ?? existing.displayName,
      verifiedRealName: verifiedRealName ?? existing.verifiedRealName,
      photoURL: photoURL ?? existing.photoURL,
      phone: phone ?? existing.phone,
      collegeId: collegeId ?? existing.collegeId,
      collegeName: collegeName ?? existing.collegeName,
      course: course ?? existing.course,
      batchYear: batchYear ?? existing.batchYear,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> verifyEmail(String uid) async {}

  @override
  Future<void> verifyPhone(String uid, {String? phone}) async {}

  @override
  Future<void> deleteUser(String uid) async {
    users.remove(uid);
  }

  @override
  Future<bool> userExists(String uid) async => users.containsKey(uid);

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    for (final user in users.values) {
      if (user.email == email) return user;
    }
    return null;
  }
}

/// Firebase-free auth backed by [MockFirebaseAuth].
class FakeAuthService implements AuthServiceApi {
  FakeAuthService({MockUser? initialUser})
      : _auth = MockFirebaseAuth(
          signedIn: initialUser != null,
          mockUser: initialUser,
        );

  final MockFirebaseAuth _auth;

  int signInEmailCalls = 0;
  int signUpEmailCalls = 0;
  int signInGoogleCalls = 0;
  String? lastEmail;
  String? lastPassword;
  bool googleCancelled = false;
  FirebaseAuthException? emailSignInError;
  FirebaseAuthException? emailSignUpError;

  MockFirebaseAuth get mockAuth => _auth;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    signInEmailCalls++;
    lastEmail = email;
    lastPassword = password;
    if (emailSignInError != null) throw emailSignInError!;
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    signUpEmailCalls++;
    lastEmail = email;
    lastPassword = password;
    if (emailSignUpError != null) throw emailSignUpError!;
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    signInGoogleCalls++;
    if (googleCancelled) return null;
    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(accessToken: 'a', idToken: 'b'),
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<bool> reloadUser() async => currentUser?.emailVerified ?? false;
}

UserModel testUserModel({
  String uid = 'test-uid',
  String email = 'student@example.com',
  bool phoneVerified = false,
  bool emailVerified = true,
}) {
  final now = DateTime(2026, 1, 1);
  return UserModel(
    uid: uid,
    email: email,
    displayName: 'Test Student',
    verifiedRealName: 'Test Student',
    publicDisplayName: 'Test Student',
    isEmailVerified: emailVerified,
    isPhoneVerified: phoneVerified,
    displayNameSetupComplete: true,
    createdAt: now,
    updatedAt: now,
  );
}

List<Override> testAuthOverrides({
  FakeAuthService? authService,
  FakePreferencesService? preferences,
  FakeUserRepository? userRepository,
  UserModel? userDetail,
  User? firebaseUser,
}) {
  final fakeAuth = authService ?? FakeAuthService();
  final prefs = preferences ?? FakePreferencesService();
  final users = userRepository ?? FakeUserRepository();
  if (userDetail != null) {
    users.users[userDetail.uid] = userDetail;
  }
  return [
    preferencesServiceProvider.overrideWithValue(prefs),
    authServiceProvider.overrideWithValue(fakeAuth),
    authStateProvider.overrideWith((ref) => fakeAuth.authStateChanges),
    userRepositoryProvider.overrideWithValue(users),
    if (firebaseUser != null)
      currentUserProvider.overrideWith((ref) => firebaseUser),
    currentUserDetailProvider.overrideWith((ref) async {
      if (userDetail != null) return userDetail;
      final authUser = fakeAuth.currentUser;
      if (authUser == null) return null;
      return users.users[authUser.uid] ??
          testUserModel(uid: authUser.uid, email: authUser.email ?? '');
    }),
  ];
}

Future<void> pumpRouterApp(
  WidgetTester tester, {
  required String initialLocation,
  required List<GoRoute> routes,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: routes,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

Future<void> pumpScreen(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: child),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}
