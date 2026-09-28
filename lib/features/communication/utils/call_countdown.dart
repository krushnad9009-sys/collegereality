/// Seconds already used on a call that connected at [startedAt], clamped
/// to `[0, maxSeconds]`.
///
/// Measured from the session's server-stored `startedAt`, not from when
/// this screen first saw the call -- otherwise leaving and reopening the
/// call screen (or an app restart) would restart the free-trial clock.
/// Clamped because `startedAt` was written by the other participant's
/// device, whose clock may be slightly off from this one.
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
