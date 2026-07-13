import '../models/student_life_models.dart';

String buildStudentLifeSearchText(List<String> parts) {
  return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join(' ').toLowerCase();
}

bool matchesStudentLifeSearch(String searchText, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return searchText.contains(q);
}

List<CampusEventModel> filterEvents({
  required List<CampusEventModel> items,
  required String searchQuery,
  String? category,
  bool upcomingOnly = false,
}) {
  return items.where((e) {
    if (!e.isActive) return false;
    if (upcomingOnly && !e.isUpcoming) return false;
    if (!matchesStudentLifeSearch(e.searchText, searchQuery)) return false;
    if (category != null && category.isNotEmpty && e.category != category) return false;
    return true;
  }).toList()
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
}

List<StudentClubModel> filterClubs({
  required List<StudentClubModel> items,
  required String searchQuery,
  String? clubType,
}) {
  return items.where((c) {
    if (!c.isActive) return false;
    if (!matchesStudentLifeSearch(c.searchText, searchQuery)) return false;
    if (clubType != null && clubType.isNotEmpty && c.clubType != clubType) return false;
    return true;
  }).toList()
    ..sort((a, b) => b.membersCount.compareTo(a.membersCount));
}

List<CompetitionModel> filterCompetitions({
  required List<CompetitionModel> items,
  required String searchQuery,
  String? scope,
  bool openRegistrationOnly = false,
}) {
  return items.where((c) {
    if (!c.isActive) return false;
    if (openRegistrationOnly && !c.isRegistrationOpen) return false;
    if (!matchesStudentLifeSearch(c.searchText, searchQuery)) return false;
    if (scope != null && scope.isNotEmpty && c.scope != scope) return false;
    return true;
  }).toList()
    ..sort((a, b) => a.registrationDeadline.compareTo(b.registrationDeadline));
}

List<StudentCommunityModel> filterCommunities({
  required List<StudentCommunityModel> items,
  required String searchQuery,
  String? communityType,
}) {
  return items.where((c) {
    if (!c.isActive) return false;
    if (!matchesStudentLifeSearch(c.name.toLowerCase(), searchQuery)) return false;
    if (communityType != null &&
        communityType.isNotEmpty &&
        c.communityType != communityType) {
      return false;
    }
    return true;
  }).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

int totalPollVotes(List<PollOptionModel> options) {
  return options.fold(0, (sum, o) => sum + o.voteCount);
}

double pollOptionPercent(PollOptionModel option, List<PollOptionModel> options) {
  final total = totalPollVotes(options);
  if (total <= 0) return 0;
  return (option.voteCount / total) * 100;
}
