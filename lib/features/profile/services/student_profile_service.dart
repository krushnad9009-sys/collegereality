import '../../auth/models/user_model.dart';
import '../../auth/services/firestore_user_service.dart';
import '../models/premium_student_profile.dart';

class StudentProfileService {
  final FirestoreUserService _userService = FirestoreUserService();

  Future<PremiumStudentProfile?> getPublicProfile(String uid) async {
    final user = await _userService.getUserByUID(uid);
    if (user == null) return null;
    return PremiumStudentProfile.fromUser(user);
  }

  Stream<PremiumStudentProfile?> watchPublicProfile(String uid) {
    return _userService.getUserStream(uid).map((user) {
      if (user == null) return null;
      return PremiumStudentProfile.fromUser(user);
    });
  }
}
