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
  // Nobody answered before the ring timeout (set by the server sweeper).
  static const callStatusMissed = 'missed';

  static const reportStatusOpen = 'open';
  static const reportStatusReviewed = 'reviewed';
  static const reportStatusActionTaken = 'action_taken';

  /// Direct guide calls are a free trial: this many seconds, once per day
  /// per guide (IST calendar day), after which the user must book a paid
  /// consultation. Enforced server-side by `startFreeTrialCall`
  /// (functions/src/freeTrialCallLogic.js FREE_TRIAL_SECONDS) -- keep the
  /// two in sync; this copy only drives the countdown UI.
  static const int freeTrialCallSeconds = 120;

  static const int spamReportThreshold = 3;
}
