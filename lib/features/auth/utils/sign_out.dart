import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

/// Single sign-out path for the whole app.
///
/// 1. Clears the Firebase session — `AuthNotifier.signOut()` →
///    `AuthService.signOut()` → `FirebaseAuth.instance.signOut()`. If that
///    throws for any reason, `FirebaseAuth.instance.signOut()` is called
///    directly so the session is never left half-open.
/// 2. Resets `authProvider` (done inside the notifier) and invalidates the
///    user-scoped providers so no stale profile survives. The router's
///    `refreshListenable` also re-runs its redirect off `authStateChanges`.
/// 3. `context.go` to the login route.
///
/// Pass a context that is still mounted at call time — never a dismissed
/// bottom-sheet or dialog context.
Future<void> signOutAndRedirect(BuildContext context, WidgetRef ref) async {
  // Capture the router before any await so navigation still works even if
  // `context` is torn down while signing out.
  final router = GoRouter.of(context);

  try {
    await ref.read(authProvider.notifier).signOut();
  } catch (e, st) {
    debugPrint('[signOut] notifier path failed, forcing FirebaseAuth: $e\n$st');
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Already signed out / offline — nothing more to do here.
    }
  }

  ref.invalidate(currentUserDetailProvider);

  router.go(RouteNames.login);
}
