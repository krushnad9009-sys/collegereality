class CommunicationConstants {
  CommunicationConstants._();

  static const List<String> supportedLanguages = [
    'English',
    'Hindi',
    'Marathi',
    'Gujarati',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Bengali',
    'Punjabi',
    'Urdu',
    'Odia',
    'Assamese',
  ];

  static const subscriptionFree = 'free';
  static const subscriptionBronze = 'bronze';
  static const subscriptionSilver = 'silver';
  static const subscriptionGold = 'gold';

  static const callTypeVoice = 'voice';
  static const callTypeVideo = 'video';

  static const callStatusRequested = 'requested';
  static const callStatusAccepted = 'accepted';
  static const callStatusActive = 'active';
  static const callStatusEnded = 'ended';
  static const callStatusRejected = 'rejected';
  static const callStatusEmergencyEnded = 'emergency_ended';

  static const reportStatusOpen = 'open';
  static const reportStatusReviewed = 'reviewed';
  static const reportStatusActionTaken = 'action_taken';

  /// Max call duration in seconds per subscription tier and call type.
  static int maxDurationSeconds({
    required String tier,
    required String callType,
  }) {
    final limits = _durationLimits[tier] ?? _durationLimits[subscriptionFree]!;
    return callType == callTypeVideo
        ? limits['video'] ?? 0
        : limits['voice'] ?? 300;
  }

  static const Map<String, Map<String, int>> _durationLimits = {
    subscriptionFree: {'voice': 300, 'video': 0},
    subscriptionBronze: {'voice': 900, 'video': 300},
    subscriptionSilver: {'voice': 1800, 'video': 900},
    subscriptionGold: {'voice': 3600, 'video': 1800},
  };

  static const int maxCallRequestsPerHour = 10;
  static const int spamReportThreshold = 3;
}
