import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/services/firestore_user_service.dart';
import '../models/payout_models.dart';
import '../providers/consultation_provider.dart';

String _rupees(int paise) {
  final rupees = (paise / 100).round();
  return '₹${NumberFormat.decimalPattern('en_IN').format(rupees)}';
}

/// Linked payout method plus any Super Admin manual balance adjustment.
/// Persisted in `UserModel.metadata['wallet']` -- the existing owner-only
/// free-form bag (already stripped from the public_profiles mirror in
/// FirestoreUserService.syncPublicProfile), so linking a UPI/bank account
/// needs no new Firestore collection or rules change. The actual earnings
/// figures come from the backend-authoritative `guide_earnings` ledger and
/// the `payout_requests` collection, not from this wallet -- see
/// [_EarningsBodyState.build].
class _Wallet {
  final int manualAdjustmentPaise;
  final String? upiId;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? accountHolderName;

  const _Wallet({
    this.manualAdjustmentPaise = 0,
    this.upiId,
    this.bankAccountNumber,
    this.bankIfsc,
    this.accountHolderName,
  });

  bool get hasPayoutMethod =>
      (upiId?.isNotEmpty ?? false) || (bankAccountNumber?.isNotEmpty ?? false);

  String get payoutSummary {
    if (upiId != null && upiId!.isNotEmpty) return upiId!;
    if (bankAccountNumber != null && bankAccountNumber!.isNotEmpty) {
      final acct = bankAccountNumber!;
      final last4 = acct.length > 4 ? acct.substring(acct.length - 4) : acct;
      return 'Bank account ····$last4';
    }
    return 'Not linked';
  }

  PayoutMethodSnapshot toSnapshot() => PayoutMethodSnapshot(
        type: (upiId?.isNotEmpty ?? false) ? 'upi' : 'bank',
        upiId: upiId,
        bankAccountNumber: bankAccountNumber,
        bankIfsc: bankIfsc,
        accountHolderName: accountHolderName,
      );

  static int _asInt(dynamic v) => v is num ? v.toInt() : 0;
  static String? _asString(dynamic v) => v is String && v.isNotEmpty ? v : null;

  /// Never throws -- a brand-new guide has no `wallet` entry yet (and an
  /// old/partially-written one could have the wrong shape), and either case
  /// should read as "no payout method linked" rather than an error. `json`
  /// itself may not even be a `Map` if legacy data wrote something else
  /// under this key.
  factory _Wallet.fromJson(Object? json) {
    if (json is! Map) return const _Wallet();
    return _Wallet(
      manualAdjustmentPaise: _asInt(json['manualAdjustmentPaise']),
      upiId: _asString(json['upiId']),
      bankAccountNumber: _asString(json['bankAccountNumber']),
      bankIfsc: _asString(json['bankIfsc']),
      accountHolderName: _asString(json['accountHolderName']),
    );
  }

  Map<String, dynamic> toJson() => {
        'manualAdjustmentPaise': manualAdjustmentPaise,
        if (upiId != null) 'upiId': upiId,
        if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
        if (bankIfsc != null) 'bankIfsc': bankIfsc,
        if (accountHolderName != null) 'accountHolderName': accountHolderName,
      };

  _Wallet copyWith({
    int? manualAdjustmentPaise,
    String? upiId,
    String? bankAccountNumber,
    String? bankIfsc,
    String? accountHolderName,
  }) {
    return _Wallet(
      manualAdjustmentPaise: manualAdjustmentPaise ?? this.manualAdjustmentPaise,
      upiId: upiId ?? this.upiId,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      accountHolderName: accountHolderName ?? this.accountHolderName,
    );
  }
}

/// Guide-only earnings dashboard reached from the drawer's "Earnings &
/// Payouts" item. Total earnings come from the backend-authoritative
/// `guide_earnings/{uid}/entries` ledger (written only by trusted Cloud
/// Function logic on payment/completion/refund); withdrawals create a
/// `payout_requests` doc reviewed by Super Admin in
/// admin_payouts_screen.dart -- the two screens share this same data, so a
/// request approved/rejected there is reflected here.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserDetailProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.home),
        ),
        title: const Text('Earnings & Payouts'),
      ),
      body: AsyncStateView(
        value: userAsync,
        builder: (user) {
          if (user == null) {
            return const AsyncEmptyView(
              icon: Icons.person_off_outlined,
              title: 'Not signed in',
              subtitle: 'Sign in to view your earnings.',
            );
          }
          if (!user.communicationSettings.isGuideAvailable) {
            return const AsyncEmptyView(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Guide earnings only',
              subtitle:
                  'Turn on "Available as a guide" from your profile to start earning from paid consultations.',
            );
          }
          return _EarningsBody(user: user);
        },
      ),
    );
  }
}

