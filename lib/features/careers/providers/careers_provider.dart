import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../models/careers_models.dart';
import '../repositories/careers_repository.dart';
import '../services/firestore_careers_service.dart';
import '../utils/careers_filter_utils.dart';

final firestoreCareersServiceProvider = Provider<FirestoreCareersService>((ref) {
  return FirestoreCareersService();
});

final careersRepositoryProvider = Provider<CareersRepository>((ref) {
  return CareersRepositoryImpl(ref.watch(firestoreCareersServiceProvider));
});

final careersSeedProvider = FutureProvider<void>((ref) async {
  await ref.watch(careersRepositoryProvider).ensureSeeded();
});

final internshipsProvider = StreamProvider<List<InternshipModel>>((ref) async* {
  await ref.watch(careersSeedProvider.future);
  yield* ref.watch(careersRepositoryProvider).watchInternships();
});

final jobsProvider = StreamProvider<List<JobModel>>((ref) async* {
  await ref.watch(careersSeedProvider.future);
  yield* ref.watch(careersRepositoryProvider).watchJobs();
});

final companiesProvider = StreamProvider<List<CompanyModel>>((ref) async* {
  await ref.watch(careersSeedProvider.future);
  yield* ref.watch(careersRepositoryProvider).watchCompanies();
});

final alumniProfilesProvider = StreamProvider<List<AlumniProfileModel>>((ref) async* {
  await ref.watch(careersSeedProvider.future);
  yield* ref.watch(careersRepositoryProvider).watchAlumniProfiles();
});

class InternshipFilterState {
  final String searchQuery;
  final String? city;
  final String? company;
  final String? payType;

  const InternshipFilterState({
    this.searchQuery = '',
    this.city,
    this.company,
    this.payType,
  });

  InternshipFilterState copyWith({
    String? searchQuery,
    String? city,
    String? company,
    String? payType,
    bool clearCity = false,
    bool clearCompany = false,
    bool clearPayType = false,
  }) {
    return InternshipFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      city: clearCity ? null : (city ?? this.city),
      company: clearCompany ? null : (company ?? this.company),
      payType: clearPayType ? null : (payType ?? this.payType),
    );
  }
}

class InternshipFilterNotifier extends StateNotifier<InternshipFilterState> {
  InternshipFilterNotifier() : super(const InternshipFilterState());
  void update(InternshipFilterState next) => state = next;
}

final internshipFilterProvider =
    StateNotifierProvider<InternshipFilterNotifier, InternshipFilterState>(
  (ref) => InternshipFilterNotifier(),
);

final filteredInternshipsProvider = Provider<AsyncValue<List<InternshipModel>>>((ref) {
  final filters = ref.watch(internshipFilterProvider);
  return ref.watch(internshipsProvider).whenData((items) {
    return filterInternships(
      items: items,
      searchQuery: filters.searchQuery,
      city: filters.city,
      company: filters.company,
      payType: filters.payType,
    );
  });
});

class JobFilterState {
  final String searchQuery;
  final String? location;
  final String? jobLevel;
  final String? workType;
  final double? minSalaryLpa;

  const JobFilterState({
    this.searchQuery = '',
    this.location,
    this.jobLevel,
    this.workType,
    this.minSalaryLpa,
  });

  JobFilterState copyWith({
    String? searchQuery,
    String? location,
    String? jobLevel,
    String? workType,
    double? minSalaryLpa,
    bool clearLocation = false,
    bool clearLevel = false,
    bool clearWorkType = false,
    bool clearSalary = false,
  }) {
    return JobFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      location: clearLocation ? null : (location ?? this.location),
      jobLevel: clearLevel ? null : (jobLevel ?? this.jobLevel),
      workType: clearWorkType ? null : (workType ?? this.workType),
      minSalaryLpa: clearSalary ? null : (minSalaryLpa ?? this.minSalaryLpa),
    );
  }
}

class JobFilterNotifier extends StateNotifier<JobFilterState> {
  JobFilterNotifier() : super(const JobFilterState());
  void update(JobFilterState next) => state = next;
}

final jobFilterProvider =
    StateNotifierProvider<JobFilterNotifier, JobFilterState>(
  (ref) => JobFilterNotifier(),
);

final filteredJobsProvider = Provider<AsyncValue<List<JobModel>>>((ref) {
  final filters = ref.watch(jobFilterProvider);
  return ref.watch(jobsProvider).whenData((items) {
    return filterJobs(
      items: items,
      searchQuery: filters.searchQuery,
      location: filters.location,
      jobLevel: filters.jobLevel,
      workType: filters.workType,
      minSalaryLpa: filters.minSalaryLpa,
    );
  });
});

class CompanySearchNotifier extends StateNotifier<String> {
  CompanySearchNotifier() : super('');
  void set(String q) => state = q;
}

final companySearchProvider = StateNotifierProvider<CompanySearchNotifier, String>(
  (ref) => CompanySearchNotifier(),
);

final filteredCompaniesProvider = Provider<AsyncValue<List<CompanyModel>>>((ref) {
  final query = ref.watch(companySearchProvider);
  return ref.watch(companiesProvider).whenData(
        (items) => filterCompanies(items: items, searchQuery: query),
      );
});

class AlumniSearchNotifier extends StateNotifier<String> {
  AlumniSearchNotifier() : super('');
  void set(String q) => state = q;
}

final alumniSearchProvider = StateNotifierProvider<AlumniSearchNotifier, String>(
  (ref) => AlumniSearchNotifier(),
);

final filteredAlumniProvider = Provider<AsyncValue<List<AlumniProfileModel>>>((ref) {
  final query = ref.watch(alumniSearchProvider);
  return ref.watch(alumniProfilesProvider).whenData(
        (items) => filterAlumni(items: items, searchQuery: query),
      );
});

final savedInternshipIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value({});
  return ref.watch(careersRepositoryProvider).watchSavedInternshipIds(user.uid);
});

final savedJobIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value({});
  return ref.watch(careersRepositoryProvider).watchSavedJobIds(user.uid);
});

final followedAlumniIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value({});
  return ref.watch(careersRepositoryProvider).watchFollowedAlumniIds(user.uid);
});

final companyReviewsProvider =
    StreamProvider.family<List<CompanyReviewModel>, String>((ref, companyId) {
  return ref.watch(careersRepositoryProvider).watchCompanyReviews(companyId);
});

final isVerifiedForCompanyReviewProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return false;
  return ref.watch(careersRepositoryProvider).isUserVerified(user.uid);
});

final companyByIdProvider =
    FutureProvider.family<CompanyModel?, String>((ref, id) async {
  await ref.watch(careersSeedProvider.future);
  return ref.watch(careersRepositoryProvider).getCompanyById(id);
});

final alumniByIdProvider =
    FutureProvider.family<AlumniProfileModel?, String>((ref, id) async {
  await ref.watch(careersSeedProvider.future);
  return ref.watch(careersRepositoryProvider).getAlumniById(id);
});

final currentUserDetailForCareersProvider = Provider((ref) {
  return ref.watch(currentUserDetailProvider);
});
