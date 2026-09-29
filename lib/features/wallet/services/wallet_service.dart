import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../communication/services/communication_firestore_service.dart';
import '../../consultations/models/payment_model.dart';
import '../../consultations/services/payment_service.dart';

/// Not enough balance for even [minCallSeconds] with this guide -- the UI
/// answers with the recharge popup.
class InsufficientBalanceException implements Exception {
  final String guideId;
  final int balancePaise;
  final int ratePaisePerMinute;
  final String message;

  const InsufficientBalanceException({
    required this.guideId,
    required this.balancePaise,
    required this.ratePaisePerMinute,
    required this.message,
  });

  @override
  String toString() => message;
}

class WalletTransaction {
  final String id;
  final String type; // 'recharge' | 'call'
  final int amountPaise; // + recharge, - call
  final int balanceAfterPaise;
  final String? guideAlias;
  final int billedSeconds;
  final int ratePaisePerMinute;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amountPaise,
    required this.balanceAfterPaise,
    this.guideAlias,
    this.billedSeconds = 0,
    this.ratePaisePerMinute = 0,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json, String id) =>
      WalletTransaction(
        id: id,
        type: json['type'] as String? ?? 'call',
        amountPaise: (json['amountPaise'] as num?)?.toInt() ?? 0,
        balanceAfterPaise: (json['balanceAfterPaise'] as num?)?.toInt() ?? 0,
        guideAlias: json['guideAlias'] as String?,
        billedSeconds: (json['billedSeconds'] as num?)?.toInt() ?? 0,
        ratePaisePerMinute: (json['ratePaisePerMinute'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

/// Client half of the shared call wallet. Every money decision is made by
/// Cloud Functions (functions/src/wallet.js): this only reads the balance
/// and ledger (owner read-only), asks for recharge orders, reports the
/// gateway's signed result, and asks the server to start paid calls.
class WalletService {
  WalletService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestoreOverride = firestore,
        _functionsOverride = functions;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseFunctions? _functionsOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  Stream<int> watchBalancePaise(String uid) => _firestore
      .collection('wallets')
      .doc(uid)
      .snapshots()
      .map((d) => (d.data()?['balancePaise'] as num?)?.toInt() ?? 0);

  Future<int> getBalancePaise(String uid) async {
    final doc = await _firestore.collection('wallets').doc(uid).get();
    return (doc.data()?['balancePaise'] as num?)?.toInt() ?? 0;
  }

  Stream<List<WalletTransaction>> watchTransactions(String uid) => _firestore
      .collection('wallet_transactions')
      .where('uid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs
          .map((d) => WalletTransaction.fromJson(d.data(), d.id))
          .toList());

  Future<ConsultationOrderResult> createRechargeOrder(int amountPaise) async {
    try {
      final result = await _functions
          .httpsCallable('createWalletRechargeOrder')
          .call<Map<String, dynamic>>({'amountPaise': amountPaise});
      return ConsultationOrderResult.fromMap(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw PaymentException(e.message ?? 'Could not start the recharge.');
    }
  }

  Future<void> verifyRecharge({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      await _functions.httpsCallable('verifyWalletRecharge').call({
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      });
    } on FirebaseFunctionsException catch (e) {
      throw PaymentException(
        e.message ??
            'Could not confirm the recharge. If money was deducted it will '
                'be added to your wallet shortly.',
      );
    }
  }

  /// Starts a wallet-paid call to [guideId]; returns the call session id.
  Future<String> startPaidCall({
    required String guideId,
    required String callType,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('startPaidCall')
          .call<Map<String, dynamic>>({
        'guideId': guideId,
        'callType': callType,
      });
      return result.data['sessionId'] as String;
    } on FirebaseFunctionsException catch (e) {
      final details = e.details is Map ? e.details as Map : const {};
      if (e.code == 'resource-exhausted' &&
          details['reason'] == 'insufficient_balance') {
        throw InsufficientBalanceException(
          guideId: guideId,
          balancePaise: (details['balancePaise'] as num?)?.toInt() ?? 0,
          ratePaisePerMinute:
              (details['ratePaisePerMinute'] as num?)?.toInt() ?? 0,
          message: e.message ?? 'Your wallet balance is too low.',
        );
      }
      throw CommunicationException(e.message ?? 'Could not start the call.');
    }
  }
}
