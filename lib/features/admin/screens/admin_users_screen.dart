import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../providers/admin_dashboard_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    setState(() => _query = _searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUserSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Search by email or name',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _search, child: const Text('Search')),
              ],
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Text(
                      'Enter an email or name to search users',
                      style: GoogleFonts.poppins(color: AppTheme.gray600),
                    ),
                  )
                : usersAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Search failed: $e')),
                    data: (users) {
                      if (users.isEmpty) {
                        return const Center(child: Text('No users found'));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _UserCard(
                          user: users[index],
                          onChanged: () => ref.invalidate(adminUserSearchProvider(_query)),
                        ),
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
  final dynamic user;
  final VoidCallback onChanged;
  const _UserCard({required this.user, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(adminUserModerationServiceProvider);
    final status = user.accountStatus as String;
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.displayName ?? user.email,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            Text(user.email, style: GoogleFonts.poppins(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(status, style: const TextStyle(fontSize: 11)),
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                ),
                if (isVerified)
                  const Chip(
                    label: Text('Verified', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (status != AdminConstants.accountStatusSuspended)
                  ActionChip(
                    avatar: const Icon(Icons.pause_circle_outline, size: 16),
                    label: const Text('Suspend'),
                    onPressed: () async {
                      await service.suspendUser(user.uid as String);
                      onChanged();
                    },
                  ),
                if (status != AdminConstants.accountStatusBanned)
                  ActionChip(
                    avatar: const Icon(Icons.block, size: 16),
                    label: const Text('Ban'),
                    onPressed: () async {
                      await service.banUser(user.uid as String);
                      onChanged();
                    },
                  ),
                if (status != AdminConstants.accountStatusActive)
                  ActionChip(
                    avatar: const Icon(Icons.restore, size: 16),
                    label: const Text('Restore'),
                    onPressed: () async {
                      await service.restoreAccount(user.uid as String);
                      onChanged();
                    },
                  ),
                if (!isVerified)
                  ActionChip(
                    avatar: const Icon(Icons.verified_user, size: 16),
                    label: const Text('Verify Student'),
                    onPressed: () async {
                      await service.verifyStudentManually(user.uid as String);
                      onChanged();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
