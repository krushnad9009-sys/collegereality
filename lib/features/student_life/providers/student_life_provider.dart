import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../models/student_life_models.dart';
import '../repositories/student_life_repository.dart';
import '../services/firestore_student_life_service.dart';
import '../utils/student_life_filter_utils.dart';

final firestoreStudentLifeServiceProvider = Provider<FirestoreStudentLifeService>((ref) {
  return FirestoreStudentLifeService();
});

final studentLifeRepositoryProvider = Provider<StudentLifeRepository>((ref) {
  return StudentLifeRepositoryImpl(ref.watch(firestoreStudentLifeServiceProvider));
});

final studentLifeSeedProvider = FutureProvider<void>((ref) async {
  await ref.watch(studentLifeRepositoryProvider).ensureSeeded();
});

final eventsProvider = StreamProvider<List<CampusEventModel>>((ref) async* {
  await ref.watch(studentLifeSeedProvider.future);
  yield* ref.watch(studentLifeRepositoryProvider).watchEvents();
});

final clubsProvider = StreamProvider<List<StudentClubModel>>((ref) async* {
  await ref.watch(studentLifeSeedProvider.future);
  yield* ref.watch(studentLifeRepositoryProvider).watchClubs();
});

final competitionsProvider = StreamProvider<List<CompetitionModel>>((ref) async* {
  await ref.watch(studentLifeSeedProvider.future);
  yield* ref.watch(studentLifeRepositoryProvider).watchCompetitions();
});

final studentCommunitiesProvider = StreamProvider<List<StudentCommunityModel>>((ref) async* {
  await ref.watch(studentLifeSeedProvider.future);
  yield* ref.watch(studentLifeRepositoryProvider).watchCommunities();
});

class EventFilterState {
  final String searchQuery;
  final String? category;
  final bool upcomingOnly;

  const EventFilterState({
    this.searchQuery = '',
    this.category,
    this.upcomingOnly = true,
  });

  EventFilterState copyWith({
    String? searchQuery,
    String? category,
    bool? upcomingOnly,
    bool clearCategory = false,
  }) {
    return EventFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : (category ?? this.category),
      upcomingOnly: upcomingOnly ?? this.upcomingOnly,
    );
  }
}

class EventFilterNotifier extends StateNotifier<EventFilterState> {
  EventFilterNotifier() : super(const EventFilterState());
  void update(EventFilterState next) => state = next;
}

final eventFilterProvider =
    StateNotifierProvider<EventFilterNotifier, EventFilterState>(
  (ref) => EventFilterNotifier(),
);

final filteredEventsProvider = Provider<AsyncValue<List<CampusEventModel>>>((ref) {
  final filters = ref.watch(eventFilterProvider);
  return ref.watch(eventsProvider).whenData(
        (items) => filterEvents(
          items: items,
          searchQuery: filters.searchQuery,
          category: filters.category,
          upcomingOnly: filters.upcomingOnly,
        ),
      );
});

class ClubFilterState {
  final String searchQuery;
  final String? clubType;

  const ClubFilterState({this.searchQuery = '', this.clubType});

  ClubFilterState copyWith({String? searchQuery, String? clubType, bool clearType = false}) {
    return ClubFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      clubType: clearType ? null : (clubType ?? this.clubType),
    );
  }
}

class ClubFilterNotifier extends StateNotifier<ClubFilterState> {
  ClubFilterNotifier() : super(const ClubFilterState());
  void update(ClubFilterState next) => state = next;
}

final clubFilterProvider =
    StateNotifierProvider<ClubFilterNotifier, ClubFilterState>(
  (ref) => ClubFilterNotifier(),
);

final filteredClubsProvider = Provider<AsyncValue<List<StudentClubModel>>>((ref) {
  final filters = ref.watch(clubFilterProvider);
  return ref.watch(clubsProvider).whenData(
        (items) => filterClubs(
          items: items,
          searchQuery: filters.searchQuery,
          clubType: filters.clubType,
        ),
      );
});

class CompetitionFilterState {
  final String searchQuery;
  final String? scope;
  final bool openOnly;

  const CompetitionFilterState({
    this.searchQuery = '',
    this.scope,
    this.openOnly = false,
  });

  CompetitionFilterState copyWith({
    String? searchQuery,
    String? scope,
    bool? openOnly,
    bool clearScope = false,
  }) {
    return CompetitionFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      scope: clearScope ? null : (scope ?? this.scope),
      openOnly: openOnly ?? this.openOnly,
    );
  }
}