class _EarningsBody extends ConsumerStatefulWidget {
  final UserModel user;
  const _EarningsBody({required this.user});

  @override
  ConsumerState<_EarningsBody> createState() => _EarningsBodyState();
}

class _EarningsBodyState extends ConsumerState<_EarningsBody> {
  final _userService = FirestoreUserService();
  bool _busy = false;

  Future<void> _saveWallet(_Wallet wallet) async {
    final metadata = Map<String, dynamic>.from(widget.user.metadata ?? {});
    metadata['wallet'] = wallet.toJson();
    await _userService.updateUserProfile(
      uid: widget.user.uid,
      metadata: metadata,
    );
    ref.invalidate(currentUserDetailProvider);
  }

  Future<void> _openPayoutSetup(_Wallet current) async {
    final result = await showModalBottomSheet<_Wallet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayoutSetupSheet(initial: current),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _saveWallet(result);
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(context, message: 'Payout details saved.');
    } catch (e) {
      if (kDebugMode) debugPrint('[Earnings] payout save failed: $e');
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Could not save payout details. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw(_Wallet wallet, int availablePaise) async {
    if (!wallet.hasPayoutMethod) {
      SnackBarHelper.showInfoSnackBar(
        context,
        message: 'Link a UPI ID or bank account first.',
      );
      await _openPayoutSetup(wallet);
      return;
    }
    if (availablePaise <= 0) {
      SnackBarHelper.showInfoSnackBar(
        context,
        message: 'No balance available to withdraw yet.',
      );
      return;
    }
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: 'Withdraw funds',
      message:
          'Request a withdrawal of ${_rupees(availablePaise)} to ${wallet.payoutSummary}? '
          'A Super Admin reviews every request before it is paid out.',
      confirmText: 'Request withdrawal',
      cancelText: 'Cancel',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(payoutServiceProvider).createPayoutRequest(
            guideId: widget.user.uid,
            guideName: widget.user.effectivePublicDisplayName,
            amountPaise: availablePaise,
            payoutMethod: wallet.toSnapshot(),
          );
      ref.invalidate(guidePayoutRequestsProvider(widget.user.uid));
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: 'Withdrawal request submitted for review.',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Earnings] withdraw failed: $e');
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Could not submit withdrawal. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.user.uid;
    final entriesAsync = ref.watch(guideEarningsEntriesProvider(uid));
    final requestsAsync = ref.watch(guidePayoutRequestsProvider(uid));
    final wallet = _Wallet.fromJson(widget.user.metadata?['wallet']);

    return AsyncStateView(
      value: entriesAsync,
      onRetry: () => ref.invalidate(guideEarningsEntriesProvider(uid)),
      builder: (entries) {
        final payable = entries.where((e) => e.status == 'payable').toList();
        final processingPaise = entries
            .where((e) => e.status == 'pending')
            .fold<int>(0, (t, e) => t + e.amountPaise);
        final totalEarnedPaise =
            payable.fold<int>(0, (t, e) => t + e.amountPaise);

        // Every non-rejected request (pending or already paid) reserves
        // that amount out of the balance -- a rejected one returns it
        // automatically since it's simply excluded here, no separate
        // "refund to balance" bookkeeping needed.
        final requests = requestsAsync.valueOrNull ?? const <PayoutRequestModel>[];
        final reservedPaise = requests
            .where((r) => r.status != PayoutRequestConstants.statusRejected)
            .fold<int>(0, (t, r) => t + r.amountPaise);
        final rawAvailable =
            totalEarnedPaise + wallet.manualAdjustmentPaise - reservedPaise;
        final availablePaise = rawAvailable < 0 ? 0 : rawAvailable;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(guideEarningsEntriesProvider(uid));
            ref.invalidate(guidePayoutRequestsProvider(uid));
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageH),
            children: [
              _TotalEarningsCard(
                totalPaise: totalEarnedPaise,
                completedCount: payable.length,
                processingPaise: processingPaise,
              ),
              const SizedBox(height: 16),
              _AvailableBalanceCard(
                availablePaise: availablePaise,
                isBusy: _busy,
                onWithdraw: () => _withdraw(wallet, availablePaise),
              ),
              const SizedBox(height: 16),
              _StyledCard(
                padding: EdgeInsets.zero,
                child: PremiumListRow(
                  leadingIcon: Icons.account_balance_outlined,
                  title: 'Bank / UPI details',
                  subtitle: wallet.payoutSummary,
                  onTap: _busy ? null : () => _openPayoutSetup(wallet),
                ),
              ),
              const SizedBox(height: 16),
              const SectionHeader(
                title: 'Withdrawal requests',
                subtitle: 'Reviewed by a Super Admin.',
              ),
              requestsAsync.when(
                data: (list) => list.isEmpty
                    ? Text(
                        'No withdrawal requests yet.',
                        style: AppFonts.plusJakarta(
                          fontSize: 13,
                          color: context.tokens.textTertiary,
                        ),
                      )
                    : Column(
                        children: list
                            .map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _WithdrawalRequestTile(request: r),
                              ),
                            )
                            .toList(),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                // Best-effort section beneath the balance cards above --
                // never block the whole page on this list failing to load.
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              const SectionHeader(
                title: 'Transaction history',
                subtitle: 'Your guidance sessions and their payout status.',
              ),
              if (entries.isEmpty)
                const AsyncEmptyView(
                  icon: Icons.receipt_long_outlined,
                  title: 'No sessions yet',
                  subtitle: 'Completed guidance sessions will show up here.',
                )
              else
                ...entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EarningsEntryTile(entry: e),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TotalEarningsCard extends StatelessWidget {
  final int totalPaise;
  final int completedCount;
  final int processingPaise;

  const _TotalEarningsCard({
    required this.totalPaise,
    required this.completedCount,
    this.processingPaise = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Total Earnings',
                style: AppFonts.plusJakarta(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${_rupees(totalPaise)} Earned',
            style: AppFonts.plusJakarta(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'From $completedCount completed ${completedCount == 1 ? 'session' : 'sessions'}'
            '${processingPaise > 0 ? ' · ${_rupees(processingPaise)} processing' : ''}',
            style: AppFonts.plusJakarta(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared card shell for "Available Balance" and "Bank / UPI details" --
/// an explicit grey border plus a visible drop shadow so both stand out
/// clearly against the page background, distinct from [PremiumCard]'s
/// subtler tokens-driven styling used elsewhere.
class _StyledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _StyledCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AvailableBalanceCard extends StatelessWidget {
  final int availablePaise;
  final bool isBusy;
  final VoidCallback onWithdraw;

  const _AvailableBalanceCard({
    required this.availablePaise,
    required this.isBusy,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return _StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: AppFonts.plusJakarta(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _rupees(availablePaise),
            style: AppFonts.plusJakarta(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: tokens.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isBusy ? null : onWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                elevation: 0,
              ),
              child: isBusy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Withdraw Funds',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.plusJakarta(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsEntryTile extends StatelessWidget {
  final GuideEarningsEntry entry;
  const _EarningsEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final String label;
    final Color statusColor;
    switch (entry.status) {
      case 'payable':
        label = 'Completed';
        statusColor = const Color(0xFF16A34A);
      case 'pending':
        label = 'Processing';
        statusColor = const Color(0xFFD97706);
      default:
        label = 'Refunded';
        statusColor = const Color(0xFF64748B);
    }

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(Icons.payments_outlined, size: 18, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consultation session',
                  style: AppFonts.plusJakarta(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy').format(entry.createdAt),
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${_rupees(entry.amountPaise)}',
                style: AppFonts.plusJakarta(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              StatusBadge(label: label, color: statusColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _WithdrawalRequestTile extends StatelessWidget {
  final PayoutRequestModel request;
  const _WithdrawalRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final String label;
    final Color statusColor;
    switch (request.status) {
      case PayoutRequestConstants.statusPaid:
        label = 'Paid';
        statusColor = const Color(0xFF16A34A);
      case PayoutRequestConstants.statusRejected:
        label = 'Rejected';
        statusColor = const Color(0xFFDC2626);
      default:
        label = 'Pending review';
        statusColor = const Color(0xFFD97706);
    }

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _rupees(request.amountPaise),
                  style: AppFonts.plusJakarta(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              StatusBadge(label: label, color: statusColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Requested ${DateFormat('MMM d, yyyy').format(request.requestedAt)} '
            '· to ${request.payoutMethod.summary}',
            style: AppFonts.plusJakarta(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tokens.textTertiary,
            ),
          ),
          if (request.status == PayoutRequestConstants.statusPaid &&
              (request.transactionId?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 4),
            Text(
              'Transaction ID: ${request.transactionId}',
              style: AppFonts.plusJakarta(fontSize: 11.5, color: tokens.textTertiary),
            ),
          ],
          if (request.status == PayoutRequestConstants.statusRejected &&
              (request.rejectionReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 4),
            Text(
              'Reason: ${request.rejectionReason}',
              style: AppFonts.plusJakarta(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PayoutSetupSheet extends StatefulWidget {
  final _Wallet initial;
  const _PayoutSetupSheet({required this.initial});

  @override
  State<_PayoutSetupSheet> createState() => _PayoutSetupSheetState();
}

class _PayoutSetupSheetState extends State<_PayoutSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  late bool _isUpi;
  late final TextEditingController _upiController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _ifscController;
  late final TextEditingController _holderNameController;

  @override
  void initState() {
    super.initState();
    _isUpi = !(widget.initial.bankAccountNumber?.isNotEmpty ?? false);
    _upiController = TextEditingController(text: widget.initial.upiId ?? '');
    _accountNumberController =
        TextEditingController(text: widget.initial.bankAccountNumber ?? '');
    _ifscController = TextEditingController(text: widget.initial.bankIfsc ?? '');
    _holderNameController =
        TextEditingController(text: widget.initial.accountHolderName ?? '');
  }

  @override
  void dispose() {
    _upiController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final wallet = _isUpi
        ? widget.initial.copyWith(
            upiId: _upiController.text.trim(),
            bankAccountNumber: '',
            bankIfsc: '',
            accountHolderName: '',
          )
        : widget.initial.copyWith(
            upiId: '',
            bankAccountNumber: _accountNumberController.text.trim(),
            bankIfsc: _ifscController.text.trim().toUpperCase(),
            accountHolderName: _holderNameController.text.trim(),
          );
    Navigator.of(context).pop(wallet);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageH,
                  AppSpacing.md,
                  AppSpacing.pageH,
                  AppSpacing.xl,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: tokens.borderSubtle,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    'Receive payments',
                    style: AppFonts.plusJakarta(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Link a UPI ID or bank account to withdraw your earnings.',
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: tokens.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('UPI'),
                          selected: _isUpi,
                          onSelected: (_) => setState(() => _isUpi = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Bank account'),
                          selected: !_isUpi,
                          onSelected: (_) => setState(() => _isUpi = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_isUpi)
                    CustomTextField(
                      label: 'UPI ID',
                      hint: 'yourname@bank',
                      controller: _upiController,
                      isRequired: true,
                      prefixIcon: Icons.alternate_email_rounded,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Enter your UPI ID';
                        if (!RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$').hasMatch(value)) {
                          return 'Enter a valid UPI ID';
                        }
                        return null;
                      },
                    )
                  else ...[
                    CustomTextField(
                      label: 'Account holder name',
                      controller: _holderNameController,
                      isRequired: true,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Enter the account holder's name"
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomTextField(
                      label: 'Account number',
                      controller: _accountNumberController,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.length < 6) return 'Enter a valid account number';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomTextField(
                      label: 'IFSC code',
                      controller: _ifscController,
                      isRequired: true,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (!RegExp(r'^[A-Za-z]{4}0[A-Za-z0-9]{6}$').hasMatch(value)) {
                          return 'Enter a valid IFSC code';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(label: 'Save payout details', onPressed: _save),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
