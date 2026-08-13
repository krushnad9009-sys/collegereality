import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/constants/firestore_constants.dart';
import '../models/payment_model.dart';

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);
  @override
  String toString() => message;
}

/// Client-side half of the payment flow. Every money-moving decision is
/// made server-side by Cloud Functions (see functions/src/consultations.js)
/// — this class only (a) asks the trusted backend to create a Razorpay
/// order, (b) hands the resulting order to the Razorpay Checkout SDK, and
/// (c) reports the gateway's signed result back to the backend for
/// verification. It never marks a payment successful itself.
class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Web has no supported Razorpay Flutter checkout UI; gate call sites on
  /// this rather than attempting a fake/partial web flow.
  bool get isCheckoutSupportedOnThisPlatform => !kIsWeb;

  CollectionReference<Map<String, dynamic>> get _payments =>
      _firestore.collection(FirestoreConstants.paymentsCollection);

  /// Calls the `createConsultationOrder` Cloud Function, which re-validates
  /// the guide's currently published price server-side (never trusts the
  /// client's number), creates the Razorpay order, and writes the
  /// `payments/{id}` doc with status `pending`. Also flips the consultation
  /// to `payment_pending`.
  Future<ConsultationOrderResult> createOrder(String consultationId) async {
    try {
      final callable = _functions.httpsCallable('createConsultationOrder');
      final result = await callable.call<Map<String, dynamic>>({
        'consultationId': consultationId,
      });
      return ConsultationOrderResult.fromMap(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw PaymentException(e.message ?? 'Could not start payment.');
    }
  }

  /// Opens Razorpay's native checkout sheet (mobile only). Resolves with
  /// the gateway's raw success response, or throws on failure/cancel.
  /// This does NOT mark anything paid — see [verifyPayment].
  Future<PaymentSuccessResponse> openCheckout({
    required ConsultationOrderResult order,
    required String description,
    required String contactEmail,
    required String contactPhone,
  }) {
    if (!isCheckoutSupportedOnThisPlatform) {
      throw PaymentException(
        'Payment checkout is available on the mobile app for now.',
      );
    }
    final razorpay = Razorpay();
    final completer = Completer<PaymentSuccessResponse>();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      if (!completer.isCompleted) completer.complete(r);
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      if (!completer.isCompleted) {
        completer.completeError(PaymentException(r.message ?? 'Payment failed.'));
      }
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      if (!completer.isCompleted) {
        completer.completeError(PaymentException('Payment cancelled.'));
      }
    });

    razorpay.open({
      'key': order.keyId,
      'amount': order.amountPaise,
      'currency': order.currency,
      'name': 'College Reality',
      'description': description,
      'order_id': order.razorpayOrderId,
      'prefill': {'contact': contactPhone, 'email': contactEmail},
    });

    return completer.future.whenComplete(razorpay.clear);
  }

  /// Reports the gateway's signed success payload to the trusted backend
  /// for HMAC verification. Only this Cloud Function may ever set a
  /// payment's status to `success` and unlock the consultation — the
  /// client-reported values are never trusted on their own.
  Future<void> verifyPayment({
    required String consultationId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyConsultationPayment');
      await callable.call<Map<String, dynamic>>({
        'consultationId': consultationId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      });
    } on FirebaseFunctionsException catch (e) {
      throw PaymentException(
        e.message ?? 'Could not verify payment. Contact support if money was deducted.',
      );
    }
  }

  Stream<PaymentModel?> watchPayment(String paymentId) {
    return _payments.doc(paymentId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PaymentModel.fromJson(doc.data()!, docId: doc.id);
    });
  }
}
