import 'package:flutter/material.dart';

import '../../../config/theme/app_fonts.dart';
import '../../../core/constants/consultation_constants.dart';
import '../../../core/constants/profile_constants.dart';
import '../../../core/widgets/status_badge.dart';
import '../../community/models/user_presence_model.dart';

/// Online & Available / Online but Busy / Offline, with an "Active N min
/// ago" fallback — derives from `lastSeenAt` staleness
/// (UserPresenceModel.isFresh), never from a screen simply being open.
///
/// Visually matches the shared [PresencePill]/[PresenceDot] family: a
/// tinted pill with a small colored dot and a bold label.
class AvailabilityBadge extends StatelessWidget {
  final UserPresenceModel presence;
  final bool compact;

  const AvailabilityBadge({
    required this.presence,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isFresh = presence.isFresh(ConsultationConstants.presenceStaleAfter);
    final (label, color) = _statusFor(isFresh);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 7,
            height: compact ? 6 : 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.plusJakarta(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _statusFor(bool isFresh) {
    if (!isFresh) {
      final lastSeen = presence.lastSeenAt;
      final label = lastSeen == null
          ? 'Offline'
          : 'Active ${_relativeMinutes(lastSeen)}';
      return (label, PresenceState.offline.color);
    }
    if (presence.isBusyNow) {
      return ('Online but Busy', PresenceState.busy.color);
    }
    if (presence.availabilityStatus == ProfileConstants.availabilityAvailable) {
      return ('Online & Available', PresenceState.online.color);
    }
    // Fresh heartbeat but the user hasn't marked themselves available.
    return ('Online', PresenceState.offline.color);
  }

  static String _relativeMinutes(DateTime lastSeenAt) {
    final diff = DateTime.now().difference(lastSeenAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
