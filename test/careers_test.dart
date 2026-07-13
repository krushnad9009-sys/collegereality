import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/careers_constants.dart';
import 'package:college_reality_india/features/careers/models/careers_models.dart';
import 'package:college_reality_india/features/careers/utils/careers_filter_utils.dart';

void main() {
  group('CareersFilterUtils', () {
    InternshipModel sampleInternship({
      required String id,
      required String title,
      String city = 'Pune',
      String companyName = 'TCS',
      String payType = CareersConstants.payTypePaid,
      bool isActive = true,
    }) {
      return InternshipModel(
        id: id,
        title: title,
        companyId: 'co_tcs',
        companyName: companyName,
        city: city,
        payType: payType,
        stipend: '₹15,000',
        duration: '3 months',
        description: 'Software intern role',
        applyUrl: 'https://example.com/apply',
        searchText: '$title $companyName $city'.toLowerCase(),
        isActive: isActive,
        createdAt: DateTime(2025, 6, 1),
        updatedAt: DateTime(2025, 6, 1),
      );
    }

    JobModel sampleJob({
      required String id,
      required String title,
      String location = 'Bangalore',
      String jobLevel = CareersConstants.jobLevelFresher,
      String workType = CareersConstants.workTypeRemote,
      double salaryMaxLpa = 8,
      bool isActive = true,
    }) {
      return JobModel(
        id: id,
        title: title,
        companyId: 'co_tcs',
        companyName: 'TCS',
        location: location,
        jobLevel: jobLevel,
        workType: workType,
        salaryMinLpa: 6,
        salaryMaxLpa: salaryMaxLpa,
        description: 'Engineering role',
        applyUrl: 'https://example.com/jobs',
        searchText: '$title TCS $location'.toLowerCase(),
        isActive: isActive,
        createdAt: DateTime(2025, 5, 1),
        updatedAt: DateTime(2025, 5, 1),
      );
    }

    test('filterInternships applies city, company, and pay filters', () {
      final items = [
        sampleInternship(id: '1', title: 'Backend Intern', city: 'Pune'),
        sampleInternship(
          id: '2',
          title: 'Design Intern',
          city: 'Mumbai',
          companyName: 'Infosys',
          payType: CareersConstants.payTypeUnpaid,
        ),
      ];

      final filtered = filterInternships(
        items: items,
        searchQuery: '',
        city: 'Pune',
        company: 'TCS',
        payType: CareersConstants.payTypePaid,
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('filterJobs applies level, work type, and salary filters', () {
      final items = [
        sampleJob(id: '1', title: 'SDE Fresher'),
        sampleJob(
          id: '2',
          title: 'Senior Engineer',
          jobLevel: CareersConstants.jobLevelExperienced,
          workType: CareersConstants.workTypeOffice,
          salaryMaxLpa: 20,
        ),
      ];

      final filtered = filterJobs(
        items: items,
        searchQuery: '',
        location: 'Bangalore',
        jobLevel: CareersConstants.jobLevelFresher,
        workType: CareersConstants.workTypeRemote,
        minSalaryLpa: 7,
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('filterCompanies matches search text', () {
      final items = [
        CompanyModel(
          id: '1',
          name: 'Tata Consultancy Services',
          nameLower: 'tata consultancy services',
          industry: 'IT Services',
          description: 'Global IT company',
          hiringStatus: CareersConstants.hiringActive,
          website: 'https://tcs.com',
          rating: 4.2,
          reviewCount: 10,
          placementHistory: const ['2024: 120 offers'],
          searchText: 'tata consultancy services it services',
          isActive: true,
          updatedAt: DateTime(2025),
        ),
      ];

      final filtered = filterCompanies(items: items, searchQuery: 'tata');
      expect(filtered.length, 1);
    });

    test('filterAlumni matches company and location filters', () {
      final items = [
        AlumniProfileModel(
          id: '1',
          displayName: 'Rahul Sharma',
          batchYear: 2022,
          collegeName: 'COEP',
          company: 'Google',
          jobTitle: 'Software Engineer',
          location: 'Bangalore',
          linkedInUrl: null,
          successStory: 'Placed through campus drive',
          isVerifiedAlumni: true,
          isActive: true,
          searchText: 'rahul google software engineer coep',
          updatedAt: DateTime(2025),
        ),
        AlumniProfileModel(
          id: '2',
          displayName: 'Priya Patel',
          batchYear: 2021,
          collegeName: 'VIT',
          company: 'Amazon',
          jobTitle: 'Product Manager',
          location: 'Hyderabad',
          linkedInUrl: null,
          successStory: '',
          isVerifiedAlumni: true,
          isActive: true,
          searchText: 'priya amazon product manager vit',
          updatedAt: DateTime(2025),
        ),
      ];

      final filtered = filterAlumni(
        items: items,
        searchQuery: '',
        company: 'Google',
        location: 'Bangalore',
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });
  });
}
