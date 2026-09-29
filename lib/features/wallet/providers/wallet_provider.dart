import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/wallet_service.dart';

final walletServiceProvider = Provider<WalletService>((ref) => WalletService());

final walletBalanceProvider =
    StreamProvider.family.autoDispose<int, String>((ref, uid) {
  return ref.watch(walletServiceProvider).watchBalancePaise(uid);
});

final walletTransactionsProvider = StreamProvider.family
    .autoDispose<List<WalletTransaction>, String>((ref, uid) {
  return ref.watch(walletServiceProvider).watchTransactions(uid);
});
