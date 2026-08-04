import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../ecosystem/models/ecosystem_models.dart';
import '../providers/admin_provider.dart';
import '../utils/admin_permissions.dart';
import '../widgets/admin_shell_layout.dart';

final adminAuditLogsProvider =
    FutureProvider.autoDispose<List<AuditLogModel>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final snap = await firestore
      .collection(FirestoreConstants.auditLogsCollection)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .get();
  return snap.docs
      .map((d) => AuditLogModel.fromJson(d.data(), docId: d.id))
      .toList();
});

final superAdminAuditLogsProvider =
    FutureProvider.autoDispose<List<AuditLogModel>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final snap = await firestore
      .collection(FirestoreConstants.superAdminAuditCollection)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .get();
  return snap.docs
      .map((d) => AuditLogModel.fromJson(d.data(), docId: d.id))
      .toList();
});

class AdminAuditLogsScreen extends ConsumerStatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  ConsumerState<AdminAuditLogsScreen> createState() =>
      _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends ConsumerState<AdminAuditLogsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentUserModelProvider).valueOrNull;
    final canView = AdminPermissions.canViewAuditLogs(actor?.userType);
    final isSuper = AdminPermissions.isSuperAdmin(actor?.userType);

    return AdminShellLayout(
      title: 'Audit Logs',
      isAdminUser: true,
      child: !canView
          ? const Center(child: Text('Staff access required.'))
          : Column(
              children: [
                if (isSuper)
                  TabBar(
                    controller: _tabs,
                    tabs: const [
                      Tab(text: 'Platform'),
                      Tab(text: 'Super Admin'),
                    ],
                  ),
                Expanded(
                  child: isSuper
                      ? TabBarView(
                          controller: _tabs,
                          children: [
                            _AuditList(provider: adminAuditLogsProvider),
                            _AuditList(provider: superAdminAuditLogsProvider),
                          ],
                        )
                      : _AuditList(provider: adminAuditLogsProvider),
                ),
              ],
            ),
    );
  }
}

class _AuditList extends ConsumerWidget {
  final ProviderListenable<AsyncValue<List<AuditLogModel>>> provider;

  const _AuditList({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed: $e')),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Text(
              'No audit entries yet',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.gray600),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final log = logs[index];
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(
                log.action,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  if (log.actorName.isNotEmpty) log.actorName,
                  if ((log.targetType ?? '').isNotEmpty)
                    '${log.targetType}:${log.targetId ?? ''}',
                  log.createdAt.toLocal().toString(),
                ].join(' · '),
              ),
            );
          },
        );
      },
    );
  }
}
