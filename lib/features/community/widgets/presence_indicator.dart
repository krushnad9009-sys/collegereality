import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/user_presence_model.dart';

class PresenceIndicator extends StatelessWidget {
  final UserPresenceModel? presence;
  final bool showLastSeen;

  const PresenceIndicator({
    this.presence,
    this.showLastSeen = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (presence == null) return const SizedBox.shrink();

    if (presence!.isOnline) {
      return const PresencePill(state: PresenceState.online);
    }

    if (!showLastSeen || presence!.lastSeenAt == null) {
      return const SizedBox.shrink();
    }

    final tokens = context.tokens;
    return Text(
      'Last seen ${_formatLastSeen(presence!.lastSeenAt!)}',
      style: AppFonts.plusJakarta(fontSize: 11, color: tokens.textTertiary),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
