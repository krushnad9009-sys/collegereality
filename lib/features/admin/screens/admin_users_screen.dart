import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
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

  // null = All, true = Verified only, false = Unverified only.
  bool? _verifiedFilter;

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
        var results = await ref.read(adminUserSearchProvider(query).future);
        // searchUsers() has no server-side verified filter of its own (it's
        // already a small, bounded in-memory list, capped at
        // AdminConstants.maxSearchUsers) -- filter client-side instead of
        // adding one.
        if (_verifiedFilter != null) {
          results = results
              .where((u) =>
                  VerificationConstants.isApprovedStudentOrAlumni(
                    u.verificationBadge,
                    u.verificationStatus,
                  ) ==
                  _verifiedFilter)
              .toList();
        }
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
          AdminUserPageParams(
            startAfterDocumentId: loadMore ? _cursor : null,
            verifiedFilter: _verifiedFilter,
          ),
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DropdownButton<bool?>(
                value: _verifiedFilter,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: true, child: Text('Verified Only')),
                  DropdownMenuItem(value: false, child: Text('Unverified Only')),
                ],
                onChanged: _loading
                    ? null
                    : (value) {
                        setState(() => _verifiedFilter = value);
                        _load();
                      },
              ),
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
    final isVerified = VerificationConstants.isApprovedStudentOrAlumni(
      user.verificationBadge,
      user.verificationStatus,
    );

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
          Row(
            children: [
              _UserAvatar(photoURL: user.photoURL, name: user.displayName ?? user.email),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email,
                      style: AppFonts.plusJakarta(fontWeight: FontWeight.w700, color: tokens.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              StatusBadge(label: status, color: statusColor),
              const SizedBox(width: 6),
              isVerified
                  ? const StatusBadge(
                      label: 'Verified',
                      color: AppTheme.verifiedBlue,
                      icon: Icons.verified,
                    )
                  : StatusBadge(
                      label: 'Unverified',
                      color: Colors.grey.shade500,
                      icon: Icons.remove_circle_outline,
                    ),
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
                ActionChip(
                  avatar: Icon(
                    isVerified ? Icons.remove_circle_outline : Icons.verified,
                    size: 16,
                    color: isVerified ? null : AppTheme.verifiedBlue,
                  ),
                  label: Text(
                    isVerified ? 'Revoke Verified Badge' : 'Grant Verified Badge',
                  ),
                  onPressed: () async {
                    await service.setStudentVerified(
                      user.uid,
                      verified: !isVerified,
                    );
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

/// Lightweight cached circular avatar for the user list -- decodes at the
/// display size (memCacheWidth/Height), not full resolution, and falls
/// back to initials on a missing photoURL or a failed/slow load rather
/// than leaving a blank circle or blocking the row on the image.
class _UserAvatar extends StatelessWidget {
  static const double _radius = 18;

  final String? photoURL;
  final String name;

  const _UserAvatar({required this.photoURL, required this.name});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final url = photoURL;
    if (url == null || url.isEmpty) {
      // Solid, non-muted background here (unlike the has-a-URL branch
      // below) since this is the only content in the circle -- white
      // initials need real contrast, not the page's muted surface tint.
      return CircleAvatar(radius: _radius, backgroundColor: AppTheme.primaryColor, child: _initials());
    }
    return CircleAvatar(
      radius: _radius,
      backgroundColor: tokens.surfaceMuted,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: _radius * 2,
          height: _radius * 2,
          fit: BoxFit.cover,
          memCacheWidth: (_radius * 2 * 2).round(),
          placeholder: (_, _) => _initials(),
          errorWidget: (_, _, _) => _initials(),
        ),
      ),
    );
  }

  Widget _initials() {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
    return Text(initial, style: AppFonts.plusJakarta(fontWeight: FontWeight.w700, color: Colors.white));
  }
}


