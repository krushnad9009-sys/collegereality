import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../config/router/route_names.dart';

/// Back / forward navigation that can't get stuck or stack duplicates.
///
/// * [popOrGo] -- a bare `context.pop()` THROWS ("There is nothing to pop")
///   when the screen is the only page on the stack, which is the case for
///   every screen reached with `context.go()` (drawer links, notification
///   taps, redirects, deep links). The back arrow then silently did
///   nothing and the user stayed on the same screen. This pops when there
///   is something to pop and otherwise goes to a sensible parent.
///
/// * [pushOnce] -- ignores a push to the route that is already on top, or
///   the same route pushed again within [_debounce] (a fast double tap).
///   Stacked duplicates made "back" reveal an identical copy of the screen.
extension SafeNavigation on BuildContext {
  void popOrGo([String fallback = RouteNames.home]) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }

  Future<T?> pushOnce<T extends Object?>(String location, {Object? extra}) {
    final router = GoRouter.of(this);
    if (PushGuard.shouldSkip(
      target: location,
      current: router.routerDelegate.currentConfiguration.uri.toString(),
      now: DateTime.now(),
    )) {
      return Future<T?>.value();
    }
    return router.push<T>(location, extra: extra);
  }
}

/// Pure duplicate-push decision (unit-tested).
class PushGuard {
  PushGuard._();

  static const Duration _debounce = Duration(milliseconds: 600);
  static String? _lastTarget;
  static DateTime? _lastAt;

  static bool shouldSkip({
    required String target,
    required String current,
    required DateTime now,
  }) {
    if (_sameLocation(target, current)) return true;
    final last = _lastAt;
    if (_lastTarget == target &&
        last != null &&
        now.difference(last) < _debounce) {
      return true;
    }
    _lastTarget = target;
    _lastAt = now;
    return false;
  }

  static bool _sameLocation(String a, String b) {
    String norm(String s) {
      final uri = Uri.tryParse(s);
      if (uri == null) return s;
      final path = uri.path.length > 1 && uri.path.endsWith('/')
          ? uri.path.substring(0, uri.path.length - 1)
          : uri.path;
      return uri.hasQuery ? '$path?${uri.query}' : path;
    }

    return norm(a) == norm(b);
  }

  @visibleForTesting
  static void reset() {
    _lastTarget = null;
    _lastAt = null;
  }
}
