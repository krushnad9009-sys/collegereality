import '../../../core/constants/consultation_constants.dart';

/// Client-side read-only view of a `payments/{id}` doc. Every status
/// transition is written by trusted backend logic only (Cloud Functions,
/// Admin SDK) — see functions/src/consultations.js. The client never
/// creates or updates this doc directly (firestore.rules: `allow write: if
/// false`); `createConsultationOrder` (a Cloud Function) is what creates it.
class PaymentModel {
  final String id;
  final String consultationId;
  final String studentId;
  final String guideId;
  final int grossAmountPaise;
  final int platformFeePaise;
  final int guideAmountPaise;
  final String currency;
  final String gateway;
  final String? gatewayOrderId;
  final String? gatewayPaymentId;
  final String status; // ConsultationConstants.paymentStatus*
  final DateTime createdAt;
  final DateTime? verifiedAt;

  const PaymentModel({
    required this.id,
    required this.consultationId,
    required this.studentId,
    required this.guideId,
    required this.grossAmountPaise,
    this.platformFeePaise = 0,
    this.guideAmountPaise = 0,
    this.currency = ConsultationConstants.currencyInr,
    this.gateway = 'razorpay',
    this.gatewayOrderId,
    this.gatewayPaymentId,
    required this.status,
    required this.createdAt,
    this.verifiedAt,
  });

  bool get isSuccessful => status == ConsultationConstants.paymentStatusSuccess;

  static DateTime? _parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory PaymentModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return PaymentModel(
      id: docId ?? json['id'] as String? ?? '',
      consultationId: json['consultationId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      guideId: json['guideId'] as String? ?? '',
      grossAmountPaise: (json['grossAmountPaise'] as num?)?.toInt() ?? 0,
      platformFeePaise: (json['platformFeePaise'] as num?)?.toInt() ?? 0,
      guideAmountPaise: (json['guideAmountPaise'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? ConsultationConstants.currencyInr,
      gateway: json['gateway'] as String? ?? 'razorpay',
      gatewayOrderId: json['gatewayOrderId'] as String?,
      gatewayPaymentId: json['gatewayPaymentId'] as String?,
      status: json['status'] as String? ?? ConsultationConstants.paymentStatusPending,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      verifiedAt: _parseDate(json['verifiedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'consultationId': consultationId,
        'studentId': studentId,
        'guideId': guideId,
        'grossAmountPaise': grossAmountPaise,
        'platformFeePaise': platformFeePaise,
        'guideAmountPaise': guideAmountPaise,
        'currency': currency,
        'gateway': gateway,
        'gatewayOrderId': gatewayOrderId,
        'gatewayPaymentId': gatewayPaymentId,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'verifiedAt': verifiedAt?.toIso8601String(),
      };
}

/// Result of calling the `createConsultationOrder` Cloud Function —
/// everything RazorpayCheckout needs to open the native checkout sheet.
/// `keyId` is Razorpay's *public* key (safe client-side); the secret key
/// never leaves the backend.
class ConsultationOrderResult {
  final String paymentDocId;
  final String razorpayOrderId;
  final String keyId;
  final int amountPaise;
  final String currency;

  const ConsultationOrderResult({
    required this.paymentDocId,
    required this.razorpayOrderId,
    required this.keyId,
    required this.amountPaise,
    required this.currency,
  });

  factory ConsultationOrderResult.fromMap(Map<dynamic, dynamic> map) {
    return ConsultationOrderResult(
      paymentDocId: map['paymentDocId'] as String,
      razorpayOrderId: map['razorpayOrderId'] as String,
      keyId: map['keyId'] as String,
      amountPaise: (map['amountPaise'] as num).toInt(),
      currency: map['currency'] as String? ?? ConsultationConstants.currencyInr,
    );
  }
}
