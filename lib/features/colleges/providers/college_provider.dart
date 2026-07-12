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

  const CollegeSearchParams({this.query, this.city, this.state});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollegeSearchParams &&
          query == other.query &&
          city == other.city &&
          state == other.state;

  @override
  int get hashCode => Object.hash(query, city, state);
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
