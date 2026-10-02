import 'package:flutter/foundation.dart';

/// Super Admin-managed payment gateway settings, stored in
/// `app_config/payment_settings`.
///
/// Only the PUBLIC Razorpay Key ID lives here. Cloud Functions read it
/// (functions/src/razorpayConfig.js) and return it with every order, so
/// the app always opens checkout with the same key that created the order
/// -- the app never reads this doc itself. The Key Secret stays in Secret
/// Manager and must belong to the same key pair.
///
/// Empty key => the RAZORPAY_KEY_ID secret deployed with the functions.
@immutable
class PaymentSettings {
  static const String collection = 'app_config';
  static const String docId = 'payment_settings';

  /// Mirrors functions/src/paymentSettingsLogic.js and firestore.rules.
  static final RegExp _keyIdPattern =
      RegExp(r'^rzp_(test|live)_[A-Za-z0-9]{8,32}$');

  final String razorpayKeyId;
  final DateTime? updatedAt;
  final String? updatedBy;

  const PaymentSettings({
    this.razorpayKeyId = '',
    this.updatedAt,
    this.updatedBy,
  });

  static bool isValidKeyIdOrEmpty(String value) =>
      value.isEmpty || _keyIdPattern.hasMatch(value);

  bool get isLiveKey => razorpayKeyId.startsWith('rzp_live_');
  bool get isTestKey => razorpayKeyId.startsWith('rzp_test_');

  factory PaymentSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PaymentSettings();
    DateTime? updatedAt;
    final raw = json['updatedAt'];
    if (raw is String) {
      updatedAt = DateTime.tryParse(raw);
    } else if (raw != null) {
      try {
        updatedAt = (raw as dynamic).toDate() as DateTime;
      } catch (_) {}
    }
    return PaymentSettings(
      razorpayKeyId: (json['razorpayKeyId'] as String? ?? '').trim(),
      updatedAt: updatedAt,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'razorpayKeyId': razorpayKeyId};
}
