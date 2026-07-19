import 'dart:async';

import 'package:flutter/foundation.dart';

/// Blocks Firestore reads while quota is exhausted and schedules exponential retry.
class FirestoreQuotaGuard {
  FirestoreQuotaGuard._();

  static final FirestoreQuotaGuard instance = FirestoreQuotaGuard._();

  static const List<int> _retryDelaysSeconds = [30, 60, 120];

  bool _blocked = false;
  int _retryAttempt = 0;
  DateTime? _retryAfter;
  Timer? _retryTimer;
  Future<void> Function()? _probe;

  final List<VoidCallback> _recoveryListeners = [];
  final List<VoidCallback> _blockedListeners = [];

  bool get isBlocked => _blocked;

  DateTime? get retryAfter => _retryAfter;

  /// True while quota cooldown is active — skip new Firestore requests.
  bool shouldBlockRequest() {
    if (!_blocked) return false;
    if (_retryAfter == null) return true;
    return DateTime.now().isBefore(_retryAfter!);
  }

  void setProbe(Future<void> Function() probe) {
    _probe = probe;
  }

  void addRecoveryListener(VoidCallback listener) {
    _recoveryListeners.add(listener);
  }

  void addBlockedListener(VoidCallback listener) {
    _blockedListeners.add(listener);
  }

  void markQuotaExceeded() {
    _blocked = true;
    final delayIndex = _retryAttempt.clamp(0, _retryDelaysSeconds.length - 1);
    final delaySeconds = _retryDelaysSeconds[delayIndex];
    _retryAttempt = (_retryAttempt + 1).clamp(0, _retryDelaysSeconds.length);

    _retryAfter = DateTime.now().add(Duration(seconds: delaySeconds));
    _scheduleRetry(delaySeconds);

    for (final listener in List<VoidCallback>.from(_blockedListeners)) {
      listener();
    }

    if (kDebugMode) {
      debugPrint(
        'Firestore quota exceeded — blocking requests for ${delaySeconds}s',
      );
    }
  }

  void markRecovered() {
    if (!_blocked && _retryAttempt == 0) return;
    _blocked = false;
    _retryAttempt = 0;
    _retryAfter = null;
    _retryTimer?.cancel();
    _retryTimer = null;

    for (final listener in List<VoidCallback>.from(_recoveryListeners)) {
      listener();
    }

    if (kDebugMode) {
      debugPrint('Firestore quota recovered — resuming requests');
    }
  }

  void _scheduleRetry(int delaySeconds) {
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (!_blocked) return;
      _retryAfter = null;
      await _runProbe();
    });
  }

  Future<void> _runProbe() async {
    final probe = _probe;
    if (probe == null) return;
    try {
      await probe();
    } catch (_) {
      // Probe failure re-blocks via markQuotaExceeded in repository.
    }
  }

  /// Manual retry from UI — only runs if cooldown elapsed.
  Future<void> retryNowIfAllowed() async {
    if (shouldBlockRequest()) return;
    await _runProbe();
  }
}
