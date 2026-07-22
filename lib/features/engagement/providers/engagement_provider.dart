import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bootstrap/startup_bootstrap.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../config/router/app_router.dart';
import '../models/engagement_models.dart';
import '../repositories/engagement_repository.dart';
import '../services/firebase_messaging_service.dart';
import '../services/firestore_engagement_service.dart';
import '../utils/engagement_filter_utils.dart';

final firestoreEngagementServiceProvider = Provider<FirestoreEngagementService>((ref) {
  return FirestoreEngagementService();
});

final engagementRepositoryProvider = Provider<EngagementRepository>((ref) {
  return EngagementRepositoryImpl(ref.watch(firestoreEngagementServiceProvider));
});

final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService>((ref) {
  return FirebaseMessagingService(ref.watch(firestoreEngagementServiceProvider));
});

final engagementSeedProvider = FutureProvider<void>((ref) async {
  final ready = ref.watch(homeContentReadyProvider);
  if (!ready) return;
  await ref.watch(engagementRepositoryProvider).ensureSeeded();
});

final userNotificationsProvider = StreamProvider<List<UserNotificationModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  ref.watch(engagementSeedProvider);
  return ref.watch(engagementRepositoryProvider).watchUserNotifications(user.uid);
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(0);
  return ref.watch(engagementRepositoryProvider).watchUnreadCount(user.uid);
});

final notificationPreferencesProvider =
    StreamProvider<NotificationPreferencesModel>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream.value(NotificationPreferencesModel.defaults(''));
  }
  return ref.watch(engagementRepositoryProvider).watchPreferences(user.uid);
});

final admissionCalendarProvider =
    StreamProvider<List<AdmissionCalendarEventModel>>((ref) {
  ref.watch(engagementSeedProvider);
  return ref.watch(engagementRepositoryProvider).watchCalendarEvents();
});

final favoriteCollegeIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value({});
  return ref.watch(engagementRepositoryProvider).watchFavoriteCollegeIds(user.uid);
});

final savedExamIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value({});
  return ref.watch(engagementRepositoryProvider).watchSavedExamIds(user.uid);
});

final savedQuestionIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value({});
  return ref.watch(engagementRepositoryProvider).watchSavedQuestionIds(user.uid);
});

class NotificationFilterState {
  final String searchQuery;
  final String? category;
  final bool unreadOnly;

  const NotificationFilterState({
    this.searchQuery = '',
    this.category,
    this.unreadOnly = false,
  });

  NotificationFilterState copyWith({
    String? searchQuery,
    String? category,
    bool clearCategory = false,
    bool? unreadOnly,
  }) {
    return NotificationFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : (category ?? this.category),
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }
}

class NotificationFilterNotifier extends StateNotifier<NotificationFilterState> {
  NotificationFilterNotifier() : super(const NotificationFilterState());

  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setCategory(String? c) =>
      state = state.copyWith(category: c, clearCategory: c == null);
  void setUnreadOnly(bool v) => state = state.copyWith(unreadOnly: v);
}

final notificationFilterProvider =
    StateNotifierProvider<NotificationFilterNotifier, NotificationFilterState>(
  (ref) => NotificationFilterNotifier(),
);

final filteredNotificationsProvider =
    Provider<AsyncValue<List<UserNotificationModel>>>((ref) {
  final notificationsAsync = ref.watch(userNotificationsProvider);
  final filters = ref.watch(notificationFilterProvider);
  return notificationsAsync.whenData(
    (items) => filterNotifications(
      items: items,
      searchQuery: filters.searchQuery,
      category: filters.category,
      unreadOnly: filters.unreadOnly,
    ),
  );
});

class CalendarFilterState {
  final String searchQuery;
  final String? category;
  final bool upcomingOnly;

  const CalendarFilterState({
    this.searchQuery = '',
    this.category,
    this.upcomingOnly = true,
  });

  CalendarFilterState copyWith({
    String? searchQuery,
    String? category,
    bool clearCategory = false,
    bool? upcomingOnly,
  }) {
    return CalendarFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : (category ?? this.category),
      upcomingOnly: upcomingOnly ?? this.upcomingOnly,
    );
  }
}

class CalendarFilterNotifier extends StateNotifier<CalendarFilterState> {
  CalendarFilterNotifier() : super(const CalendarFilterState());

  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setCategory(String? c) =>
      state = state.copyWith(category: c, clearCategory: c == null);
  void setUpcomingOnly(bool v) => state = state.copyWith(upcomingOnly: v);
}

final calendarFilterProvider =
    StateNotifierProvider<CalendarFilterNotifier, CalendarFilterState>(
  (ref) => CalendarFilterNotifier(),
);

final filteredCalendarProvider =
    Provider<AsyncValue<List<AdmissionCalendarEventModel>>>((ref) {
  final calendarAsync = ref.watch(admissionCalendarProvider);
  final filters = ref.watch(calendarFilterProvider);
  return calendarAsync.whenData(
    (items) => filterCalendarEvents(
      items: items,
      searchQuery: filters.searchQuery,
      category: filters.category,
      upcomingOnly: filters.upcomingOnly,
    ),
  );
});

final engagementMessagingInitProvider = FutureProvider<void>((ref) async {
  final ready = ref.watch(homeContentReadyProvider);
  if (!ready) return;
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return;
  await ref.watch(firebaseMessagingServiceProvider).initialize(
        userId: user.uid,
        router: ref.read(appRouterProvider),
      );
});

final alertScanProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return;
  await ref.watch(engagementRepositoryProvider).runPersonalizedAlertScan(user.uid);
});
