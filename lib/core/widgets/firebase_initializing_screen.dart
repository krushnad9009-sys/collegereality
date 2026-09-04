import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/firebase_bootstrap.dart';

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
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _attempts = 0;
    if (_timedOut) setState(() => _timedOut = false);
    _timer = Timer.periodic(const Duration(milliseconds: 150), (t) {
      _attempts++;
      if (Firebase.apps.isNotEmpty) {
        t.cancel();
        if (mounted) ref.invalidate(widget.routerProvider);
      } else if (_attempts >= _maxPolls) {
        t.cancel();
        // Don't just stop and leave a spinner forever — surface an
        // explicit, recoverable error boundary instead.
        if (mounted) setState(() => _timedOut = true);
      }
    });
  }

  Future<void> _retry() async {
    FirebaseBootstrap.resetForRetry();
    unawaited(FirebaseBootstrap.ensureInitialized());
    if (mounted) _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _timedOut ? _errorBoundary() : _spinner(),
      ),
    );
  }

  Widget _spinner() => const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );

  Widget _errorBoundary() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.black45),
          const SizedBox(height: 16),
          const Text(
            "Couldn't finish starting up.\nCheck your connection and try again.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
