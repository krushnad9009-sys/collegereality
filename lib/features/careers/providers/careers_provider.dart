import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../models/careers_models.dart';
import '../repositories/careers_repository.dart';
import '../services/firestore_careers_service.dart';
import '../services/resume_storage_service.dart';
import '../utils/careers_filter_utils.dart';
import '../utils/careers_matching_utils.dart';

final firestoreCareersServiceProvider = Provider<FirestoreCareersService>((ref) {
  return FirestoreCareersService();
});

final resumeStorageServiceProvider = Provider<ResumeStorageService>((ref) {
  return ResumeStorageService();
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
  final bool workFromHome;
  final int? minStipend;
  final String? durationBucket;

  const InternshipFilterState({
    this.searchQuery = '',
    this.city,
    this.company,
    this.payType,
    this.workFromHome = false,
    this.minStipend,
    this.durationBucket,
  });

  InternshipFilterState copyWith({
    String? searchQuery,
    String? city,
    String? company,
    String? payType,
    bool? workFromHome,
    int? minStipend,
    String? durationBucket,
    bool clearCity = false,
    bool clearCompany = false,
    bool clearPayType = false,
    bool clearStipend = false,
    bool clearDuration = false,
  }) {
    return InternshipFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      city: clearCity ? null : (city ?? this.city),
      company: clearCompany ? null : (company ?? this.company),
      payType: clearPayType ? null : (payType ?? this.payType),
      workFromHome: workFromHome ?? this.workFromHome,
      minStipend: clearStipend ? null : (minStipend ?? this.minStipend),
      durationBucket: clearDuration ? null : (durationBucket ?? this.durationBucket),
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
      workFromHome: filters.workFromHome ? true : null,
      minStipend: filters.minStipend,
      durationBucket: filters.durationBucket,
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

final studentResumeProvider = StreamProvider<StudentResumeModel?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(careersRepositoryProvider).watchStudentResume(user.uid);
});

final companyAccountProvider = StreamProvider<CompanyAccountModel?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(careersRepositoryProvider).watchCompanyAccount(user.uid);
});

final recommendedJobsProvider = Provider<AsyncValue<List<CareerMatchResult<JobModel>>>>((ref) {
  final jobsAsync = ref.watch(jobsProvider);
  final userAsync = ref.watch(currentUserDetailProvider);
  return jobsAsync.whenData((jobs) {
    final user = userAsync.valueOrNull;
    final skills = [
      ...?user?.interests,
      ...?ref.watch(studentResumeProvider).valueOrNull?.extractedSkills,
    ];
    return recommendJobs(
      jobs: jobs,
      degree: user?.course,
      branch: user?.branch,
      skills: skills,
    );
  });
});

final recommendedInternshipsProvider =
    Provider<AsyncValue<List<CareerMatchResult<InternshipModel>>>>((ref) {
  final internshipsAsync = ref.watch(internshipsProvider);
  final userAsync = ref.watch(currentUserDetailProvider);
  return internshipsAsync.whenData((internships) {
    final user = userAsync.valueOrNull;
    final skills = [
      ...?user?.interests,
      ...?ref.watch(studentResumeProvider).valueOrNull?.extractedSkills,
    ];
    return recommendInternships(internships: internships, skills: skills);
  });
});

final careerSuggestionsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final jobsAsync = ref.watch(jobsProvider);
  final internshipsAsync = ref.watch(internshipsProvider);
  final userAsync = ref.watch(currentUserDetailProvider);
  if (jobsAsync.isLoading || internshipsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  final user = userAsync.valueOrNull;
  final skills = [
    ...?user?.interests,
    ...?ref.watch(studentResumeProvider).valueOrNull?.extractedSkills,
  ];
  return AsyncValue.data(
    generateCareerSuggestions(
      degree: user?.course,
      branch: user?.branch,
      skills: skills,
      jobs: jobsAsync.valueOrNull ?? [],
      internships: internshipsAsync.valueOrNull ?? [],
    ),
  );
});

class PaginatedInternshipsState {
  final List<InternshipModel> items;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  const PaginatedInternshipsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDoc,
  });

  PaginatedInternshipsState copyWith({
    List<InternshipModel>? items,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
  }) {
    return PaginatedInternshipsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}

class PaginatedInternshipsNotifier extends StateNotifier<PaginatedInternshipsState> {
  PaginatedInternshipsNotifier(this._repo) : super(const PaginatedInternshipsState());

  final CareersRepository _repo;

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, items: []);
    final page = await _repo.fetchInternshipsPage();
    state = PaginatedInternshipsState(
      items: page.items,
      hasMore: page.hasMore,
      lastDoc: page.lastDocument,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final page = await _repo.fetchInternshipsPage(startAfter: state.lastDoc);
    state = state.copyWith(
      items: [...state.items, ...page.items],
      hasMore: page.hasMore,
      lastDoc: page.lastDocument,
      isLoading: false,
    );
  }
}

final paginatedInternshipsProvider =
    StateNotifierProvider<PaginatedInternshipsNotifier, PaginatedInternshipsState>((ref) {
  return PaginatedInternshipsNotifier(ref.watch(careersRepositoryProvider));
});

class PaginatedJobsState {
  final List<JobModel> items;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  const PaginatedJobsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDoc,
  });

  PaginatedJobsState copyWith({
    List<JobModel>? items,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
  }) {
    return PaginatedJobsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}

class PaginatedJobsNotifier extends StateNotifier<PaginatedJobsState> {
  PaginatedJobsNotifier(this._repo) : super(const PaginatedJobsState());

  final CareersRepository _repo;

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, items: []);
    final page = await _repo.fetchJobsPage();
    state = PaginatedJobsState(
      items: page.items,
      hasMore: page.hasMore,
      lastDoc: page.lastDocument,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final page = await _repo.fetchJobsPage(startAfter: state.lastDoc);
    state = state.copyWith(
      items: [...state.items, ...page.items],
      hasMore: page.hasMore,
      lastDoc: page.lastDocument,
      isLoading: false,
    );
  }
}

final paginatedJobsProvider =
    StateNotifierProvider<PaginatedJobsNotifier, PaginatedJobsState>((ref) {
  return PaginatedJobsNotifier(ref.watch(careersRepositoryProvider));
});
