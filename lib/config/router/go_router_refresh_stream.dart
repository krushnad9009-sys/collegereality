import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] when a stream emits so redirects re-run.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      if (!_ready.isCompleted) _ready.complete();
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;
  final Completer<void> _ready = Completer<void>();

  /// Completes once the wrapped stream (Firebase auth state) has emitted at
  /// least once. On Flutter Web a hard refresh reaches the router's very
  /// first `redirect` evaluation before Firebase Auth has finished
  /// restoring the persisted session, so `currentUser` briefly reads null
  /// even for an actually-logged-in user — bouncing them to /login for a
  /// flash before self-correcting. Awaiting this (with a bounded timeout)
  /// before that first decision avoids the false bounce.
  Future<void> get firstEvent => _ready.future;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
