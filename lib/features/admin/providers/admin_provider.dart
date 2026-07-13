import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';

final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final userDetail = await ref.watch(userRepositoryProvider).getUser(user.uid);
  return userDetail?.userType == 'admin' ||
      userDetail?.userType == 'super_admin';
});

final isStaffProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final userDetail = await ref.watch(userRepositoryProvider).getUser(user.uid);
  final type = userDetail?.userType ?? '';
  return type == 'admin' || type == 'super_admin' || type == 'moderator';
});

final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(userRepositoryProvider).getUser(user.uid);
});
