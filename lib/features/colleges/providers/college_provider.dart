import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/college_model.dart';
import '../repositories/college_repository.dart';
import '../services/firestore_college_service.dart';

final firestoreCollegeServiceProvider =
    Provider<FirestoreCollegeService>((ref) {
  return FirestoreCollegeService();
});

final collegeRepositoryProvider = Provider<CollegeRepository>((ref) {
  return CollegeRepositoryImpl(ref.watch(firestoreCollegeServiceProvider));
});

final collegeSeederProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(collegeRepositoryProvider);
  await repository.seedCollegesIfNeeded();
});

final collegesProvider = FutureProvider<List<CollegeModel>>((ref) async {
  await ref.watch(collegeSeederProvider.future);
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.getColleges();
});

final collegesStreamProvider = StreamProvider<List<CollegeModel>>((ref) {
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.watchColleges();
});

final collegeByIdProvider =
    FutureProvider.family<CollegeModel?, String>((ref, id) async {
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.getCollegeById(id);
});

class CollegeSearchParams {
  final String? query;
  final String? city;
  final String? state;
  final String? course;

  const CollegeSearchParams({
    this.query,
    this.city,
    this.state,
    this.course,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollegeSearchParams &&
          query == other.query &&
          city == other.city &&
          state == other.state &&
          course == other.course;

  @override
  int get hashCode => Object.hash(query, city, state, course);
}

final collegeSearchProvider =
    FutureProvider.family<List<CollegeModel>, CollegeSearchParams>(
        (ref, params) async {
  await ref.watch(collegeSeederProvider.future);
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.search(
    query: params.query,
    city: params.city,
    state: params.state,
    course: params.course,
  );
});

final indianStatesProvider = FutureProvider<List<String>>((ref) async {
  final colleges = await ref.watch(collegesProvider.future);
  return colleges.map((c) => c.state).toSet().toList()..sort();
});

final indianCitiesProvider = FutureProvider<List<String>>((ref) async {
  final colleges = await ref.watch(collegesProvider.future);
  return colleges.map((c) => c.city).toSet().toList()..sort();
});

final indianCoursesProvider = FutureProvider<List<String>>((ref) async {
  final colleges = await ref.watch(collegesProvider.future);
  return colleges.expand((c) => c.courses).toSet().toList()..sort();
});
