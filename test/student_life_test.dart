import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/student_life_constants.dart';
import 'package:college_reality_india/features/student_life/models/student_life_models.dart';
import 'package:college_reality_india/features/student_life/utils/student_life_filter_utils.dart';

void main() {
  group('StudentLifeFilterUtils', () {
    CampusEventModel sampleEvent({
      required String id,
      required String title,
      String category = StudentLifeConstants.eventTechnical,
      DateTime? startAt,
      bool isActive = true,
    }) {
      final start = startAt ?? DateTime.now().add(const Duration(days: 5));
      return CampusEventModel(
        id: id,
        title: title,
        collegeId: 'col_coep',
        collegeName: 'COEP',
        category: category,
        location: 'Pune',
        startAt: start,
        endAt: start.add(const Duration(hours: 3)),
        searchText: '$title coep pune'.toLowerCase(),
        isActive: isActive,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
    }

    test('filterEvents applies category and upcoming filters', () {
      final items = [
        sampleEvent(id: '1', title: 'Hackathon', category: StudentLifeConstants.eventHackathon),
        sampleEvent(
          id: '2',
          title: 'Past Seminar',
          category: StudentLifeConstants.eventSeminar,
          startAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      final filtered = filterEvents(
        items: items,
        searchQuery: '',
        category: StudentLifeConstants.eventHackathon,
        upcomingOnly: true,
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('filterClubs applies club type filter', () {
      final items = [
        StudentClubModel(
          id: '1',
          name: 'Code Warriors',
          collegeId: 'col_coep',
          collegeName: 'COEP',
          clubType: StudentLifeConstants.clubCoding,
          membersCount: 100,
          searchText: 'code warriors coding coep',
          updatedAt: DateTime(2025),
        ),
        StudentClubModel(
          id: '2',
          name: 'NSS Unit',
          collegeId: 'col_pict',
          collegeName: 'PICT',
          clubType: StudentLifeConstants.clubNss,
          membersCount: 200,
          searchText: 'nss pict',
          updatedAt: DateTime(2025),
        ),
      ];

      final filtered = filterClubs(
        items: items,
        searchQuery: '',
        clubType: StudentLifeConstants.clubCoding,
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('filterCompetitions applies scope and open registration filters', () {
      final items = [
        CompetitionModel(
          id: '1',
          title: 'Code Sprint',
          collegeId: 'col_coep',
          collegeName: 'COEP',
          scope: StudentLifeConstants.scopeCollege,
          registrationDeadline: DateTime.now().add(const Duration(days: 10)),
          searchText: 'code sprint coep college',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
        CompetitionModel(
          id: '2',
          title: 'National Debate',
          collegeId: 'col_vit',
          collegeName: 'VIT',
          scope: StudentLifeConstants.scopeNational,
          registrationDeadline: DateTime.now().subtract(const Duration(days: 1)),
          searchText: 'national debate vit',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ];

      final filtered = filterCompetitions(
        items: items,
        searchQuery: '',
        scope: StudentLifeConstants.scopeCollege,
        openRegistrationOnly: true,
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('pollOptionPercent calculates vote share', () {
      const options = [
        PollOptionModel(id: 'a', label: 'A', voteCount: 3),
        PollOptionModel(id: 'b', label: 'B', voteCount: 1),
      ];

      expect(pollOptionPercent(options.first, options), 75);
      expect(totalPollVotes(options), 4);
    });
  });
}
