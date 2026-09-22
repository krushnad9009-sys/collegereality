import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// High-contrast status colors shared across the pending queue, the
// requests history list, and the guide directory -- distinct hues at
// different weights (soft tint vs solid fill) so status reads at a glance.
const _pendingBadgeColor = Color(0xFF92400E); // dark amber text on a soft-amber StatusBadge tint
const _paidBadgeColor = Color(0xFF15803D); // vibrant green, used with SolidStatusBadge
const _rejectedBadgeColor = Color(0xFFDC2626); // soft-red StatusBadge

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
  PayoutPeriod _period = PayoutPeriod.allTime;

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
    final actorAsync = ref.watch(currentUserModelProvider);
    final isAdminUser = ref.watch(isAdminUserProvider).maybeWhen(data: (v) => v, orElse: () => false);

    return AdminShellLayout(
      title: 'Payouts & Earnings',
      isAdminUser: isAdminUser,
      // Explicit loading/error/data handling here instead of
      // `.valueOrNull` -- that would read as `actor == null` the instant
      // currentUserModelProvider is still loading (or ever errors), which
      // made a genuine Super Admin see "access required" flash on every
      // open instead of the panel simply waiting for their role to load.
      child: actorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _PermissionErrorState(
          onRetry: () => ref.invalidate(currentUserModelProvider),
        ),
        data: (actor) {
          if (!AdminPermissions.canManagePayouts(actor?.userType)) {
            return const Center(child: Text('Super Admin access required.'));
          }
          return _DashboardBody(
            adminUid: actor?.uid ?? '',
            query: _query,
            onQueryChanged: (v) => setState(() => _query = v),
            searchController: _searchController,
            period: _period,
            onPeriodChanged: (p) => setState(() => _period = p),
            onRefresh: _refresh,
          );
        },
      ),
    );
  }
}

