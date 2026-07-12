class UserPresenceModel {
  final bool isOnline;
  final DateTime? lastSeenAt;

  const UserPresenceModel({
    this.isOnline = false,
    this.lastSeenAt,
  });

  factory UserPresenceModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPresenceModel();
    return UserPresenceModel(
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenAt: DateTime.tryParse(json['lastSeenAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'isOnline': isOnline,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
      };
}
