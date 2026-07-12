import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/premium_student_profile.dart';
import '../services/student_profile_service.dart';

final studentProfileServiceProvider = Provider<StudentProfileService>((ref) {
  return StudentProfileService();
});

final premiumStudentProfileProvider =
    StreamProvider.family<PremiumStudentProfile?, String>((ref, uid) {
  return ref.watch(studentProfileServiceProvider).watchPublicProfile(uid);
});
