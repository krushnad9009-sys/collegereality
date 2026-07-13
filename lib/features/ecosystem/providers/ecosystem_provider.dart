import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/user_provider.dart';
import '../models/ecosystem_models.dart';
import '../services/audit_log_service.dart';
import '../services/ecosystem_firestore_service.dart';
import '../services/role_service.dart';

final ecosystemServiceProvider = Provider<EcosystemFirestoreService>((ref) {
  return EcosystemFirestoreService();
});

final auditLogServiceProvider = Provider<AuditLogService>((ref) {
  return AuditLogService();
});

final collegeAccountProvider = FutureProvider<CollegeAccountModel?>((ref) async {
  final user = ref.watch(currentUserDetailProvider).valueOrNull;
  if (user == null) return null;
  return ref.watch(ecosystemServiceProvider).getCollegeAccount(user.uid);
});

final userRoleProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(currentUserDetailProvider).valueOrNull;
  final account = ref.watch(collegeAccountProvider).valueOrNull;
  return RoleService.resolveRole(user: user, collegeAccount: account);
});

final pendingCollegeRequestsProvider =
    FutureProvider<List<CollegeRequestModel>>((ref) {
  return ref.watch(ecosystemServiceProvider).fetchCollegeRequests(
        status: 'pending_review',
      );
});

final pendingEditSuggestionsProvider =
    FutureProvider<List<CollegeEditSuggestionModel>>((ref) {
  return ref.watch(ecosystemServiceProvider).fetchEditSuggestions(
        status: 'pending_review',
      );
});

final pendingDataReportsProvider =
    FutureProvider<List<CollegeDataReportModel>>((ref) {
  return ref.watch(ecosystemServiceProvider).fetchDataReports(
        status: 'pending_review',
      );
});

final pendingCollegeClaimsProvider =
    FutureProvider<List<CollegeClaimModel>>((ref) {
  return ref.watch(ecosystemServiceProvider).fetchCollegeClaims(
        status: 'pending_review',
      );
});

final pendingFacultyRequestsProvider =
    FutureProvider<List<FacultyVerificationRequestModel>>((ref) {
  return ref.watch(ecosystemServiceProvider).fetchFacultyRequests(
        status: 'pending_review',
      );
});

final collegeOfficialContentProvider = FutureProvider.family<
    List<CollegeOfficialContentModel>, ({String collegeId, String? section})>(
  (ref, params) {
    return ref.watch(ecosystemServiceProvider).fetchOfficialContent(
          collegeId: params.collegeId,
          section: params.section,
        );
  },
);

final collegeMentorshipOffersProvider =
    FutureProvider.family<List<AlumniMentorshipOfferModel>, String>(
  (ref, collegeId) {
    return ref.watch(ecosystemServiceProvider).fetchMentorshipOffers(collegeId);
  },
);

final collegeFacultyWorkshopsProvider =
    FutureProvider.family<List<FacultyWorkshopModel>, String>(
  (ref, collegeId) {
    return ref.watch(ecosystemServiceProvider).fetchWorkshops(collegeId);
  },
);

final auditLogsProvider = FutureProvider<List<AuditLogModel>>((ref) {
  return ref.watch(auditLogServiceProvider).fetchPage();
});
