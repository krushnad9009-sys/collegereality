import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/constants/profile_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/user_provider.dart';
import '../../community/providers/community_provider.dart';

/// Quick "Online status" switch on the guide's own profile hub. Flips
/// `presence.availabilityStatus` between available/offline (and the
/// `isOnline` flag) so the guide controls whether students can start an
/// instant paid chat/call. Only rendered for an approved verified guide
/// who has turned guide mode on.
class GuideOnlineToggleCard extends ConsumerStatefulWidget {
  final UserModel user;

  const GuideOnlineToggleCard({required this.user, super.key});

  /// Whether this card renders anything for [user] — an approved verified
  /// guide who has guide mode on. Callers use it to avoid laying out a
  /// leading gap before an empty card.
  static bool isEligible(UserModel user) =>
      VerificationConstants.isApprovedStudentOrAlumni(
        user.verificationBadge,
        user.verificationStatus,
      ) &&
      user.communicationSettings.isGuideAvailable;

  @override
  ConsumerState<GuideOnlineToggleCard> createState() =>
      _GuideOnlineToggleCardState();
}

class _GuideOnlineToggleCardState extends ConsumerState<GuideOnlineToggleCard> {
  bool _busy = false;

  /// Set the instant a toggle is tapped, cleared once the live stream
  /// confirms it. Firestore's local cache resolves `FieldValue
  /// .serverTimestamp()` to `null` until the server ack lands, which would
  /// otherwise make presence read stale for a moment right after switching
  /// ON -- the switch shows this optimistic value instead of the
  /// live-derived one while a write is in flight, so it never depends on
  /// that transient local state.
  bool? _pendingOnline;

  bool get _isEligibleGuide => GuideOnlineToggleCard.isEligible(widget.user);

  Future<void> _setOnline(bool value) async {
    final previous = _pendingOnline;
    setState(() {
      _pendingOnline = value;
      _busy = true;
    });
    try {
      await ref
          .read(communityServiceProvider)
          .setAvailability(widget.user.uid, available: value);
      // currentUserDetailProvider is a one-shot FutureProvider, not a
      // stream -- without this, it keeps serving whatever presence it had
      // cached from before this toggle. That stale copy is exactly what
      // made edit_profile_screen.dart's general "Save Profile" (course,
      // bio, anything) silently overwrite a guide's online status back to
      // whatever it was when that screen last hydrated: it re-populates
      // its local availability field from this same provider, and its
      // save always writes presence back out from that local field. This
      // invalidation is what keeps that screen (and anywhere else reading
      // this provider) from ever re-hydrating a stale value in the first
      // place.
      ref.invalidate(currentUserDetailProvider);
    } catch (_) {
      if (mounted) {
        // Revert to whatever the switch showed before this attempt so the
        // UI never claims a state the write never actually reached.
        setState(() => _pendingOnline = previous);
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Could not update your status. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEligibleGuide) return const SizedBox.shrink();

    final tokens = context.tokens;
    // Straight from the guide's own `users/{uid}` doc (owner-readable,
    // source of truth) rather than the public_profiles mirror other
    // viewers read -- one write, one listener, no dependency on a second
    // sync write landing before this card sees the change.
    final live = ref.watch(userStreamProvider(widget.user.uid));
    final presence = live.valueOrNull?.presence ?? widget.user.presence;

    // This is the guide's OWN toggle, so it reflects their persisted
    // choice directly -- NOT gated by the same freshness check other
    // viewers' "is this guide reachable right now" signal uses
    // (UserPresenceModel.isLiveOnline). That staleness gate exists so a
    // crashed/backgrounded app can't leave other students thinking a
    // guide is reachable forever; it has nothing to do with what this
    // switch itself should show, and gating on it here was the "reverts
    // after ~100s" bug -- a missed/delayed heartbeat tick made the
    // guide's own switch flip off even though they never touched it.
    final liveOnline =
        presence.availabilityStatus == ProfileConstants.availabilityAvailable;

    // Once the live stream confirms our own pending toggle, stop
    // overriding it.
    if (_pendingOnline != null && _pendingOnline == liveOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pendingOnline == liveOnline) {
          setState(() => _pendingOnline = null);
        }
      });
    }

    final online = _pendingOnline ?? liveOnline;

    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: PresenceDot(
          state: online ? PresenceState.online : PresenceState.offline,
          size: 12,
        ),
        title: Text(
          online ? 'Online' : 'Offline',
          style: AppFonts.plusJakarta(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
        subtitle: Text(
          online
              ? 'Students can start an instant chat or call with you now.'
              : 'You\'re hidden from instant chat/call. Turn on to take consultations.',
          style: AppFonts.plusJakarta(
            fontSize: 12,
            color: tokens.textSecondary,
          ),
        ),
        value: online,
        onChanged: _busy ? null : _setOnline,
      ),
    );
  }
}