class CompetitionFilterNotifier extends StateNotifier<CompetitionFilterState> {
  CompetitionFilterNotifier() : super(const CompetitionFilterState());
  void update(CompetitionFilterState next) => state = next;
}

final competitionFilterProvider =
    StateNotifierProvider<CompetitionFilterNotifier, CompetitionFilterState>(
  (ref) => CompetitionFilterNotifier(),
);

final filteredCompetitionsProvider =
    Provider<AsyncValue<List<CompetitionModel>>>((ref) {
  final filters = ref.watch(competitionFilterProvider);
  return ref.watch(competitionsProvider).whenData(
        (items) => filterCompetitions(
          items: items,
          searchQuery: filters.searchQuery,
          scope: filters.scope,
          openRegistrationOnly: filters.openOnly,
        ),
      );
});

class CommunityFilterState {
  final String searchQuery;
  final String? communityType;

  const CommunityFilterState({this.searchQuery = '', this.communityType});

  CommunityFilterState copyWith({
    String? searchQuery,
    String? communityType,
    bool clearType = false,
  }) {
    return CommunityFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      communityType: clearType ? null : (communityType ?? this.communityType),
    );
  }
}

class CommunityFilterNotifier extends StateNotifier<CommunityFilterState> {
  CommunityFilterNotifier() : super(const CommunityFilterState());
  void update(CommunityFilterState next) => state = next;
}

final communityFilterProvider =
    StateNotifierProvider<CommunityFilterNotifier, CommunityFilterState>(
  (ref) => CommunityFilterNotifier(),
);

final filteredCommunitiesProvider =
    Provider<AsyncValue<List<StudentCommunityModel>>>((ref) {
  final filters = ref.watch(communityFilterProvider);
  return ref.watch(studentCommunitiesProvider).whenData(
        (items) => filterCommunities(
          items: items,
          searchQuery: filters.searchQuery,
          communityType: filters.communityType,
        ),
      );
});

final savedEventIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value({});
  return ref.watch(studentLifeRepositoryProvider).watchSavedEventIds(user.uid);
});

final registeredEventIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value({});
  return ref.watch(studentLifeRepositoryProvider).watchRegisteredEventIds(user.uid);
});

final clubJoinStatusesProvider = StreamProvider<Map<String, String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value({});
  return ref.watch(studentLifeRepositoryProvider).watchClubJoinStatuses(user.uid);
});

final isVerifiedForStudentLifeProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return false;
  return ref.watch(studentLifeRepositoryProvider).isUserVerified(user.uid);
});

final eventByIdProvider =
    FutureProvider.family<CampusEventModel?, String>((ref, id) async {
  await ref.watch(studentLifeSeedProvider.future);
  return ref.watch(studentLifeRepositoryProvider).getEventById(id);
});

final clubByIdProvider =
    FutureProvider.family<StudentClubModel?, String>((ref, id) async {
  await ref.watch(studentLifeSeedProvider.future);
  return ref.watch(studentLifeRepositoryProvider).getClubById(id);
});

final competitionByIdProvider =
    FutureProvider.family<CompetitionModel?, String>((ref, id) async {
  await ref.watch(studentLifeSeedProvider.future);
  return ref.watch(studentLifeRepositoryProvider).getCompetitionById(id);
});

final communityByIdProvider =
    FutureProvider.family<StudentCommunityModel?, String>((ref, id) async {
  await ref.watch(studentLifeSeedProvider.future);
  return ref.watch(studentLifeRepositoryProvider).getCommunityById(id);
});

final communityPostsProvider =
    StreamProvider.family<List<StudentCommunityPostModel>, String>((ref, communityId) {
  return ref.watch(studentLifeRepositoryProvider).watchCommunityPosts(communityId);
});

final postCommentsProvider =
    StreamProvider.family<List<StudentCommunityCommentModel>, String>((ref, postId) {
  return ref.watch(studentLifeRepositoryProvider).watchPostComments(postId);
});

final postReportsAdminProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(studentLifeRepositoryProvider).watchOpenPostReports();
});

final commentReportsAdminProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(studentLifeRepositoryProvider).watchOpenCommentReports();
});

final currentUserDetailForStudentLifeProvider = Provider((ref) {
  return ref.watch(currentUserDetailProvider);
});
