/// Constants for the "Talk to a Verified Student/Alumni" paid consultation
/// feature. Reuses existing auth/verification/chat/call/rating systems —
/// see ConsultationModel, PaymentModel, ConsultationRatingModel.
class ConsultationConstants {
  ConsultationConstants._();

  static const String typeChat = 'chat';
  static const String typeCall = 'call';
  static const String typeVideo = 'video';
  static const List<String> types = [typeChat, typeCall, typeVideo];

  // Consultation lifecycle — see PRODUCT GOAL states in the feature plan.
  static const String statusRequested = 'requested';
  static const String statusPaymentPending = 'payment_pending';
  static const String statusPaid = 'paid';
  static const String statusWaitingForGuide = 'waiting_for_guide';
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusExpired = 'expired';

  static const List<String> terminalStatuses = [
    statusCompleted,
    statusCancelled,
    statusExpired,
  ];

  static const String paymentStatusPending = 'pending';
  static const String paymentStatusSuccess = 'success';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusRefunded = 'refunded';
  static const String paymentStatusCancelled = 'cancelled';

  static const String refundStatusNone = 'none';
  static const String refundStatusPending = 'pending';
  static const String refundStatusRefunded = 'refunded';
  static const String refundStatusFailed = 'failed';

  static const String raterRoleStudent = 'student';
  static const String raterRoleGuide = 'guide';

  static const String currencyInr = 'INR';

  // Platform fee — flat percentage taken off the gross consultation price.
  // Kept as a single source of truth on the client for display estimates
  // only; the Cloud Function backend recomputes and enforces the real
  // split server-side (see functions/src/consultations.js).
  static const double platformFeePercent = 20.0;

  static int estimatedPlatformFeePaise(int grossPaise) =>
      ((grossPaise * platformFeePercent) / 100).round();

  static int estimatedGuideAmountPaise(int grossPaise) =>
      grossPaise - estimatedPlatformFeePaise(grossPaise);

  // Presence heartbeat — see CommunityFirestoreService.updatePresence.
  static const Duration heartbeatInterval = Duration(seconds: 75);
  static const Duration presenceStaleAfter = Duration(seconds: 100);

  static const int maxConsultationRequestsPerHour = 6;
}
