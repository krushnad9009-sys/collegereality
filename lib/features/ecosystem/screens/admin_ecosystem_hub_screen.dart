import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../core/constants/ecosystem_constants.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/ecosystem_provider.dart';

class AdminEcosystemHubScreen extends ConsumerWidget {
  const AdminEcosystemHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ecosystem Approvals'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.go(RouteNames.admin),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'Edits'),
              Tab(text: 'Reports'),
              Tab(text: 'Claims'),
              Tab(text: 'Faculty'),
              Tab(text: 'Audit'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestsTab(),
            _EditsTab(),
            _ReportsTab(),
            _ClaimsTab(),
            _FacultyTab(),
            _AuditTab(),
          ],
        ),
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingCollegeRequestsProvider);
    final user = ref.watch(currentUserDetailProvider).valueOrNull;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) => _ListShell(
        empty: 'No pending college requests',
        items: items,
        builder: (item) => _ApprovalCard(
          title: item.name,
          subtitle: '${item.city}, ${item.state} · by ${item.userName}',
          onApprove: () => ref.read(ecosystemServiceProvider).reviewCollegeRequest(
                requestId: item.id,
                adminId: user!.uid,
                adminName: user.displayName ?? 'Admin',
                approve: true,
              ).then((_) => ref.invalidate(pendingCollegeRequestsProvider)),
          onReject: () => ref.read(ecosystemServiceProvider).reviewCollegeRequest(
                requestId: item.id,
                adminId: user!.uid,
                adminName: user.displayName ?? 'Admin',
                approve: false,
                adminNotes: 'Rejected',
              ).then((_) => ref.invalidate(pendingCollegeRequestsProvider)),
        ),
      ),
    );
  }
}

class _EditsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingEditSuggestionsProvider);
    final user = ref.watch(currentUserDetailProvider).valueOrNull;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) => _ListShell(
        empty: 'No pending edit suggestions',
        items: items,
        builder: (item) => _ApprovalCard(
          title: '${item.field} — ${item.collegeName}',
          subtitle: '${item.currentValue} → ${item.suggestedValue}',
          onApprove: () => ref.read(ecosystemServiceProvider).reviewEditSuggestion(
                suggestionId: item.id,
                adminId: user!.uid,
                adminName: user.displayName ?? 'Admin',
                approve: true,
              ).then((_) => ref.invalidate(pendingEditSuggestionsProvider)),
          onReject: () => ref.read(ecosystemServiceProvider).reviewEditSuggestion(
                suggestionId: item.id,
                adminId: user!.uid,
                adminName: user.displayName ?? 'Admin',
                approve: false,
              ).then((_) => ref.invalidate(pendingEditSuggestionsProvider)),
        ),
      ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingDataReportsProvider);
    final user = ref.watch(currentUserDetailProvider).valueOrNull;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) => _ListShell(
        empty: 'No pending data reports',
        items: items,
        builder: (item) => _ApprovalCard(
          title: EcosystemConstants.reportTypeLabel(item.reportType),
          subtitle: '${item.collegeName}: ${item.description}',
          onApprove: () => ref.read(ecosystemServiceProvider).resolveDataReport(
                reportId: item.id,
                adminId: user!.uid,
                adminName: user.displayName ?? 'Admin',
                resolved: true,
              ).then((_) => ref.invalidate(pendingDataReportsProvider)),
          onReject: () => ref.read(ecosystemServiceProvider).resolveDataReport(
                reportId: item.id,
                adminId: user!.uid,
                adminName: user.displayName ?? 'Admin',
                resolved: false,
              ).then((_) => ref.invalidate(pendingDataReportsProvider)),
        ),
      ),
    );
  }
}

class _ClaimsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingCollegeClaimsProvider);
    final user = ref.watch(currentUserDetailProvider).valueOrNull;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) => _ListShell(
        empty: 'No pending claims',
        items: items,
        builder: (item) => _ApprovalCard(
          title: item.collegeName,
          subtitle: '${item.representativeName} · ${item.officialEmail}',
          onApprove: () => ref.read(ecosystemServiceProvider).approveCollegeClaim(
                claimId: item.id,
                adminId: user!.uid,
                adminName: user.displayName ?? 'Admin',
              ).then((_) => ref.invalidate(pendingCollegeClaimsProvider)),
          onReject: () => ref.read(ecosystemServiceProvider).rejectCollegeClaim(
                claimId: item.id,
                adminId: user!.uid,
                adminNotes: 'Rejected',
              ).then((_) => ref.invalidate(pendingCollegeClaimsProvider)),
        ),
      ),
    );
  }
}

class _FacultyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingFacultyRequestsProvider);
    final user = ref.watch(currentUserDetailProvider).valueOrNull;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) => _ListShell(
        empty: 'No pending faculty requests',
        items: items,
        builder: (item) => _ApprovalCard(
          title: item.userName,
          subtitle: '${item.collegeName} · ${item.officialEmail}',
          onApprove: () => ref.read(ecosystemServiceProvider).approveFacultyVerification(
                requestId: item.id,
                adminId: user!.uid,
                adminName: user.displayName ?? 'Admin',
              ).then((_) => ref.invalidate(pendingFacultyRequestsProvider)),
          onReject: () async {
            ref.invalidate(pendingFacultyRequestsProvider);
          },
        ),
      ),
    );
  }
}

class _AuditTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditLogsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (logs) {
        if (logs.isEmpty) return const Center(child: Text('No audit logs yet'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final log = logs[i];
            return Card(
              child: ListTile(
                title: Text(log.action, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${log.actorName.isNotEmpty ? log.actorName : log.actorId} · ${log.createdAt}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ListShell<T> extends StatelessWidget {
  final String empty;
  final List<T> items;
  final Widget Function(T item) builder;

  const _ListShell({
    required this.empty,
    required this.items,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Center(child: Text(empty));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => builder(items[i]),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.title,
    required this.subtitle,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(onPressed: onApprove, child: const Text('Approve')),
                TextButton(onPressed: onReject, child: const Text('Reject')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
