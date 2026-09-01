import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';
import '../../features/admin/utils/admin_permissions.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/user_provider.dart';

void _log(String message) {
  if (kDebugMode) debugPrint('[SuperAdminAuth] $message');
}

/// Debug-only visibility into the super-admin authorization decision --
/// exactly the chain that silently broke once already (a users/{uid}
/// document with a field of the wrong type made getUser() throw, which
/// this provider's normal control flow turns into "not admin" with no
/// visible error). Never logs secrets/tokens; uid and email are not
/// secret and are exactly what's needed to diagnose "why am I denied".
final isSuperAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    _log('DENIED -- no authenticated Firebase user');
    return false;
  }

  _log(
    'CHECK uid=${user.uid} email=${user.email ?? "(none)"} '
    'firebaseProjectId=${DefaultFirebaseOptions.currentPlatform.projectId} '
    'firestorePath=users/${user.uid}',
  );

  try {
    // Explicit timeout, not just the try/catch below: a Firestore .get()
    // that hangs (rather than throwing -- e.g. a stuck connection on web
    // after a hard refresh) would otherwise never resolve this Future at
    // all, which every caller of this provider (the router's redirect
    // included) then waits on indefinitely.
    final userDetail = await ref
        .watch(userRepositoryProvider)
        .getUser(user.uid)
        .timeout(const Duration(seconds: 8));
    final userType = userDetail?.userType;
    final result = AdminPermissions.isSuperAdmin(userType);
    _log(
      'RESULT uid=${user.uid} userType=${userType ?? "(user doc not found)"} '
      'isSuperAdmin=$result',
    );
    return result;
  } catch (e, st) {
    // A failure here (e.g. a malformed field on the users/{uid} document)
    // must never surface as a silent, unexplained "Access Denied" -- log
    // the real exception so it's diagnosable from the browser console
    // without needing separate backend access.
    _log('FAILED uid=${user.uid} type=${e.runtimeType} message=$e');
    if (kDebugMode) {
      debugPrintStack(stackTrace: st, label: '[SuperAdminAuth] getUser');
    }
    return false;
  }
});
