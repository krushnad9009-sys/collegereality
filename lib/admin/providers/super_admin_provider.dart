import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admin/utils/admin_permissions.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/user_provider.dart';

final isSuperAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final userDetail = await ref.watch(userRepositoryProvider).getUser(user.uid);
  return AdminPermissions.isSuperAdmin(userDetail?.userType);
});
