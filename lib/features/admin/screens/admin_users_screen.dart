import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/admin_models.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_shell_layout.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();

  // Two independent data modes, mirroring AdminCollegesScreen:
  //  * no filter text -> paginated listing of ALL users (this list + cursor)
  //  * filter text present -> one-shot searchUsers() results (unpaginated,
  //    already capped at AdminConstants.maxSearchUsers -- unchanged)
  String? _cursor;
  bool _hasMore = false;
  List<AdminUserSearchResult> _users = [];
  bool _loading = false;
  String? _error;

  bool get _isFiltering => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool loadMore = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        final results =
            await ref.read(adminUserSearchProvider(query).future);
        if (!mounted) return;
        setState(() {
          _users = results;
          _cursor = null;
          _hasMore = false;
        });
        return;
      }

      final page = await ref.read(
        adminUserPageProvider(
          AdminUserPageParams(startAfterDocumentId: loadMore ? _cursor : null),
        ).future,
      );
      if (!mounted) return;
      setState(() {
        _users = loadMore ? [..._users, ...page.items] : page.items;
        _cursor = page.lastDocumentId;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isAdminUser = ref.watch(isAdminUserProvider).maybeWhen(data: (v) => v, orElse: () => false);

    return AdminShellLayout(
      title: 'User Management',
      isAdminUser: isAdminUser,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Search by email or name (optional)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isFiltering
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _load();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(onPressed: () => _load(), child: const Text('Search')),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : () => _load(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          'Failed to load users: $_error',
                          style: AppFonts.plusJakarta(color: tokens.textSecondary),
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: Text(
                              'No users found',
                              style: AppFonts.plusJakarta(color: tokens.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: _users.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              if (index == _users.length) {
                                return Center(
                                  child: _loading
                                      ? const Padding(
                                          padding: EdgeInsets.all(AppSpacing.sm),
                                          child: CircularProgressIndicator(),
                                        )
                                      : TextButton(
                                          onPressed: () => _load(loadMore: true),
                                          child: const Text('Load more'),
                                        ),
                                );
                              }
                              return _UserCard(
                                user: _users[index],
                                onChanged: () => _load(),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final AdminUserSearchResult user;
  final VoidCallback onChanged;
  const _UserCard({required this.user, required this.onChanged});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user permanently?'),
        content: Text(
          'This will permanently delete ${user.email}. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(adminUserModerationServiceProvider).deleteUser(user.uid);
    onChanged();
  }

  Future<void> _warnUser(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Issue warning'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Warning message',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send warning'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || message.isEmpty) return;
    await ref.read(adminUserModerationServiceProvider).warnUser(user.uid, message: message);
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(adminUserModerationServiceProvider);
    final status = user.accountStatus;
    final isVerified = user.verificationStatus == VerificationConstants.statusApproved;

    Color statusColor;
    switch (status) {
      case AdminConstants.accountStatusBanned:
        statusColor = Colors.red;
      case AdminConstants.accountStatusSuspended:
        statusColor = Colors.orange;
      default:
        statusColor = Colors.green;
    }

    final tokens = context.tokens;
    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.displayName ?? user.email,
            style: AppFonts.plusJakarta(fontWeight: FontWeight.w700, color: tokens.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            user.email,
            style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              StatusBadge(label: status, color: statusColor),
              if (isVerified) ...[
                const SizedBox(width: 6),
                const StatusBadge(label: 'Verified', color: Colors.green, icon: Icons.verified_user),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
                ActionChip(
                  avatar: const Icon(Icons.warning_amber_outlined, size: 16),
                  label: const Text('Warn'),
                  onPressed: () => _warnUser(context, ref),
                ),
                if (status != AdminConstants.accountStatusSuspended)
                  ActionChip(
                    avatar: const Icon(Icons.pause_circle_outline, size: 16),
                    label: const Text('Suspend'),
                    onPressed: () async {
                      await service.suspendUser(user.uid);
                      onChanged();
                    },
                  ),
                if (status != AdminConstants.accountStatusBanned)
                  ActionChip(
                    avatar: const Icon(Icons.block, size: 16),
                    label: const Text('Ban'),
                    onPressed: () async {
                      await service.banUser(user.uid);
                      onChanged();
                    },
                  ),
                if (status != AdminConstants.accountStatusActive)
                  ActionChip(
                    avatar: const Icon(Icons.restore, size: 16),
                    label: const Text('Restore'),
                    onPressed: () async {
                      await service.restoreAccount(user.uid);
                      onChanged();
                    },
                  ),
                if (!isVerified)
                  ActionChip(
                    avatar: const Icon(Icons.verified_user, size: 16),
                    label: const Text('Verify Student'),
                    onPressed: () async {
                      await service.verifyStudentManually(user.uid);
                      onChanged();
                    },
                  ),
                ActionChip(
                  avatar: const Icon(Icons.delete_forever, size: 16),
                  label: const Text('Delete'),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ],
        ),
    );
  }
}


