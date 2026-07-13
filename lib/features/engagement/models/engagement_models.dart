import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/engagement_constants.dart';

class UserNotificationModel {
  final String id;
  final String userId;
  final String type;
  final String category;
  final String title;
  final String body;
  final String entityType;
  final String entityId;
  final String actionRoute;
  final bool isRead;
  final String searchText;
  final DateTime createdAt;

  const UserNotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.title,
    this.body = '',
    this.entityType = '',
    this.entityId = '',
    this.actionRoute = '',
    this.isRead = false,
    this.searchText = '',
    required this.createdAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory UserNotificationModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return UserNotificationModel(
      id: docId ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as String? ?? '',
      actionRoute: json['actionRoute'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      searchText: json['searchText'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type,
        'category': category,
        'title': title,
        'body': body,
        'entityType': entityType,
        'entityId': entityId,
        'actionRoute': actionRoute,
        'isRead': isRead,
        'searchText': searchText,
        'createdAt': createdAt.toIso8601String(),
      };

  UserNotificationModel copyWith({
    bool? isRead,
  }) {
    return UserNotificationModel(
      id: id,
      userId: userId,
      type: type,
      category: category,
      title: title,
      body: body,
      entityType: entityType,
      entityId: entityId,
      actionRoute: actionRoute,
      isRead: isRead ?? this.isRead,
      searchText: searchText,
      createdAt: createdAt,
    );
  }
}

class NotificationPreferencesModel {
  final String userId;
  final bool alertsEnabled;
  final bool newReview;
  final bool newAnswer;
  final bool newChatMessage;
  final bool collegeUpdates;
  final bool placementUpdates;
  final bool scholarshipUpdates;
  final bool eventReminders;
  final bool admissionReminders;
  final bool feesChange;
  final bool placementStatsChange;
  final bool scholarshipOpen;
  final bool admissionStart;
  final bool admissionDeadline;
  final bool newEvent;
  final DateTime? lastAlertScanAt;
  final DateTime updatedAt;

  const NotificationPreferencesModel({
    required this.userId,
    this.alertsEnabled = true,
    this.newReview = true,
    this.newAnswer = true,
    this.newChatMessage = true,
    this.collegeUpdates = true,
    this.placementUpdates = true,
    this.scholarshipUpdates = true,
    this.eventReminders = true,
    this.admissionReminders = true,
    this.feesChange = true,
    this.placementStatsChange = true,
    this.scholarshipOpen = true,
    this.admissionStart = true,
    this.admissionDeadline = true,
    this.newEvent = true,
    this.lastAlertScanAt,
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory NotificationPreferencesModel.defaults(String userId) {
    return NotificationPreferencesModel(
      userId: userId,
      updatedAt: DateTime.now(),
    );
  }

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return NotificationPreferencesModel(
      userId: docId ?? json['userId'] as String? ?? '',
      alertsEnabled: json['alertsEnabled'] as bool? ?? true,
      newReview: json['newReview'] as bool? ?? true,
      newAnswer: json['newAnswer'] as bool? ?? true,
      newChatMessage: json['newChatMessage'] as bool? ?? true,
      collegeUpdates: json['collegeUpdates'] as bool? ?? true,
      placementUpdates: json['placementUpdates'] as bool? ?? true,
      scholarshipUpdates: json['scholarshipUpdates'] as bool? ?? true,
      eventReminders: json['eventReminders'] as bool? ?? true,
      admissionReminders: json['admissionReminders'] as bool? ?? true,
      feesChange: json['feesChange'] as bool? ?? true,
      placementStatsChange: json['placementStatsChange'] as bool? ?? true,
      scholarshipOpen: json['scholarshipOpen'] as bool? ?? true,
      admissionStart: json['admissionStart'] as bool? ?? true,
      admissionDeadline: json['admissionDeadline'] as bool? ?? true,
      newEvent: json['newEvent'] as bool? ?? true,
      lastAlertScanAt: json['lastAlertScanAt'] != null
          ? _parseDate(json['lastAlertScanAt'])
          : null,
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'alertsEnabled': alertsEnabled,
        'newReview': newReview,
        'newAnswer': newAnswer,
        'newChatMessage': newChatMessage,
        'collegeUpdates': collegeUpdates,
        'placementUpdates': placementUpdates,
        'scholarshipUpdates': scholarshipUpdates,
        'eventReminders': eventReminders,
        'admissionReminders': admissionReminders,
        'feesChange': feesChange,
        'placementStatsChange': placementStatsChange,
        'scholarshipOpen': scholarshipOpen,
        'admissionStart': admissionStart,
        'admissionDeadline': admissionDeadline,
        'newEvent': newEvent,
        if (lastAlertScanAt != null)
          'lastAlertScanAt': lastAlertScanAt!.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  NotificationPreferencesModel copyWith({
    bool? alertsEnabled,
    bool? newReview,
    bool? newAnswer,
    bool? newChatMessage,
    bool? collegeUpdates,
    bool? placementUpdates,
    bool? scholarshipUpdates,
    bool? eventReminders,
    bool? admissionReminders,
    bool? feesChange,
    bool? placementStatsChange,
    bool? scholarshipOpen,
    bool? admissionStart,
    bool? admissionDeadline,
    bool? newEvent,
    DateTime? lastAlertScanAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreferencesModel(
      userId: userId,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      newReview: newReview ?? this.newReview,
      newAnswer: newAnswer ?? this.newAnswer,
      newChatMessage: newChatMessage ?? this.newChatMessage,
      collegeUpdates: collegeUpdates ?? this.collegeUpdates,
      placementUpdates: placementUpdates ?? this.placementUpdates,
      scholarshipUpdates: scholarshipUpdates ?? this.scholarshipUpdates,
      eventReminders: eventReminders ?? this.eventReminders,
      admissionReminders: admissionReminders ?? this.admissionReminders,
      feesChange: feesChange ?? this.feesChange,
      placementStatsChange: placementStatsChange ?? this.placementStatsChange,
      scholarshipOpen: scholarshipOpen ?? this.scholarshipOpen,
      admissionStart: admissionStart ?? this.admissionStart,
      admissionDeadline: admissionDeadline ?? this.admissionDeadline,
      newEvent: newEvent ?? this.newEvent,
      lastAlertScanAt: lastAlertScanAt ?? this.lastAlertScanAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AdmissionCalendarEventModel {
  final String id;
  final String title;
  final String category;
  final String state;
  final String description;
  final DateTime eventDate;
  final DateTime? deadlineDate;
  final String searchText;
  final bool isActive;
  final DateTime updatedAt;

  const AdmissionCalendarEventModel({
    required this.id,
    required this.title,
    required this.category,
    this.state = '',
    this.description = '',
    required this.eventDate,
    this.deadlineDate,
    this.searchText = '',
    this.isActive = true,
    required this.updatedAt,
  });

  bool get isUpcoming => eventDate.isAfter(DateTime.now());

  bool get isDeadlineSoon {
    final deadline = deadlineDate ?? eventDate;
    final days = deadline.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 14;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory AdmissionCalendarEventModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return AdmissionCalendarEventModel(
      id: docId ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? EngagementConstants.calendarCapRound,
      state: json['state'] as String? ?? '',
      description: json['description'] as String? ?? '',
      eventDate: _parseDate(json['eventDate']),
      deadlineDate: json['deadlineDate'] != null ? _parseDate(json['deadlineDate']) : null,
      searchText: json['searchText'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'state': state,
        'description': description,
        'eventDate': eventDate.toIso8601String(),
        if (deadlineDate != null) 'deadlineDate': deadlineDate!.toIso8601String(),
        'searchText': searchText,
        'isActive': isActive,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class AlertNotificationDraft {
  final String type;
  final String category;
  final String title;
  final String body;
  final String entityType;
  final String entityId;
  final String actionRoute;

  const AlertNotificationDraft({
    required this.type,
    required this.category,
    required this.title,
    this.body = '',
    this.entityType = '',
    this.entityId = '',
    this.actionRoute = '',
  });
}
