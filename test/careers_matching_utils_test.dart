import 'package:college_reality_india/core/constants/careers_constants.dart';
import 'package:college_reality_india/features/careers/models/careers_models.dart';
import 'package:college_reality_india/features/careers/utils/careers_matching_utils.dart';
import 'package:flutter_test/flutter_test.dart';

JobModel _job({
  required String id,
  required String title,
  List<String> skills = const ['Flutter', 'Dart'],
  String eligibility = 'B.Tech computer science',
  String jobLevel = 'fresher',
  bool isActive = true,
}) {
  final now = DateTime(2026, 2, 1);
  return JobModel(
    id: id,
    title: title,
    companyId: 'co-$id',
    companyName: 'Company $id',
    location: 'Pune',
    jobLevel: jobLevel,
    workType: CareersConstants.workTypeOffice,
    salaryMinLpa: 6,
    salaryMaxLpa: 10,
    eligibility: eligibility,
    description: 'Role for $title',
    skills: skills,
    searchText: '$title flutter'.toLowerCase(),
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

InternshipModel _internship({
  required String id,
  required String title,
  List<String> skills = const ['Python'],
  bool isPaid = true,
  bool isRemote = false,
  bool isActive = true,
}) {
  final now = DateTime(2026, 2, 1);
  return InternshipModel(
    id: id,
    title: title,
    companyId: 'co-$id',
    companyName: 'Startup $id',
    city: 'Bangalore',
    payType: isPaid ? CareersConstants.payTypePaid : CareersConstants.payTypeUnpaid,
    workType: isRemote ? CareersConstants.workTypeRemote : CareersConstants.workTypeOffice,
    skills: skills,
    searchText: title.toLowerCase(),
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('recommendJobs', () {
    test('ranks by skill and degree matches', () {
      final results = recommendJobs(
        jobs: [
          _job(id: '1', title: 'Mobile Dev', skills: const ['Flutter', 'Firebase']),
          _job(id: '2', title: 'Backend', skills: const ['Java']),
        ],
        degree: 'B.Tech',
        branch: 'Computer Science',
        skills: const ['Flutter', 'Firebase'],
      );
      expect(results, isNotEmpty);
      expect(results.first.item.id, '1');
      expect(results.first.reason, contains('Skill match'));
    });

    test('skips inactive jobs', () {
      final results = recommendJobs(
        jobs: [_job(id: '1', title: 'Inactive', isActive: false)],
        degree: 'B.Tech',
        branch: 'CSE',
        skills: const ['Flutter'],
      );
      expect(results, isEmpty);
    });

    test('adds fresher bonus to score', () {
      final withFresher = recommendJobs(
        jobs: [_job(id: '1', title: 'Fresher Role', jobLevel: 'fresher', skills: const ['Rust'])],
        degree: 'MBA',
        branch: 'Finance',
        skills: const ['Rust'],
      );
      final withoutFresher = recommendJobs(
        jobs: [_job(id: '2', title: 'Senior Role', jobLevel: 'experienced', skills: const ['Rust'])],
        degree: 'MBA',
        branch: 'Finance',
        skills: const ['Rust'],
      );
      expect(withFresher.first.score, greaterThan(withoutFresher.first.score));
    });

    test('respects limit', () {
      final jobs = List.generate(15, (i) => _job(id: '$i', title: 'Job $i'));
      final results = recommendJobs(
        jobs: jobs,
        degree: 'B.Tech',
        branch: 'computer',
        skills: const ['Flutter'],
        limit: 5,
      );
      expect(results.length, 5);
    });
  });

  group('recommendInternships', () {
    test('ranks paid remote internships higher', () {
      final results = recommendInternships(
        internships: [
          _internship(id: '1', title: 'Office Unpaid', isPaid: false, isRemote: false),
          _internship(id: '2', title: 'Remote Paid', isPaid: true, isRemote: true, skills: const ['Python']),
        ],
        skills: const ['Python'],
      );
      expect(results.first.item.id, '2');
    });

    test('skips inactive internships', () {
      final results = recommendInternships(
        internships: [_internship(id: '1', title: 'Closed', isActive: false)],
        skills: const ['Python'],
      );
      expect(results, isEmpty);
    });
  });

  group('generateCareerSuggestions', () {
    test('suggests adding skills when profile empty', () {
      final suggestions = generateCareerSuggestions(
        degree: null,
        branch: null,
        skills: const [],
        jobs: [_job(id: '1', title: 'Dev')],
        internships: [_internship(id: '1', title: 'Intern')],
      );
      expect(suggestions.any((s) => s.contains('Add skills')), isTrue);
      expect(suggestions.any((s) => s.contains('degree')), isTrue);
    });

    test('lists in-demand missing skills', () {
      final suggestions = generateCareerSuggestions(
        degree: 'B.Tech',
        branch: 'CSE',
        skills: const ['Java'],
        jobs: [
          _job(id: '1', title: 'Dev', skills: const ['Flutter', 'Dart', 'Firebase']),
        ],
        internships: const [],
      );
      expect(suggestions.any((s) => s.contains('In-demand skills')), isTrue);
    });

    test('mentions paid internships when available', () {
      final suggestions = generateCareerSuggestions(
        degree: 'B.Tech',
        branch: 'CSE',
        skills: const ['Python'],
        jobs: const [],
        internships: [
          _internship(id: '1', title: 'Paid Intern', isPaid: true),
          _internship(id: '2', title: 'Paid Intern 2', isPaid: true),
        ],
      );
      expect(suggestions.any((s) => s.contains('paid internships')), isTrue);
    });

    test('includes branch-specific growth tip', () {
      final suggestions = generateCareerSuggestions(
        degree: 'B.Tech',
        branch: 'CSE',
        skills: const ['Flutter', 'Dart', 'Firebase'],
        jobs: [_job(id: '1', title: 'Dev', skills: const ['Flutter'])],
        internships: [_internship(id: '1', title: 'Intern', skills: const ['Flutter'])],
      );
      expect(suggestions.any((s) => s.contains('CSE roles')), isTrue);
    });
  });
}
