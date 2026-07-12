import '../../../core/constants/profile_constants.dart';

class UserPresenceModel {
  final bool isOnline;
  final DateTime? lastSeenAt;
  final String availabilityStatus;

  const UserPresenceModel({
    this.isOnline = false,
    this.lastSeenAt,
    this.availabilityStatus = ProfileConstants.availabilityOffline,
  });

  factory UserPresenceModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPresenceModel();
    return UserPresenceModel(
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenAt: DateTime.tryParse(json['lastSeenAt']?.toString() ?? ''),
      availabilityStatus: json['availabilityStatus'] as String? ??
          ProfileConstants.availabilityOffline,
    );
  }

  Map<String, dynamic> toJson() => {
        'isOnline': isOnline,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
        'availabilityStatus': availabilityStatus,
      };

  UserPresenceModel copyWith({
    bool? isOnline,
    DateTime? lastSeenAt,
    String? availabilityStatus,
  }) {
    return UserPresenceModel(
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
    );
  }
}
