import 'package:flutter/material.dart';

import '../../../core/constants/profile_constants.dart';
import '../../../core/widgets/status_badge.dart';

/// Availability indicator for student/guide profiles — restyled onto the
/// shared [PresencePill]/[PresenceDot] visual family used for presence
/// everywhere else in the app (community, guide cards).
class AvailabilityChip extends StatelessWidget {
  final String status;

  const AvailabilityChip({required this.status, super.key});

  PresenceState get _state {
    switch (status) {
      case ProfileConstants.availabilityAvailable:
        return PresenceState.online;
      case ProfileConstants.availabilityBusy:
        return PresenceState.busy;
      default:
        return PresenceState.offline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PresencePill(
      state: _state,
      labelOverride: ProfileConstants.availabilityLabel(status),
    );
  }
}
