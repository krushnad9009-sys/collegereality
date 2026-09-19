import 'package:college_reality_india/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

class _FakeAuthentication extends Fake implements GoogleSignInAuthentication {
  _FakeAuthentication({this.idToken, this.accessToken});
  @override
  final String? idToken;
  @override
  final String? accessToken;
}

class _FakeAccount extends Fake implements GoogleSignInAccount {
  _FakeAccount(this._auth);
  final GoogleSignInAuthentication _auth;
  @override
  Future<GoogleSignInAuthentication> get authentication async => _auth;
}

class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  _FakeGoogleSignIn({this.account, this.error});
  final GoogleSignInAccount? account;
  final Object? error;
  int signOutCalls = 0;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (error != null) throw error!;
    return account;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOutCalls++;
    return null;
  }
}

void main() {
  test('signs in via signInWithCredential with the Google tokens', () async {
    final auth = MockFirebaseAuth();
    final service = AuthService(
      firebaseAuth: auth,
      googleSignIn: _FakeGoogleSignIn(
        account: _FakeAccount(
          _FakeAuthentication(idToken: 'id-token', accessToken: 'access-token'),
        ),
      ),
    );

    final credential = await service.signInWithGoogle();

    expect(credential, isNotNull);
    expect(auth.currentUser, isNotNull);
  });

  test('web-style accessToken-only result still signs in', () async {
    final auth = MockFirebaseAuth();
    final service = AuthService(
      firebaseAuth: auth,
      googleSignIn: _FakeGoogleSignIn(
        account: _FakeAccount(_FakeAuthentication(accessToken: 'access-token')),
      ),
    );

    expect(await service.signInWithGoogle(), isNotNull);
  });

  test('null account (user cancelled) returns null', () async {
    final service = AuthService(
      firebaseAuth: MockFirebaseAuth(),
      googleSignIn: _FakeGoogleSignIn(),
    );

    expect(await service.signInWithGoogle(), isNull);
  });

  test('web popup_closed (String and PlatformException) is a cancel', () async {
    for (final error in <Object>[
      'popup_closed',
      PlatformException(code: 'popup_closed'),
      PlatformException(code: GoogleSignIn.kSignInCanceledError),
    ]) {
      final service = AuthService(
        firebaseAuth: MockFirebaseAuth(),
        googleSignIn: _FakeGoogleSignIn(error: error),
      );
      expect(await service.signInWithGoogle(), isNull, reason: '$error');
    }
  });

  test('other Google errors propagate', () async {
    final service = AuthService(
      firebaseAuth: MockFirebaseAuth(),
      googleSignIn: _FakeGoogleSignIn(
        error: PlatformException(code: 'network_error'),
      ),
    );

    expect(service.signInWithGoogle(), throwsA(isA<PlatformException>()));
  });

  test('no tokens at all is rejected as invalid-credential', () async {
    final service = AuthService(
      firebaseAuth: MockFirebaseAuth(),
      googleSignIn: _FakeGoogleSignIn(
        account: _FakeAccount(_FakeAuthentication()),
      ),
    );

    expect(
      service.signInWithGoogle(),
      throwsA(
        isA<FirebaseAuthException>()
            .having((e) => e.code, 'code', 'invalid-credential'),
      ),
    );
  });

  test('signOut also signs out of Google (including on web)', () async {
    final google = _FakeGoogleSignIn();
    final service = AuthService(
      firebaseAuth: MockFirebaseAuth(),
      googleSignIn: google,
    );

    await service.signOut();

    expect(google.signOutCalls, 1);
  });
}
