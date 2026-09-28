import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/user_presence_model.dart';

/// "Online" pill / "Last seen …" line for another user. Feed it from
/// `presenceProvider(uid)` (a live `public_profiles` snapshot stream).
///
/// Stateful because a user whose app was force-quit produces NO further
/// snapshots -- their doc just silently goes stale. The periodic rebuild
/// re-checks [UserPresenceModel.isActiveNow] (and refreshes "5m ago") so
/// they flip to "Last seen" on their own instead of looking online forever.
class PresenceIndicator extends StatefulWidget {
  final UserPresenceModel? presence;
  final bool showLastSeen;

  const PresenceIndicator({
    this.presence,
    this.showLastSeen = true,
    super.key,
  });

  @override
  State<PresenceIndicator> createState() => _PresenceIndicatorState();
}

class _PresenceIndicatorState extends State<PresenceIndicator> {
  static const _recheckEvery = Duration(seconds: 30);
  Timer? _recheck;

  @override
  void initState() {
    super.initState();
    _recheck = Timer.periodic(_recheckEvery, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _recheck?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presence = widget.presence;
    if (presence == null) return const SizedBox.shrink();

    if (presence.isActiveNow) {
      return const PresencePill(state: PresenceState.online);
    }

    if (!widget.showLastSeen || presence.lastSeenAt == null) {
      return const SizedBox.shrink();
    }

    final tokens = context.tokens;
    return Text(
      'Last seen ${_formatLastSeen(presence.lastSeenAt!)}',
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
