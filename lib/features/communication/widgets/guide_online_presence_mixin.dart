import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/profile_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/user_provider.dart';
import '../../community/providers/community_provider.dart';

/// Shared state/logic behind every "I'm online / offline" guide toggle in
/// the app (the Profile hub card and the compact Home header bar) --
/// extracted so the write path, optimistic UI, and error handling only
/// have to be gotten right once. See GuideOnlineToggleCard for the history
/// of bugs this specific sequence fixes (heartbeat-gated staleness, a
/// stale currentUserDetailProvider cache getting written back out by an
/// unrelated profile save, and FieldValue.serverTimestamp()'s pending-write
/// null).
mixin GuideOnlinePresenceLogic<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool busy = false;

  /// Set the instant a toggle is tapped, cleared once the live stream
  /// confirms it -- see [resolveOnline].
  bool? pendingOnline;

  /// The guide whose presence this widget toggles/displays.
  UserModel get presenceUser;

  Future<void> setGuideOnline(bool value) async {
    final previous = pendingOnline;
    setState(() {
      pendingOnline = value;
      busy = true;
    });
    try {
      await ref
          .read(communityServiceProvider)
          .setAvailability(presenceUser.uid, available: value);
      // currentUserDetailProvider is a one-shot FutureProvider, not a
      // stream -- without this it keeps serving whatever presence it had
      // cached from before this toggle, which is what let an unrelated
      // profile save elsewhere silently overwrite a guide's online status.
      ref.invalidate(currentUserDetailProvider);
    } catch (_) {
      if (mounted) {
        // Revert to whatever the switch showed before this attempt so the
        // UI never claims a state the write never actually reached.
        setState(() => pendingOnline = previous);
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Could not update your status. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Call from `build()`. Returns whether the toggle should currently show
  /// "online" -- the pending optimistic value while a write is in flight,
  /// otherwise the guide's own persisted `availabilityStatus`, read
  /// straight from their own `users/{uid}` doc (not the public_profiles
  /// mirror, and NOT gated by heartbeat freshness -- see
  /// GuideOnlineToggleCard for why this differs from `isLiveOnline`, the
  /// signal other viewers use for this same guide).
  bool resolveOnline() {
    final live = ref.watch(userStreamProvider(presenceUser.uid));
    final presence = live.valueOrNull?.presence ?? presenceUser.presence;
    final liveOnline =
        presence.availabilityStatus == ProfileConstants.availabilityAvailable;

    if (pendingOnline != null && pendingOnline == liveOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && pendingOnline == liveOnline) {
          setState(() => pendingOnline = null);
        }
      });
    }

    return pendingOnline ?? liveOnline;
  }
}
