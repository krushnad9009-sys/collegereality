import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
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
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Online',
            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.accentColor),
          ),
        ],
      );
    }

    if (!showLastSeen || presence!.lastSeenAt == null) {
      return const SizedBox.shrink();
    }

    return Text(
      'Last seen ${_formatLastSeen(presence!.lastSeenAt!)}',
      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.gray500),
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
