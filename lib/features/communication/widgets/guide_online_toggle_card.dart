import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
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
  /// otherwise make `presence.isLiveOnline` read false for a moment right
  /// after switching ON (the exact "flips back to Offline" bug) -- the
  /// switch shows this optimistic value instead of the live-derived one
  /// while a write is in flight, so it never depends on that transient
  /// local state.
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
    // Live presence from the public mirror; fall back to the doc we were
    // built with until the stream produces a value.
    final live = ref.watch(presenceProvider(widget.user.uid));
    final presence = live.valueOrNull ?? widget.user.presence;
    final liveOnline = presence.isLiveOnline;

    // Once the live stream confirms our own pending toggle, stop
    // overriding it -- from then on this card tracks real presence again
    // (e.g. the heartbeat later going stale still turns the switch off).
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
