import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown for the brief window (typically well under a second) where
/// `Firebase.initializeApp()` is still genuinely completing in the
/// background after `FirebaseBootstrap`'s own bootstrap timeout gave up
/// waiting for it, so `main()` could still reach `runApp()` on a slow
/// connection. Router providers must never call `FirebaseAuth.instance`/
/// `Firebase.app()` before the JS SDK has actually registered the default
/// app -- doing so hits a real bug in firebase_core_web where the
/// "app not found" error path does an unconditional unsafe cast, crashing
/// with a JS-interop TypeError instead of a normal catchable exception.
///
/// This screen polls `Firebase.apps` (itself safe to call -- it never
/// hits that buggy path) from its own widget lifecycle and calls
/// `ref.invalidate(routerProvider)` once ready, so the caller's router
/// provider rebuilds for real. Invalidating from here (an active,
/// mounted widget's own WidgetRef) is what actually notifies
/// MaterialApp.router's watcher -- calling `ref.invalidateSelf()` from a
/// Timer captured inside the router provider's own build closure does
/// not reliably do so.
class FirebaseInitializingScreen extends ConsumerStatefulWidget {
  const FirebaseInitializingScreen({required this.routerProvider, super.key});

  final ProviderOrFamily routerProvider;

  @override
  ConsumerState<FirebaseInitializingScreen> createState() =>
      _FirebaseInitializingScreenState();
}

class _FirebaseInitializingScreenState
    extends ConsumerState<FirebaseInitializingScreen> {
  Timer? _timer;
  static const _maxPolls = 60; // ~9s at 150ms
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (t) {
      _attempts++;
      if (Firebase.apps.isNotEmpty) {
        t.cancel();
        if (mounted) ref.invalidate(widget.routerProvider);
      } else if (_attempts >= _maxPolls) {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
