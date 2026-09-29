/// Seconds already used on a call that connected at [startedAt], clamped
/// to `[0, maxSeconds]`.
///
/// Callers pass the moment THIS device saw the call connect -- not the
/// session's `startedAt`, which the other phone wrote with its own clock
/// (a clock a few minutes behind ended calls the instant they connected).
/// The server enforces the real limit on its own clock.
int callElapsedSeconds({
  required DateTime? startedAt,
  required DateTime now,
  required int maxSeconds,
}) {
  if (startedAt == null) return 0;
  final elapsed = now.difference(startedAt).inSeconds;
  return elapsed.clamp(0, maxSeconds);
}

/// Seconds left before the call must auto-disconnect.
int callRemainingSeconds({
  required int elapsedSeconds,
  required int maxSeconds,
}) =>
    (maxSeconds - elapsedSeconds).clamp(0, maxSeconds);
