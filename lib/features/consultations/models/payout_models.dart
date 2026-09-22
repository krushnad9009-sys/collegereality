/// UPI/bank details captured at the moment a withdrawal was requested --
/// a snapshot, not a live reference, so a later change to the guide's
/// saved payout method never rewrites the record of where a past request
/// was actually meant to be paid out.
class PayoutMethodSnapshot {
  final String type; // 'upi' | 'bank'
  final String? upiId;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? accountHolderName;

  const PayoutMethodSnapshot({
    required this.type,
    this.upiId,
    this.bankAccountNumber,
    this.bankIfsc,
    this.accountHolderName,
  });

  String get summary {
    if (type == 'upi' && (upiId?.isNotEmpty ?? false)) return upiId!;
    if (bankAccountNumber != null && bankAccountNumber!.isNotEmpty) {
      final acct = bankAccountNumber!;
      final last4 = acct.length > 4 ? acct.substring(acct.length - 4) : acct;
      return 'Bank ····$last4${bankIfsc != null && bankIfsc!.isNotEmpty ? ' ($bankIfsc)' : ''}';
    }
    return 'Not linked';
  }

  factory PayoutMethodSnapshot.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PayoutMethodSnapshot(type: 'upi');
    return PayoutMethodSnapshot(
      type: json['type'] as String? ?? 'upi',
      upiId: json['upiId'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankIfsc: json['bankIfsc'] as String?,
      accountHolderName: json['accountHolderName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (upiId != null) 'upiId': upiId,
        if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
        if (bankIfsc != null) 'bankIfsc': bankIfsc,
        if (accountHolderName != null) 'accountHolderName': accountHolderName,
      };
}

class PayoutRequestConstants {
  PayoutRequestConstants._();
  static const String statusPending = 'pending';
  static const String statusPaid = 'paid';
  static const String statusRejected = 'rejected';
}

/// A guide's withdrawal request against their `guide_earnings` balance --
/// see firestore.rules `match /payout_requests/{requestId}` for the write
/// constraints (guide creates pending-only; only admin decides it).
class PayoutRequestModel {
  final String id;
  final String guideId;
  final String guideName;
  final int amountPaise;
  final PayoutMethodSnapshot payoutMethod;
  final String status;
  final DateTime requestedAt;
  final DateTime? decidedAt;
  final String? decidedBy;
  final String? transactionId;
  final String? rejectionReason;

  const PayoutRequestModel({
    required this.id,
    required this.guideId,
    required this.guideName,
    required this.amountPaise,
    required this.payoutMethod,
    required this.status,
    required this.requestedAt,
    this.decidedAt,
    this.decidedBy,
    this.transactionId,
    this.rejectionReason,
  });

  static DateTime? _parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory PayoutRequestModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return PayoutRequestModel(
      id: docId ?? json['id'] as String? ?? '',
      guideId: json['guideId'] as String? ?? '',
      guideName: json['guideName'] as String? ?? 'Guide',
      amountPaise: (json['amountPaise'] as num?)?.toInt() ?? 0,
      payoutMethod: PayoutMethodSnapshot.fromJson(
        json['payoutMethod'] as Map<String, dynamic>?,
      ),
      status: json['status'] as String? ?? PayoutRequestConstants.statusPending,
      requestedAt: _parseDate(json['requestedAt']) ?? DateTime.now(),
      decidedAt: _parseDate(json['decidedAt']),
      decidedBy: json['decidedBy'] as String?,
      transactionId: json['transactionId'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'guideId': guideId,
        'guideName': guideName,
        'amountPaise': amountPaise,
        'payoutMethod': payoutMethod.toJson(),
        'status': status,
        'requestedAt': requestedAt.toIso8601String(),
        'decidedAt': decidedAt?.toIso8601String(),
        'decidedBy': decidedBy,
        'transactionId': transactionId,
        'rejectionReason': rejectionReason,
      };
}

/// One row of the backend-authoritative `guide_earnings/{guideId}/entries`
/// ledger -- written only by trusted Cloud Function logic (see
/// firestore.rules and functions/src/{finalizePayment,triggers}.js), never
/// by this client. `status`: 'pending' (paid by student, session not yet
/// completed) -> 'payable' (session completed, now owed to the guide) or
/// 'void' (refunded/cancelled).
class GuideEarningsEntry {
  final String id;
  final String guideId;
  final String consultationId;
  final int amountPaise;
  final String status;
  final DateTime createdAt;

  const GuideEarningsEntry({
    required this.id,
    required this.guideId,
    required this.consultationId,
    required this.amountPaise,
    required this.status,
    required this.createdAt,
  });

  factory GuideEarningsEntry.fromJson(
    Map<String, dynamic> json, {
    String? docId,
    required String guideId,
  }) {
    final createdAtRaw = json['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else if (createdAtRaw != null && createdAtRaw is! String) {
      // Cloud Functions write this with admin.firestore.Timestamp, which
      // the client SDK deserializes to a Dart `Timestamp` -- duck-type via
      // `.toDate()` rather than importing cloud_firestore into this
      // otherwise-plain model file.
      try {
        createdAt = (createdAtRaw as dynamic).toDate() as DateTime;
      } catch (_) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }
    return GuideEarningsEntry(
      id: docId ?? json['consultationId'] as String? ?? '',
      guideId: guideId,
      consultationId: json['consultationId'] as String? ?? '',
      amountPaise: (json['amountPaise'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      createdAt: createdAt,
    );
  }
}
