import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../utils/admin_permissions.dart';

final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final userDetail = await ref.watch(userRepositoryProvider).getUser(user.uid);
  return AdminPermissions.isAdmin(userDetail?.userType);
});

final isStaffProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final userDetail = await ref.watch(userRepositoryProvider).getUser(user.uid);
  return AdminPermissions.isStaff(userDetail?.userType);
});

final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(userRepositoryProvider).getUser(user.uid);
});

final isAdminUserProvider = FutureProvider<bool>((ref) async {
  final model = await ref.watch(currentUserModelProvider.future);
  return AdminPermissions.isAdmin(model?.userType);
});
