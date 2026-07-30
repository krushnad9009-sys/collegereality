import 'package:college_reality_india/core/constants/careers_constants.dart';
import 'package:college_reality_india/features/careers/models/careers_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  test('InternshipModel JSON round-trip and getters', () {
    final internship = InternshipModel(
      id: 'i1',
      title: 'Intern',
      companyId: 'c1',
      companyName: 'Acme',
      city: 'Pune',
      payType: CareersConstants.payTypePaid,
      stipend: '10k',
      stipendMin: 10000,
      duration: '3 months',
      durationWeeks: 12,
      workType: CareersConstants.workTypeRemote,
      description: 'Build apps',
      skills: const ['Flutter'],
      applyUrl: 'https://example.com',
      searchText: 'intern',
      createdAt: now,
      updatedAt: now,
    );
    expect(internship.isPaid, isTrue);
    expect(internship.isRemote, isTrue);
    final restored = InternshipModel.fromJson(internship.toJson(), docId: 'i1');
    expect(restored.title, 'Intern');
    expect(restored.skills, ['Flutter']);
    expect(InternshipModel.fromJson({}, docId: 'x').id, 'x');
  });

  test('JobModel JSON round-trip', () {
    final job = JobModel(
      id: 'j1',
      title: 'SDE',
      companyId: 'c1',
      companyName: 'Acme',
      location: 'Pune',
      jobLevel: 'fresher',
      workType: CareersConstants.workTypeRemote,
      salaryMinLpa: 5,
      salaryMaxLpa: 10,
      skills: const ['Dart'],
      createdAt: now,
      updatedAt: now,
    );
    final restored = JobModel.fromJson(job.toJson(), docId: 'j1');
    expect(restored.title, 'SDE');
    expect(restored.location, 'Pune');
  });

  test('CompanyModel JSON round-trip', () {
    final company = CompanyModel(
      id: 'c1',
      name: 'Acme',
      nameLower: 'acme',
      updatedAt: now,
    );
    final restored = CompanyModel.fromJson(company.toJson(), docId: 'c1');
    expect(restored.name, 'Acme');
  });

  test('CompanyReviewModel JSON round-trip', () {
    final review = CompanyReviewModel(
      id: 'r1',
      companyId: 'c1',
      userId: 'u1',
      authorDisplayName: 'Ada',
      rating: 4,
      createdAt: now,
    );
    final restored = CompanyReviewModel.fromJson(review.toJson(), docId: 'r1');
    expect(restored.rating, 4);
  });

  test('AlumniProfileModel JSON round-trip', () {
    final alumni = AlumniProfileModel(
      id: 'a1',
      userId: 'u1',
      displayName: 'Ada',
      collegeName: 'COEP',
      batchYear: 2020,
      company: 'Acme',
      jobTitle: 'SDE',
      updatedAt: now,
    );
    final restored = AlumniProfileModel.fromJson(alumni.toJson(), docId: 'a1');
    expect(restored.displayName, 'Ada');
  });

  test('ApplicationModel JSON round-trip', () {
    final app = ApplicationModel(
      id: 'ap1',
      userId: 'u1',
      jobId: 'j1',
      companyId: 'c1',
      applicantName: 'Ada',
      createdAt: now,
    );
    final restored = ApplicationModel.fromJson(app.toJson(), docId: 'ap1');
    expect(restored.jobId, 'j1');
  });

  test('StudentResumeModel and CompanyAccountModel JSON', () {
    final resume = StudentResumeModel(
      userId: 'u1',
      fileName: 'resume.pdf',
      downloadUrl: 'https://example.com/r.pdf',
      updatedAt: now,
    );
    expect(
      StudentResumeModel.fromJson(resume.toJson(), docId: 'u1').fileName,
      'resume.pdf',
    );

    final account = CompanyAccountModel(
      userId: 'u1',
      companyId: 'c1',
      companyName: 'Acme',
      createdAt: now,
    );
    expect(
      CompanyAccountModel.fromJson(account.toJson(), docId: 'u1').companyName,
      'Acme',
    );
  });

  test('CareersPageResult holds items', () {
    const page = CareersPageResult<JobModel>(items: [], hasMore: false);
    expect(page.items, isEmpty);
  });
}