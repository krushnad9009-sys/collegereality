import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Auth operations used by [AuthNotifier] and screens.
abstract class AuthServiceApi {
  User? get currentUser;
  Stream<User?> get authStateChanges;

  Future<UserCredential> signUpWithEmail(String email, String password);
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential?> signInWithGoogle();
  Future<void> signOut();
  Future<void> updateUserProfile({String? displayName, String? photoURL});
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<bool> reloadUser();
}

class AuthService implements AuthServiceApi {
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              clientId: kIsWeb ? _webClientId : null,
            );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  static const String _webClientId =
      '244446156099-bb6c7e0dabe7a5efbf0bf6.apps.googleusercontent.com';

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return _firebaseAuth.signInWithPopup(provider);
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      if (!kIsWeb) _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    await currentUser?.updateDisplayName(displayName);
    await currentUser?.updatePhotoURL(photoURL);
    await currentUser?.reload();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'You must be logged in to verify your email.',
      );
    }
    if (user.emailVerified) {
      throw FirebaseAuthException(
        code: 'email-already-verified',
        message: 'Your email is already verified.',
      );
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message: 'Could not send verification email. Check your connection.',
      );
    }
  }

  @override
  Future<bool> reloadUser() async {
    await currentUser?.reload();
    return currentUser?.emailVerified ?? false;
  }
}
