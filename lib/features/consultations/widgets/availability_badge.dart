import 'package:flutter/material.dart';

import '../../../config/theme/app_fonts.dart';
import '../../../core/constants/consultation_constants.dart';
import '../../../core/constants/profile_constants.dart';
import '../../community/models/user_presence_model.dart';

/// 🟢 Online & Available / 🟡 Online but Busy / ⚪ Offline, with an
/// "Active N min ago" fallback — derives from `lastSeenAt` staleness
/// (UserPresenceModel.isFresh), never from a screen simply being open.
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
    final (emoji, label, color) = _statusFor(isFresh);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: TextStyle(fontSize: compact ? 10 : 12)),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppFonts.plusJakarta(
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  (String, String, Color) _statusFor(bool isFresh) {
    if (!isFresh) {
      final lastSeen = presence.lastSeenAt;
      final label = lastSeen == null
          ? 'Offline'
          : 'Active ${_relativeMinutes(lastSeen)}';
      return ('⚪', label, Colors.grey);
    }
    if (presence.isBusyNow) {
      return ('🟡', 'Online but Busy', const Color(0xFFB8860B));
    }
    if (presence.availabilityStatus == ProfileConstants.availabilityAvailable) {
      return ('🟢', 'Online & Available', const Color(0xFF12A150));
    }
    // Fresh heartbeat but the user hasn't marked themselves available.
    return ('⚪', 'Online', Colors.grey);
  }

  static String _relativeMinutes(DateTime lastSeenAt) {
    final diff = DateTime.now().difference(lastSeenAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
