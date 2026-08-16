import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/constants/role_constants.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/premium_list_row.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../models/admin_models.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_provider.dart';
import '../utils/admin_permissions.dart';
import '../widgets/admin_shell_layout.dart';

final adminStaffUsersProvider =
    FutureProvider.autoDispose<List<AdminUserSearchResult>>((ref) async {
  return ref.watch(adminUserModerationServiceProvider).listStaffUsers();
});

/// Super Admin screen to assign staff roles (moderator / admin / super_admin).
class AdminRolesScreen extends ConsumerWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(currentUserModelProvider).valueOrNull;
    final canManage = AdminPermissions.canManageRoles(actor?.userType);
    final staffAsync = ref.watch(adminStaffUsersProvider);
    final tokens = context.tokens;

    return AdminShellLayout(
      title: 'Roles & Permissions',
      isAdminUser: true,
      child: !canManage
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Only Super Admins can manage roles.'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Staff directory',
                  style: AppFonts.plusJakarta(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Assign moderator, admin, or super admin roles. Every change is audit-logged.',
                  style: AppFonts.plusJakarta(color: tokens.textSecondary),
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permission matrix',
                        style: AppFonts.plusJakarta(
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Moderator — content moderation & analytics',
                        style: AppFonts.plusJakarta(fontSize: 13, color: tokens.textSecondary),
                      ),
                      Text(
                        '• Admin — colleges, users, verification, export, broadcasts',
                        style: AppFonts.plusJakarta(fontSize: 13, color: tokens.textSecondary),
                      ),
                      Text(
                        '• Super Admin — roles, ads, settings, merge colleges, review edits',
                        style: AppFonts.plusJakarta(fontSize: 13, color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                staffAsync.when(
                  loading: () => const AsyncLoadingView(),
                  error: (e, _) => AsyncErrorView.fromError(e),
                  data: (users) {
                    if (users.isEmpty) {
                      return Text(
                        'No staff users found. Promote a user from User Management.',
                        style: AppFonts.plusJakarta(color: tokens.textSecondary),
                      );
                    }
                    return Column(
                      children: users
                          .map(
                            (u) => _RoleCard(
                              user: u,
                              actorUserType: actor?.userType,
                              onChanged: () =>
                                  ref.invalidate(adminStaffUsersProvider),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _RoleCard extends ConsumerWidget {
  final AdminUserSearchResult user;
  final String? actorUserType;
  final VoidCallback onChanged;

  const _RoleCard({
    required this.user,
    required this.actorUserType,
    required this.onChanged,
  });

  Future<void> _changeRole(BuildContext context, WidgetRef ref) async {
    final roles = AdminPermissions.assignableRoles(actorUserType);
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Set role for ${user.email}'),
        children: roles
            .map(
              (role) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, role),
                child: Text(RoleConstants.label(role)),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || actorUserType == null) return;
    try {
      await ref.read(adminUserModerationServiceProvider).setUserRole(
            uid: user.uid,
            newRole: selected,
            actorUserType: actorUserType!,
          );
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated to ${RoleConstants.label(selected)}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumCard(
        padding: EdgeInsets.zero,
        child: PremiumListRow(
          leadingIcon: Icons.person_outline,
          title: user.displayName ?? user.email,
          subtitle: '${user.email}\n${RoleConstants.label(user.userType)}',
          showChevron: false,
          trailing: FilledButton.tonal(
            onPressed: () => _changeRole(context, ref),
            child: const Text('Change role'),
          ),
        ),
      ),
    );
  }
}
