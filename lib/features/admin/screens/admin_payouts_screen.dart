import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/widgets/index.dart';
import '../../consultations/models/payout_models.dart';
import '../../consultations/providers/consultation_provider.dart';
import '../providers/admin_payouts_provider.dart';
import '../providers/admin_provider.dart';
import '../utils/admin_permissions.dart';
import '../widgets/admin_shell_layout.dart';

String _rupees(int paise) {
  final rupees = (paise / 100).round();
  return '₹${NumberFormat.decimalPattern('en_IN').format(rupees)}';
}

/// Super Admin panel for reviewing guide withdrawal requests, the platform
/// commission, and every guide's earnings -- built on the
/// backend-authoritative `guide_earnings` ledger and the admin-manageable
/// `payout_requests` collection (see admin_payouts_provider.dart for the
/// query/aggregation strategy, and EarningsScreen for the guide-facing
/// side of this same data).
class AdminPayoutsScreen extends ConsumerStatefulWidget {
  const AdminPayoutsScreen({super.key});

  @override
  ConsumerState<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends ConsumerState<AdminPayoutsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(adminPayoutsDashboardProvider);
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentUserModelProvider).valueOrNull;
    final isAdminUser = ref.watch(isAdminUserProvider).maybeWhen(data: (v) => v, orElse: () => false);
    final canManage = AdminPermissions.canManagePayouts(actor?.userType);
    final dashboardAsync = ref.watch(adminPayoutsDashboardProvider);

    return AdminShellLayout(
      title: 'Payouts & Earnings',
      isAdminUser: isAdminUser,
      child: !canManage
          ? const Center(child: Text('Super Admin access required.'))
          : RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: AsyncStateView(
                value: dashboardAsync,
                onRetry: _refresh,
                builder: (dashboard) => ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _OverviewSection(dashboard: dashboard),
                    const SizedBox(height: AppSpacing.xl),
                    const _PlatformFeeCard(),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Pending Withdrawal Requests',
                      style: AppFonts.plusJakarta(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (dashboard.pendingRequests.isEmpty)
                      _EmptyNote(text: 'No withdrawal requests are waiting for review.')
                    else
                      ...dashboard.pendingRequests.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _PendingRequestCard(
                            request: r,
                            adminUid: actor?.uid ?? '',
                            onDecided: _refresh,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'All Guides Earnings Directory',
                      style: AppFonts.plusJakarta(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Search by guide name or college',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _GuidesDirectory(
                      guides: dashboard.guides,
                      query: _query,
                      adminUid: actor?.uid ?? '',
                      onAdjusted: _refresh,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;
  const _EmptyNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        text,
        style: AppFonts.plusJakarta(fontSize: 13, color: context.tokens.textTertiary),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final AdminPayoutsDashboard dashboard;
  const _OverviewSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1100 ? 4 : width >= 700 ? 2 : 1;
    final pendingTotal =
        dashboard.pendingRequests.fold<int>(0, (t, r) => t + r.amountPaise);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: width >= 700 ? 1.9 : 2.6,
      children: [
        _StatCard(
          label: 'Platform Commission Collected',
          value: _rupees(dashboard.revenue.commissionPaise),
          hint: 'From ${_rupees(dashboard.revenue.grossPaise)} total transacted',
          icon: Icons.percent_rounded,
          color: Colors.indigo,
        ),
        _StatCard(
          label: 'Pending Withdrawal Requests',
          value: '${dashboard.pendingRequests.length}',
          hint: '${_rupees(pendingTotal)} awaiting review',
          icon: Icons.pending_actions_outlined,
          color: Colors.amber.shade800,
        ),
        _StatCard(
          label: 'Total Payouts Cleared',
          value: _rupees(dashboard.totalPaidOutPaise),
          hint: '${dashboard.paidRequestCount} disbursed to date',
          icon: Icons.check_circle_outline,
          color: Colors.green.shade700,
        ),
        _StatCard(
          label: 'Total Guide Earnings (gross)',
          value: _rupees(dashboard.revenue.guidePayoutEarnedPaise),
          hint: '${dashboard.guides.length} active guides',
          icon: Icons.groups_outlined,
          color: Colors.blueGrey,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppFonts.plusJakarta(fontSize: 20, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.plusJakarta(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: AppFonts.plusJakarta(fontSize: 11, color: tokens.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PlatformFeeCard extends ConsumerStatefulWidget {
  const _PlatformFeeCard();

  @override
  ConsumerState<_PlatformFeeCard> createState() => _PlatformFeeCardState();
}

class _PlatformFeeCardState extends ConsumerState<_PlatformFeeCard> {
  final _controller = TextEditingController();
  bool _hydrated = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _hydrate(double percent) {
    if (_hydrated) return;
    _hydrated = true;
    _controller.text = percent % 1 == 0 ? percent.toStringAsFixed(0) : percent.toString();
  }

  Future<void> _save() async {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 0 || parsed > 100) {
      SnackBarHelper.showErrorSnackBar(context, message: 'Enter a percentage between 0 and 100.');
      return;
    }
    setState(() => _saving = true);
    try {
      await savePlatformFeePercent(parsed);
      ref.invalidate(platformFeeConfigProvider);
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(context, message: 'Platform commission updated.');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(context, message: 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final feeAsync = ref.watch(platformFeeConfigProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Commission',
            style: AppFonts.plusJakarta(fontSize: 15, fontWeight: FontWeight.w700, color: tokens.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Percentage taken from each paid consultation. Applies to display '
            'estimates going forward only -- it does not change past '
            'transactions, and the deployed backend split (functions/src/'
            'consultationLogic.js) must be updated separately to enforce a '
            'new value on real payments.',
            style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          feeAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Failed to load: $e'),
            data: (percent) {
              _hydrate(percent);
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixText: '%',
                        isDense: true,
                        labelText: 'Commission percentage',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends ConsumerStatefulWidget {
  final PayoutRequestModel request;
  final String adminUid;
  final VoidCallback onDecided;

  const _PendingRequestCard({
    required this.request,
    required this.adminUid,
    required this.onDecided,
  });

  @override
  ConsumerState<_PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends ConsumerState<_PendingRequestCard> {
  bool _busy = false;

  Future<void> _approve() async {
    final controller = TextEditingController();
    final transactionId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve & Mark Paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pay ${_rupees(widget.request.amountPaise)} to '
                '${widget.request.guideName} via ${widget.request.payoutMethod.summary}, '
                'then record the transfer reference below.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Transaction ID',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (transactionId == null || transactionId.isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(payoutServiceProvider).approvePayoutRequest(
            requestId: widget.request.id,
            transactionId: transactionId,
            adminUid: widget.adminUid,
          );
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(context, message: 'Marked as paid.');
      widget.onDecided();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(context, message: 'Could not approve: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason (required)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(payoutServiceProvider).rejectPayoutRequest(
            requestId: widget.request.id,
            reason: reason,
            adminUid: widget.adminUid,
          );
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: 'Rejected -- funds returned to the guide\'s available balance.',
      );
      widget.onDecided();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(context, message: 'Could not reject: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final r = widget.request;
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.guideName,
                  style: AppFonts.plusJakarta(fontWeight: FontWeight.w700, color: tokens.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _rupees(r.amountPaise),
                style: AppFonts.plusJakarta(fontWeight: FontWeight.w800, fontSize: 16, color: tokens.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Guide ID: ${r.guideId}',
            style: AppFonts.plusJakarta(fontSize: 11.5, color: tokens.textTertiary),
          ),
          const SizedBox(height: 2),
          Text(
            'To ${r.payoutMethod.summary} · Requested ${DateFormat('MMM d, yyyy · h:mm a').format(r.requestedAt)}',
            style: AppFonts.plusJakarta(fontSize: 12.5, color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _reject,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject Request'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _approve,
                  icon: _busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve & Mark Paid'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuidesDirectory extends StatelessWidget {
  final List<AdminGuideSummary> guides;
  final String query;
  final String adminUid;
  final VoidCallback onAdjusted;

  const _GuidesDirectory({
    required this.guides,
    required this.query,
    required this.adminUid,
    required this.onAdjusted,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = query.isEmpty
        ? guides
        : guides.where((g) {
            final name = g.user.effectivePublicDisplayName.toLowerCase();
            final college = (g.user.collegeName ?? '').toLowerCase();
            return name.contains(query) || college.contains(query);
          }).toList();

    if (filtered.isEmpty) {
      return _EmptyNote(
        text: guides.isEmpty
            ? 'No guides have gone available yet.'
            : 'No guides match "$query".',
      );
    }

    return Column(
      children: filtered
          .map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _GuideRow(guide: g, adminUid: adminUid, onAdjusted: onAdjusted),
            ),
          )
          .toList(),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final AdminGuideSummary guide;
  final String adminUid;
  final VoidCallback onAdjusted;

  const _GuideRow({required this.guide, required this.adminUid, required this.onAdjusted});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final user = guide.user;
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _GuideDetailSheet(guide: guide, adminUid: adminUid, onAdjusted: onAdjusted),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.effectivePublicDisplayName,
                        style: AppFonts.plusJakarta(fontWeight: FontWeight.w700, color: tokens.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: Colors.blue),
                    ],
                  ],
                ),
                if ((user.collegeName ?? '').isNotEmpty)
                  Text(
                    user.collegeName!,
                    style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${guide.completedConsultations} sessions',
                  style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textSecondary),
                ),
                Text(
                  '${_rupees(guide.totalEarnedPaise)} earned',
                  style: AppFonts.plusJakarta(fontSize: 12.5, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                ),
                Text(
                  '${_rupees(guide.availableBalancePaise)} available',
                  style: AppFonts.plusJakarta(fontSize: 11.5, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideDetailSheet extends ConsumerStatefulWidget {
  final AdminGuideSummary guide;
  final String adminUid;
  final VoidCallback onAdjusted;

  const _GuideDetailSheet({required this.guide, required this.adminUid, required this.onAdjusted});

  @override
  ConsumerState<_GuideDetailSheet> createState() => _GuideDetailSheetState();
}

class _GuideDetailSheetState extends ConsumerState<_GuideDetailSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitAdjustment() async {
    final rupees = double.tryParse(_amountController.text.trim());
    final note = _noteController.text.trim();
    if (rupees == null || rupees == 0) {
      SnackBarHelper.showErrorSnackBar(context, message: 'Enter a non-zero amount (use "-" to deduct).');
      return;
    }
    if (note.isEmpty) {
      SnackBarHelper.showErrorSnackBar(context, message: 'An admin note is required for every adjustment.');
      return;
    }
    setState(() => _saving = true);
    try {
      await applyManualBalanceAdjustment(
        guideId: widget.guide.user.uid,
        deltaPaise: (rupees * 100).round(),
        note: note,
        adminUid: widget.adminUid,
      );
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(context, message: 'Balance adjusted.');
      widget.onAdjusted();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(context, message: 'Could not adjust balance: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ledgerAsync = ref.watch(adminGuideLedgerProvider(widget.guide.user.uid));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(color: tokens.borderSubtle, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                Text(
                  widget.guide.user.effectivePublicDisplayName,
                  style: AppFonts.plusJakarta(fontSize: 18, fontWeight: FontWeight.w800, color: tokens.textPrimary),
                ),
                Text(
                  '${_rupees(widget.guide.totalEarnedPaise)} earned · ${_rupees(widget.guide.availableBalancePaise)} available',
                  style: AppFonts.plusJakarta(fontSize: 13, color: tokens.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Manually adjust balance',
                  style: AppFonts.plusJakarta(fontSize: 14, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹, use - to deduct)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Admin note (required)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: _saving ? null : _submitAdjustment,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Apply adjustment'),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Ledger',
                  style: AppFonts.plusJakarta(fontSize: 14, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                ),
                const SizedBox(height: 6),
                ledgerAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Failed to load ledger: $e'),
                  data: (entries) => entries.isEmpty
                      ? _EmptyNote(text: 'No earnings entries yet.')
                      : Column(
                          children: entries
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          DateFormat('MMM d, yyyy').format(e.createdAt),
                                          style: AppFonts.plusJakarta(fontSize: 12.5, color: tokens.textSecondary),
                                        ),
                                      ),
                                      Text(
                                        e.status,
                                        style: AppFonts.plusJakarta(fontSize: 11.5, color: tokens.textTertiary),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _rupees(e.amountPaise),
                                        style: AppFonts.plusJakarta(fontSize: 12.5, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
