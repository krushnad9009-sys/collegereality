import '../models/careers_models.dart';
import '../services/firestore_careers_service.dart';

abstract class CareersRepository {
  Future<void> ensureSeeded();
  Stream<List<InternshipModel>> watchInternships();
  Stream<List<JobModel>> watchJobs();
  Stream<List<CompanyModel>> watchCompanies();
  Stream<List<AlumniProfileModel>> watchAlumniProfiles();
  Future<InternshipModel?> getInternshipById(String id);
  Future<JobModel?> getJobById(String id);
  Future<CompanyModel?> getCompanyById(String id);
  Future<AlumniProfileModel?> getAlumniById(String id);
  Stream<List<CompanyReviewModel>> watchCompanyReviews(String companyId);
  Future<bool> isUserVerified(String userId);
  Future<void> submitCompanyReview({
    required String companyId,
    required String userId,
    required String authorDisplayName,
    required double rating,
    required String textReview,
    required bool isVerifiedStudent,
  });
  Future<void> saveInternship(String userId, String internshipId);
  Future<void> unsaveInternship(String userId, String internshipId);
  Stream<Set<String>> watchSavedInternshipIds(String userId);
  Future<void> saveJob(String userId, String jobId);
  Future<void> unsaveJob(String userId, String jobId);
  Stream<Set<String>> watchSavedJobIds(String userId);
  Future<void> followAlumni(String followerId, String alumniId);
  Future<void> unfollowAlumni(String followerId, String alumniId);
  Stream<Set<String>> watchFollowedAlumniIds(String followerId);
  Future<void> applyInternship({
    required String userId,
    required String internshipId,
    required String companyId,
    String coverNote,
  });
  Future<void> applyJob({
    required String userId,
    required String jobId,
    required String companyId,
    String coverNote,
  });
}

class CareersRepositoryImpl implements CareersRepository {
  final FirestoreCareersService _service;
  CareersRepositoryImpl(this._service);

  @override
  Future<void> ensureSeeded() => _service.ensureSeeded();
  @override
  Stream<List<InternshipModel>> watchInternships() => _service.watchInternships();
  @override
  Stream<List<JobModel>> watchJobs() => _service.watchJobs();
  @override
  Stream<List<CompanyModel>> watchCompanies() => _service.watchCompanies();
  @override
  Stream<List<AlumniProfileModel>> watchAlumniProfiles() =>
      _service.watchAlumniProfiles();
  @override
  Future<InternshipModel?> getInternshipById(String id) =>
      _service.getInternshipById(id);
  @override
  Future<JobModel?> getJobById(String id) => _service.getJobById(id);
  @override
  Future<CompanyModel?> getCompanyById(String id) => _service.getCompanyById(id);
  @override
  Future<AlumniProfileModel?> getAlumniById(String id) =>
      _service.getAlumniById(id);
  @override
  Stream<List<CompanyReviewModel>> watchCompanyReviews(String companyId) =>
      _service.watchCompanyReviews(companyId);
  @override
  Future<bool> isUserVerified(String userId) => _service.isUserVerified(userId);
  @override
  Future<void> submitCompanyReview({
    required String companyId,
    required String userId,
    required String authorDisplayName,
    required double rating,
    required String textReview,
    required bool isVerifiedStudent,
  }) =>
      _service.submitCompanyReview(
        companyId: companyId,
        userId: userId,
        authorDisplayName: authorDisplayName,
        rating: rating,
        textReview: textReview,
        isVerifiedStudent: isVerifiedStudent,
      );
  @override
  Future<void> saveInternship(String userId, String internshipId) =>
      _service.saveInternship(userId, internshipId);
  @override
  Future<void> unsaveInternship(String userId, String internshipId) =>
      _service.unsaveInternship(userId, internshipId);
  @override
  Stream<Set<String>> watchSavedInternshipIds(String userId) =>
      _service.watchSavedInternshipIds(userId);
  @override
  Future<void> saveJob(String userId, String jobId) =>
      _service.saveJob(userId, jobId);
  @override
  Future<void> unsaveJob(String userId, String jobId) =>
      _service.unsaveJob(userId, jobId);
  @override
  Stream<Set<String>> watchSavedJobIds(String userId) =>
      _service.watchSavedJobIds(userId);
  @override
  Future<void> followAlumni(String followerId, String alumniId) =>
      _service.followAlumni(followerId, alumniId);
  @override
  Future<void> unfollowAlumni(String followerId, String alumniId) =>
      _service.unfollowAlumni(followerId, alumniId);
  @override
  Stream<Set<String>> watchFollowedAlumniIds(String followerId) =>
      _service.watchFollowedAlumniIds(followerId);
  @override
  Future<void> applyInternship({
    required String userId,
    required String internshipId,
    required String companyId,
    String coverNote = '',
  }) =>
      _service.applyInternship(
        userId: userId,
        internshipId: internshipId,
        companyId: companyId,
        coverNote: coverNote,
      );
  @override
  Future<void> applyJob({
    required String userId,
    required String jobId,
    required String companyId,
    String coverNote = '',
  }) =>
      _service.applyJob(
        userId: userId,
        jobId: jobId,
        companyId: companyId,
        coverNote: coverNote,
      );
}
