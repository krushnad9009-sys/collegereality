import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

export 'package:flutter_animate/flutter_animate.dart';

/// True when the platform "reduce motion" / "remove animations" accessibility
/// setting is on. Entrance animations render their settled state instead.
bool get reduceMotion => WidgetsBinding
    .instance
    .platformDispatcher
    .accessibilityFeatures
    .disableAnimations;

/// Standard entrance animation used across the app: a soft fade combined with
/// a short upward slide (and, optionally, a subtle scale-up).
///
/// The `flutter_animate` wrapper stays mounted for the widget's lifetime and
/// holds the child at its settled state once done, so a parent `setState`
/// never re-triggers it and the child's own [State] is never remounted.
/// Honors [reduceMotion] (renders the plain child, no animation).
///
/// Use [delayMs] to stagger a list of cards/buttons, e.g.
/// `AppReveal(delayMs: index * 70, child: ...)`.
class AppReveal extends StatelessWidget {
  final Widget child;
  final int delayMs;
  final int durationMs;

  /// Vertical travel as a fraction of the child's own height.
  final double slideFrom;

  /// Add a gentle scale-up (nice for hero elements / success states).
  final bool scale;

  const AppReveal({
    required this.child,
    this.delayMs = 0,
    this.durationMs = 420,
    this.slideFrom = 0.06,
    this.scale = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;

    final delay = delayMs.ms;
    final duration = durationMs.ms;

    Animate animation = child.animate().fadeIn(
      delay: delay,
      duration: duration,
      curve: Curves.easeOutCubic,
    );

    if (slideFrom != 0) {
      animation = animation.slideY(
        begin: slideFrom,
        end: 0,
        delay: delay,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
    }
    if (scale) {
      animation = animation.scaleXY(
        begin: 0.94,
        end: 1,
        delay: delay,
        duration: duration,
        curve: Curves.easeOutBack,
      );
    }
    return animation;
  }
}

/// Staggers [children] with an incremental [AppReveal] delay and returns the
/// wrapped list — drop-in for a `Column`/`ListView` `children:`.
List<Widget> staggered(
  List<Widget> children, {
  int startDelayMs = 0,
  int stepMs = 70,
}) {
  return [
    for (var i = 0; i < children.length; i++)
      AppReveal(delayMs: startDelayMs + i * stepMs, child: children[i]),
  ];
}
