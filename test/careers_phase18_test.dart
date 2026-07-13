import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/careers_constants.dart';
import 'package:college_reality_india/features/careers/models/careers_models.dart';
import 'package:college_reality_india/features/careers/utils/careers_filter_utils.dart';
import 'package:college_reality_india/features/careers/utils/careers_matching_utils.dart';
import 'package:college_reality_india/features/careers/utils/resume_scoring_utils.dart';

void main() {
  group('Phase 18 filter extensions', () {
    InternshipModel sampleInternship({
      String workType = CareersConstants.workTypeOffice,
      int stipendMin = 0,
      int durationWeeks = 0,
    }) {
      return InternshipModel(
        id: '1',
        title: 'Backend Intern',
        companyId: 'co_tcs',
        companyName: 'TCS',
        city: 'Pune',
        payType: CareersConstants.payTypePaid,
        stipend: '₹25,000',
        stipendMin: stipendMin,
        duration: '6 months',
        durationWeeks: durationWeeks,
        workType: workType,
        searchText: 'backend intern tcs pune',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
    }

    test('filterInternships supports WFH and stipend filters', () {
      final items = [
        sampleInternship(workType: CareersConstants.workTypeRemote, stipendMin: 25000),
        sampleInternship(workType: CareersConstants.workTypeOffice, stipendMin: 10000),
      ];

      final wfh = filterInternships(
        items: items,
        searchQuery: '',
        workFromHome: true,
      );
      expect(wfh.length, 1);
      expect(wfh.first.workType, CareersConstants.workTypeRemote);

      final stipend = filterInternships(
        items: items,
        searchQuery: '',
        minStipend: 20000,
      );
      expect(stipend.length, 1);
      expect(stipend.first.stipendMin, 25000);
    });
  });

  group('CareersMatchingUtils', () {
    test('recommendJobs scores degree and skills', () {
      final jobs = [
        JobModel(
          id: 'j1',
          title: 'SDE',
          companyId: 'co_tcs',
          companyName: 'TCS',
          location: 'Pune',
          jobLevel: CareersConstants.jobLevelFresher,
          workType: CareersConstants.workTypeOffice,
          eligibility: 'B.E. Computer Engineering',
          skills: ['Java', 'SQL'],
          searchText: 'sde tcs',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ];

      final matches = recommendJobs(
        jobs: jobs,
        degree: 'B.E. Computer Engineering',
        branch: 'Computer',
        skills: ['Java'],
      );
      expect(matches, isNotEmpty);
      expect(matches.first.score, greaterThan(0));
    });

    test('generateCareerSuggestions returns actionable tips', () {
      final tips = generateCareerSuggestions(
        degree: null,
        branch: null,
        skills: [],
        jobs: [],
        internships: [],
      );
      expect(tips, isNotEmpty);
    });
  });

  group('ResumeScoringUtils', () {
    test('scoreResume penalizes missing resume', () {
      final result = scoreResume(
        user: null,
        hasResumeFile: false,
        fileSizeBytes: 0,
        extractedSkills: [],
      );
      expect(result.score, lessThan(50));
      expect(result.suggestions, isNotEmpty);
    });
  });
}
