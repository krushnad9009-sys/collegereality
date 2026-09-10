import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thrown when the caller must re-authenticate before their account can be
/// deleted (the `requestAccountDeletion` function requires a recently
/// minted ID token — same protection as Firebase's own `user.delete()`).
class ReauthRequiredException implements Exception {
  final String message;
  const ReauthRequiredException(this.message);
  @override
  String toString() => message;
}

/// Calls the trusted `requestAccountDeletion` Cloud Function, which erases
/// the caller's own data, anonymises retained content (reviews, ratings,
/// answers), keeps financial records, and finally deletes the Firebase
/// Auth user. The client just needs to sign out afterwards.
class AccountDeletionService {
  AccountDeletionService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  static void _log(String message) {
    if (kDebugMode) debugPrint('[AccountDeletionService] $message');
  }

  /// Returns normally once the account has been deleted server-side.
  /// Throws [ReauthRequiredException] if a fresh sign-in is needed, or a
  /// generic [Exception] on any other failure (the caller should tell the
  /// user to retry).
  Future<void> deleteMyAccount() async {
    try {
      final callable = _functions.httpsCallable(
        'requestAccountDeletion',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );
      final res = await callable.call<Map<String, dynamic>>({'confirm': true});
      final data = Map<String, dynamic>.from(res.data as Map);
      _log('done hadErrors=${data['hadErrors']}');
    } on FirebaseFunctionsException catch (e) {
      _log('FAILED code=${e.code} details=${e.details}');
      final reason = e.details is Map ? (e.details as Map)['reason'] : null;
      if (e.code == 'failed-precondition' || reason == 'requires-recent-login') {
        throw ReauthRequiredException(
          e.message ??
              'For your security, sign out and sign back in, then delete '
                  'your account.',
        );
      }
      rethrow;
    }
  }
}

final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService();
});
