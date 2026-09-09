import '../../../core/constants/consultation_constants.dart';
import '../../../core/constants/profile_constants.dart';

class UserPresenceModel {
  final bool isOnline;
  final DateTime? lastSeenAt;
  final String availabilityStatus;
  // Set while the user is in an active paid consultation — drives the
  // "🟡 Online but Busy" state independent of `availabilityStatus`, which
  // reflects the user's own manual toggle.
  final DateTime? busyUntil;

  const UserPresenceModel({
    this.isOnline = false,
    this.lastSeenAt,
    this.availabilityStatus = ProfileConstants.availabilityOffline,
    this.busyUntil,
  });

  /// Derives live status from `lastSeenAt` staleness rather than trusting
  /// the stored `isOnline` flag alone — a killed/crashed app has no chance
  /// to write `isOnline: false`, so staleness is the real signal.
  bool isFresh(Duration staleAfter) {
    if (lastSeenAt == null) return false;
    return DateTime.now().difference(lastSeenAt!) < staleAfter;
  }

  bool get isBusyNow =>
      busyUntil != null && busyUntil!.isAfter(DateTime.now());

  /// The single "is this guide reachable right now" signal used by the
  /// online dot on guide lists/profiles and by the instant-consultation
  /// payment gate: the guide flipped their availability toggle ON **and**
  /// their heartbeat is fresh (a force-quit app goes offline on its own
  /// once `lastSeenAt` goes stale). Mirrored server-side in
  /// `functions/src/consultations.js`.
  bool get isLiveOnline =>
      availabilityStatus == ProfileConstants.availabilityAvailable &&
      isFresh(ConsultationConstants.presenceStaleAfter);

  factory UserPresenceModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPresenceModel();
    return UserPresenceModel(
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenAt: DateTime.tryParse(json['lastSeenAt']?.toString() ?? ''),
      availabilityStatus: json['availabilityStatus'] as String? ??
          ProfileConstants.availabilityOffline,
      busyUntil: DateTime.tryParse(json['busyUntil']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'isOnline': isOnline,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
        'availabilityStatus': availabilityStatus,
        'busyUntil': busyUntil?.toIso8601String(),
      };

  UserPresenceModel copyWith({
    bool? isOnline,
    DateTime? lastSeenAt,
    String? availabilityStatus,
    DateTime? busyUntil,
  }) {
    return UserPresenceModel(
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      busyUntil: busyUntil ?? this.busyUntil,
    );
  }
}
