import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/admission_prediction_model.dart';
import '../models/cutoff_record_model.dart';
import '../models/entrance_exam_model.dart';
import '../models/scholarship_model.dart';
import '../repositories/admission_repository.dart';
import '../services/firestore_admission_service.dart';
import '../utils/admission_utils.dart';

final firestoreAdmissionServiceProvider = Provider<FirestoreAdmissionService>((ref) {
  return FirestoreAdmissionService();
});

final admissionRepositoryProvider = Provider<AdmissionRepository>((ref) {
  return AdmissionRepositoryImpl(ref.watch(firestoreAdmissionServiceProvider));
});

final admissionSeedProvider = FutureProvider<void>((ref) async {
  await ref.watch(admissionRepositoryProvider).ensureSeeded();
});

final scholarshipsProvider = StreamProvider<List<ScholarshipModel>>((ref) async* {
  await ref.watch(admissionSeedProvider.future);
  yield* ref.watch(admissionRepositoryProvider).watchScholarships();
});

final entranceExamsProvider = StreamProvider<List<EntranceExamModel>>((ref) async* {
  await ref.watch(admissionSeedProvider.future);
  yield* ref.watch(admissionRepositoryProvider).watchExams();
});

final cutoffsProvider = StreamProvider.family<List<CutoffRecordModel>, String?>(
  (ref, examId) async* {
    await ref.watch(admissionSeedProvider.future);
    yield* ref.watch(admissionRepositoryProvider).watchCutoffs(examId: examId);
  },
);

class ScholarshipFilterState {
  final String searchQuery;
  final String? providerType;
  final String? category;
  final String? state;
  final String? course;
  final double? maxIncomeLpa;

  const ScholarshipFilterState({
    this.searchQuery = '',
    this.providerType,
    this.category,
    this.state,
    this.course,
    this.maxIncomeLpa,
  });

  ScholarshipFilterState copyWith({
    String? searchQuery,
    String? providerType,
    String? category,
    String? state,
    String? course,
    double? maxIncomeLpa,
    bool clearProvider = false,
    bool clearCategory = false,
    bool clearState = false,
    bool clearCourse = false,
    bool clearIncome = false,
  }) {
    return ScholarshipFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      providerType: clearProvider ? null : (providerType ?? this.providerType),
      category: clearCategory ? null : (category ?? this.category),
      state: clearState ? null : (state ?? this.state),
      course: clearCourse ? null : (course ?? this.course),
      maxIncomeLpa: clearIncome ? null : (maxIncomeLpa ?? this.maxIncomeLpa),
    );
  }
}

class ScholarshipFilterNotifier extends StateNotifier<ScholarshipFilterState> {
  ScholarshipFilterNotifier() : super(const ScholarshipFilterState());

  void update(ScholarshipFilterState next) => state = next;
}

final scholarshipFilterProvider =
    StateNotifierProvider<ScholarshipFilterNotifier, ScholarshipFilterState>(
  (ref) => ScholarshipFilterNotifier(),
);

final filteredScholarshipsProvider = Provider<AsyncValue<List<ScholarshipModel>>>((ref) {
  final scholarshipsAsync = ref.watch(scholarshipsProvider);
  final filters = ref.watch(scholarshipFilterProvider);
  return scholarshipsAsync.whenData((scholarships) {
    return filterScholarships(
      scholarships: scholarships,
      searchQuery: filters.searchQuery,
      providerType: filters.providerType,
      category: filters.category,
      state: filters.state,
      course: filters.course,
      maxIncomeLpa: filters.maxIncomeLpa,
    );
  });
});

class ExamSearchNotifier extends StateNotifier<String> {
  ExamSearchNotifier() : super('');
  void setQuery(String q) => state = q;
}

final examSearchProvider = StateNotifierProvider<ExamSearchNotifier, String>(
  (ref) => ExamSearchNotifier(),
);

final filteredExamsProvider = Provider<AsyncValue<List<EntranceExamModel>>>((ref) {
  final examsAsync = ref.watch(entranceExamsProvider);
  final query = ref.watch(examSearchProvider);
  return examsAsync.whenData((exams) => filterExams(exams: exams, searchQuery: query));
});

class CutoffFilterState {
  final String collegeQuery;
  final String courseQuery;
  final String? state;
  final String? university;
  final String? category;
  final String? gender;
  final String? round;
  final String? examId;

  const CutoffFilterState({
    this.collegeQuery = '',
    this.courseQuery = '',
    this.state,
    this.university,
    this.category,
    this.gender,
    this.round,
    this.examId,
  });

  CutoffFilterState copyWith({
    String? collegeQuery,
    String? courseQuery,
    String? state,
    String? university,
    String? category,
    String? gender,
    String? round,
    String? examId,
  }) {
    return CutoffFilterState(
      collegeQuery: collegeQuery ?? this.collegeQuery,
      courseQuery: courseQuery ?? this.courseQuery,
      state: state ?? this.state,
      university: university ?? this.university,
      category: category ?? this.category,
      gender: gender ?? this.gender,
      round: round ?? this.round,
      examId: examId ?? this.examId,
    );
  }
}

class CutoffFilterNotifier extends StateNotifier<CutoffFilterState> {
  CutoffFilterNotifier() : super(const CutoffFilterState());
  void update(CutoffFilterState next) => state = next;
}

final cutoffFilterProvider =
    StateNotifierProvider<CutoffFilterNotifier, CutoffFilterState>(
  (ref) => CutoffFilterNotifier(),
);

final filteredCutoffsProvider = Provider<AsyncValue<List<CutoffRecordModel>>>((ref) {
  final filters = ref.watch(cutoffFilterProvider);
  final cutoffsAsync = ref.watch(cutoffsProvider(filters.examId));
  return cutoffsAsync.whenData((cutoffs) {
    return filterCutoffs(
      cutoffs: cutoffs,
      collegeQuery: filters.collegeQuery,
      courseQuery: filters.courseQuery,
      state: filters.state,
      university: filters.university,
      category: filters.category,
      gender: filters.gender,
      round: filters.round,
      examId: filters.examId,
    );
  });
});

final savedScholarshipIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value({});
  return ref.watch(admissionRepositoryProvider).watchSavedScholarshipIds(user.uid);
});

final userPredictionsProvider = StreamProvider<List<AdmissionPredictionModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(admissionRepositoryProvider).watchUserPredictions(user.uid);
});

final examByIdProvider =
    FutureProvider.family<EntranceExamModel?, String>((ref, examId) async {
  await ref.watch(admissionSeedProvider.future);
  return ref.watch(admissionRepositoryProvider).getExamById(examId);
});

final scholarshipByIdProvider =
    FutureProvider.family<ScholarshipModel?, String>((ref, id) async {
  await ref.watch(admissionSeedProvider.future);
  return ref.watch(admissionRepositoryProvider).getScholarshipById(id);
});