class _PermissionErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not confirm your admin access.',
              style: AppFonts.plusJakarta(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final String adminUid;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final TextEditingController searchController;
  final PayoutPeriod period;
  final ValueChanged<PayoutPeriod> onPeriodChanged;
  final VoidCallback onRefresh;

  const _DashboardBody({
    required this.adminUid,
    required this.query,
    required this.onQueryChanged,
    required this.searchController,
    required this.period,
    required this.onPeriodChanged,
    required this.onRefresh,
  });

  Future<void> _exportCsv(BuildContext context, List<PayoutRequestModel> requests) async {
    if (requests.isEmpty) {
      SnackBarHelper.showInfoSnackBar(context, message: 'No payout records to export yet.');
      return;
    }
    final csv = exportPayoutRequestsCsv(requests);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    SnackBarHelper.showSuccessSnackBar(
      context,
      message:
          'CSV copied to clipboard (${requests.length} record${requests.length == 1 ? '' : 's'}) '
          '-- paste into Excel or Google Sheets and save as .csv.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminPayoutsDashboardProvider);
    // adminPayoutsDashboardProvider never actually throws (every sub-fetch
    // and this itself degrades to AdminPayoutsDashboard.empty on failure),
    // but AsyncStateView's error/loading branches stay as a safety net for
    // the brief initial-load frame and for defense in depth.
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: AsyncStateView(
        value: dashboardAsync,
        onRetry: onRefresh,
        builder: (dashboard) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (dashboard.pendingRequests.isNotEmpty)
              _PendingAlertBanner(count: dashboard.pendingRequests.length),
            if (dashboard.pendingRequests.isNotEmpty) const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SegmentedButton<PayoutPeriod>(
                  segments: PayoutPeriod.values
                      .map((p) => ButtonSegment(value: p, label: Text(p.label)))
                      .toList(),
                  selected: {period},
                  onSelectionChanged: (s) => onPeriodChanged(s.first),
                  showSelectedIcon: false,
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportCsv(context, dashboard.allRequests),
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Export CSV Report'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _OverviewSection(dashboard: dashboard, period: period),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Platform Settings',
              style: AppFonts.plusJakarta(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _PlatformFeeCard(),
            const SizedBox(height: AppSpacing.md),
            const _AutoApproveThresholdCard(),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Pending Withdrawal Requests',
              style: AppFonts.plusJakarta(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (dashboard.pendingRequests.isEmpty)
              _EmptyStateCard(
                icon: Icons.inbox_outlined,
                title: 'No pending payout requests',
                subtitle: 'Withdrawal requests submitted by guides will show up here for review.',
                onRetry: onRefresh,
              )
            else
              ...dashboard.pendingRequests.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PendingRequestCard(
                    request: r,
                    adminUid: adminUid,
                    onDecided: onRefresh,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'All Withdrawal Requests',
              style: AppFonts.plusJakarta(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (dashboard.allRequests.isEmpty)
              _EmptyStateCard(
                icon: Icons.receipt_long_outlined,
                title: 'No withdrawal requests yet',
                subtitle: 'Every request a guide submits, decided or not, will be listed here.',
                onRetry: onRefresh,
              )
            else
              _RequestHistoryList(requests: dashboard.allRequests),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'All Guides Earnings Directory',
              style: AppFonts.plusJakarta(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Search by guide name or college',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => onQueryChanged(v.trim().toLowerCase()),
            ),
            const SizedBox(height: AppSpacing.sm),
            dashboard.guides.isEmpty
                ? _EmptyStateCard(
                    icon: Icons.groups_outlined,
                    title: 'No guides yet',
                    subtitle: 'Once a student turns on "Available as a guide", they\'ll show up here.',
                    onRetry: onRefresh,
                  )
                : _GuidesDirectory(
                    guides: dashboard.guides,
                    query: query,
                    adminUid: adminUid,
                    onAdjusted: onRefresh,
                  ),
          ],
        ),
      ),
    );
  }
}

/// Prominent banner shown only when there's something to act on -- pending
/// requests are a to-do, not just a stat, so they get pulled above the
/// fold instead of waiting to be noticed inside the overview grid.
class _PendingAlertBanner extends StatelessWidget {
  final int count;
  const _PendingAlertBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: _pendingBadgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: _pendingBadgeColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: _pendingBadgeColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count payout request${count == 1 ? '' : 's'} '
              '${count == 1 ? 'needs' : 'need'} your review.',
              style: AppFonts.plusJakarta(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _pendingBadgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clean, retryable empty state -- used instead of a hard error message
/// wherever a query legitimately returned zero rows (as opposed to
/// failing), so "nothing here yet" never reads like something is broken.
class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: tokens.textTertiary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppFonts.plusJakarta(fontSize: 14.5, fontWeight: FontWeight.w700, color: tokens.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppFonts.plusJakarta(fontSize: 12.5, color: tokens.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry / Refresh'),
          ),
        ],
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
  final PayoutPeriod period;
  const _OverviewSection({required this.dashboard, required this.period});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1100 ? 4 : width >= 700 ? 2 : 1;
    final pendingTotal =
        dashboard.pendingRequests.fold<int>(0, (t, r) => t + r.amountPaise);
    final revenue = dashboard.revenueFor(period);
    final periodSuffix = period == PayoutPeriod.allTime ? '' : ' (${period.label})';

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: width >= 700 ? 1.9 : 2.6,
      children: [
        _StatCard(
          label: 'Platform Commission Collected$periodSuffix',
          value: _rupees(revenue.commissionPaise),
          hint: 'From ${_rupees(revenue.grossPaise)} total transacted',
          icon: Icons.percent_rounded,
          color: Colors.indigo,
        ),
        _StatCard(
          label: 'Pending Withdrawal Requests',
          value: '${dashboard.pendingRequests.length}',
          hint: '${_rupees(pendingTotal)} awaiting review',
          icon: Icons.pending_actions_outlined,
          color: _pendingBadgeColor,
        ),
        _StatCard(
          label: 'Total Payouts Cleared$periodSuffix',
          value: _rupees(dashboard.paidOutPaiseFor(period)),
          hint: '${dashboard.paidRequestCountFor(period)} disbursed${period == PayoutPeriod.allTime ? ' to date' : ''}',
          icon: Icons.check_circle_outline,
          color: _paidBadgeColor,
        ),
        _StatCard(
          label: 'Total Guide Earnings (gross)$periodSuffix',
          value: _rupees(revenue.guidePayoutEarnedPaise),
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

class _AutoApproveThresholdCard extends ConsumerStatefulWidget {
  const _AutoApproveThresholdCard();

  @override
  ConsumerState<_AutoApproveThresholdCard> createState() => _AutoApproveThresholdCardState();
}

class _AutoApproveThresholdCardState extends ConsumerState<_AutoApproveThresholdCard> {
  final _controller = TextEditingController();
  bool _hydrated = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _hydrate(int thresholdPaise) {
    if (_hydrated) return;
    _hydrated = true;
    _controller.text = (thresholdPaise / 100).toStringAsFixed(0);
  }

  Future<void> _save() async {
    final rupees = double.tryParse(_controller.text.trim());
    if (rupees == null || rupees < 0) {
      SnackBarHelper.showErrorSnackBar(context, message: 'Enter a valid amount in rupees.');
      return;
    }
    setState(() => _saving = true);
    try {
      await saveAutoApproveThresholdPaise((rupees * 100).round());
      ref.invalidate(autoApproveThresholdPaiseProvider);
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(context, message: 'Auto-approve threshold updated.');
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
    final thresholdAsync = ref.watch(autoApproveThresholdPaiseProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Auto-Approve Payouts Below (₹)',
            style: AppFonts.plusJakarta(fontSize: 15, fontWeight: FontWeight.w700, color: tokens.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Requests under this amount are flagged in the pending queue for '
            'one-click instant approval instead of the full transaction-id '
            'dialog. Still requires a tap here -- nothing clears in the '
            'background automatically.',
            style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          thresholdAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Failed to load: $e'),
            data: (thresholdPaise) {
              _hydrate(thresholdPaise);
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                        isDense: true,
                        labelText: 'Threshold amount',
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

  /// One-click approval for requests under the configured auto-approve
  /// threshold -- skips the transaction-id dialog with an auto-generated
  /// reference instead. Still a manual tap, not a background job; see the
  /// doc comment on autoApproveThresholdPaiseProvider.
  Future<void> _instantApprove() async {
    setState(() => _busy = true);
    try {
      await ref.read(payoutServiceProvider).approvePayoutRequest(
            requestId: widget.request.id,
            transactionId: 'AUTO-${DateTime.now().millisecondsSinceEpoch}',
            adminUid: widget.adminUid,
          );
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(context, message: 'Instantly approved and marked as paid.');
      widget.onDecided();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(context, message: 'Could not approve: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final r = widget.request;
    final thresholdPaise = ref.watch(autoApproveThresholdPaiseProvider).valueOrNull;
    final isAutoApproveEligible =
        thresholdPaise != null && r.amountPaise < thresholdPaise;

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
          if (isAutoApproveEligible) ...[
            const SizedBox(height: 6),
            const StatusBadge(
              label: '⚡ Eligible for auto-approval',
              color: _paidBadgeColor,
              icon: Icons.bolt_rounded,
            ),
          ],
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
          if (isAutoApproveEligible) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _instantApprove,
                style: FilledButton.styleFrom(backgroundColor: _paidBadgeColor),
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: const Text('Instant Approve (below threshold)'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Every withdrawal request regardless of status -- capped to the 100 most
/// recent so this list stays readable; the full set is still what the CSV
/// export uses.
class _RequestHistoryList extends StatelessWidget {
  final List<PayoutRequestModel> requests;
  const _RequestHistoryList({required this.requests});

  @override
  Widget build(BuildContext context) {
    final shown = requests.take(100).toList();
    return Column(
      children: [
        for (final r in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _RequestHistoryTile(request: r),
          ),
        if (requests.length > shown.length)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Showing the ${shown.length} most recent of ${requests.length} requests -- use Export CSV Report for the full list.',
              style: AppFonts.plusJakarta(fontSize: 11.5, color: context.tokens.textTertiary),
            ),
          ),
      ],
    );
  }
}

class _RequestHistoryTile extends StatelessWidget {
  final PayoutRequestModel request;
  const _RequestHistoryTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final r = request;
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.guideName,
                  style: AppFonts.plusJakarta(fontWeight: FontWeight.w700, color: tokens.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Requested ${DateFormat('MMM d, yyyy').format(r.requestedAt)}'
                  '${r.decidedAt != null ? ' · Cleared ${DateFormat('MMM d, yyyy').format(r.decidedAt!)}' : ''}',
                  style: AppFonts.plusJakarta(fontSize: 11.5, color: tokens.textTertiary),
                ),
                if (r.status == PayoutRequestConstants.statusRejected &&
                    (r.rejectionReason?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Reason: ${r.rejectionReason}',
                      style: AppFonts.plusJakarta(fontSize: 11.5, color: _rejectedBadgeColor),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _rupees(r.amountPaise),
                style: AppFonts.plusJakarta(fontWeight: FontWeight.w700, color: tokens.textPrimary),
              ),
              const SizedBox(height: 4),
              _RequestStatusBadge(status: r.status),
            ],
          ),
        ],
      ),
    );
  }
}

/// High-contrast status badge: soft amber/dark-yellow for pending, a
/// vibrant solid green fill for paid (distinct from every other soft-tint
/// badge on this screen so a cleared payout is unmistakable at a glance),
/// and soft red for rejected.
class _RequestStatusBadge extends StatelessWidget {
  final String status;
  const _RequestStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case PayoutRequestConstants.statusPaid:
        return const SolidStatusBadge(
          label: 'Paid',
          color: _paidBadgeColor,
          icon: Icons.check_circle_rounded,
        );
      case PayoutRequestConstants.statusRejected:
        return const StatusBadge(
          label: 'Rejected',
          color: _rejectedBadgeColor,
          icon: Icons.cancel_outlined,
        );
      default:
        return const StatusBadge(
          label: 'Pending',
          color: _pendingBadgeColor,
          icon: Icons.schedule_rounded,
        );
    }
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
