import 'package:college_reality_india/core/constants/ecosystem_constants.dart';
import 'package:college_reality_india/features/ecosystem/models/ecosystem_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 2, 10, 12, 0);

  group('EditHistoryEntry JSON', () {
    test('round-trip preserves audit fields', () {
      final original = EditHistoryEntry(
        action: 'updated',
        field: 'fees',
        oldValue: '100000',
        newValue: '120000',
        actorId: 'admin-1',
        actorName: 'Admin',
        at: now,
      );
      final restored = EditHistoryEntry.fromJson(original.toJson());
      expect(restored.field, 'fees');
      expect(restored.newValue, '120000');
      expect(restored.at, now);
    });
  });

  group('CollegeRequestModel JSON', () {
    test('round-trip preserves location and status', () {
      final original = CollegeRequestModel(
        id: 'req-1',
        userId: 'user-1',
        userName: 'Student',
        name: 'New Institute',
        nameLower: 'new institute',
        city: 'Pune',
        cityLower: 'pune',
        state: 'Maharashtra',
        address: 'Camp Road',
        website: 'https://example.com',
        universityName: 'SPPU',
        notes: 'Please add',
        status: EcosystemConstants.statusPending,
        createdAt: now,
        updatedAt: now,
      );
      final restored = CollegeRequestModel.fromJson(original.toJson(), docId: 'req-1');
      expect(restored.name, 'New Institute');
      expect(restored.website, 'https://example.com');
      expect(restored.status, EcosystemConstants.statusPending);
    });
  });

  group('CollegeEditSuggestionModel JSON', () {
    test('round-trip preserves edit history', () {
      final original = CollegeEditSuggestionModel(
        id: 'sug-1',
        collegeId: 'col-1',
        collegeName: 'COEP',
        userId: 'user-1',
        field: 'address',
        currentValue: 'Old address',
        suggestedValue: 'New address',
        reason: 'Moved campus',
        editHistory: [
          EditHistoryEntry(
            action: 'submitted',
            field: 'address',
            newValue: 'New address',
            actorId: 'user-1',
            at: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );
      final restored = CollegeEditSuggestionModel.fromJson(original.toJson());
      expect(restored.editHistory.single.action, 'submitted');
      expect(restored.suggestedValue, 'New address');
    });
  });

  group('CollegeDataReportModel JSON', () {
    test('round-trip preserves report metadata', () {
      final original = CollegeDataReportModel(
        id: 'rep-1',
        collegeId: 'col-1',
        collegeName: 'Test College',
        userId: 'user-1',
        reportType: EcosystemConstants.reportWrongFees,
        description: 'Fees outdated',
        createdAt: now,
        updatedAt: now,
      );
      final restored = CollegeDataReportModel.fromJson(original.toJson());
      expect(restored.reportType, EcosystemConstants.reportWrongFees);
      expect(restored.description, 'Fees outdated');
    });
  });

  group('CollegeClaimModel JSON', () {
    test('round-trip preserves representative details', () {
      final original = CollegeClaimModel(
        id: 'claim-1',
        collegeId: 'col-1',
        collegeName: 'VIT',
        userId: 'user-1',
        officialEmail: 'admin@vit.edu',
        representativeName: 'Dr. Rao',
        representativeDesignation: 'Registrar',
        authorizationLetterUrl: 'https://storage/letter.pdf',
        createdAt: now,
        updatedAt: now,
      );
      final restored = CollegeClaimModel.fromJson(original.toJson());
      expect(restored.officialEmail, 'admin@vit.edu');
      expect(restored.authorizationLetterUrl, isNotNull);
    });
  });

  group('CollegeAccountModel JSON', () {
    test('round-trip preserves verification flags', () {
      final original = CollegeAccountModel(
        userId: 'user-official',
        collegeId: 'col-1',
        collegeName: 'Official College',
        officialEmail: 'info@college.edu',
        isVerified: true,
        showOfficialBadge: true,
        verifiedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final restored = CollegeAccountModel.fromJson(original.toJson());
      expect(restored.isVerified, isTrue);
      expect(restored.showOfficialBadge, isTrue);
      expect(restored.verifiedAt, now);
    });
  });

  group('FacultyVerificationRequestModel JSON', () {
    test('round-trip preserves department info', () {
      final original = FacultyVerificationRequestModel(
        id: 'fac-1',
        userId: 'user-1',
        collegeId: 'col-1',
        collegeName: 'COEP',
        officialEmail: 'prof@coep.ac.in',
        department: 'Computer',
        designation: 'Assistant Professor',
        facultyIdUrl: 'https://storage/id.pdf',
        createdAt: now,
        updatedAt: now,
      );
      final restored = FacultyVerificationRequestModel.fromJson(original.toJson());
      expect(restored.department, 'Computer');
      expect(restored.facultyIdUrl, isNotNull);
    });
  });

  group('CollegeOfficialContentModel JSON', () {
    test('round-trip preserves section and media', () {
      final original = CollegeOfficialContentModel(
        id: 'content-1',
        collegeId: 'col-1',
        authorId: 'official-1',
        section: EcosystemConstants.sectionNotice,
        title: 'Admission Open',
        body: 'Applications open till July.',
        mediaUrls: const ['https://example.com/notice.pdf'],
        createdAt: now,
        updatedAt: now,
      );
      final restored = CollegeOfficialContentModel.fromJson(original.toJson());
      expect(restored.section, EcosystemConstants.sectionNotice);
      expect(restored.mediaUrls, original.mediaUrls);
    });
  });

  group('FacultyWorkshopModel JSON', () {
    test('round-trip preserves schedule', () {
      final original = FacultyWorkshopModel(
        id: 'ws-1',
        facultyId: 'fac-1',
        collegeId: 'col-1',
        title: 'ML Workshop',
        description: 'Intro to ML',
        scheduledAt: now.add(const Duration(days: 14)),
        createdAt: now,
      );
      final restored = FacultyWorkshopModel.fromJson(original.toJson());
      expect(restored.title, 'ML Workshop');
      expect(restored.scheduledAt, original.scheduledAt);
    });
  });

  group('FacultyResearchModel JSON', () {
    test('round-trip preserves abstract and link', () {
      final original = FacultyResearchModel(
        id: 'res-1',
        facultyId: 'fac-1',
        collegeId: 'col-1',
        title: 'Edge AI Paper',
        abstract: 'Efficient inference on edge devices.',
        linkUrl: 'https://arxiv.org/example',
        createdAt: now,
      );
      final restored = FacultyResearchModel.fromJson(original.toJson());
      expect(restored.linkUrl, 'https://arxiv.org/example');
    });
  });

  group('AlumniMentorshipOfferModel JSON', () {
    test('round-trip preserves topic and active flag', () {
      final original = AlumniMentorshipOfferModel(
        id: 'mentor-1',
        alumniId: 'alum-1',
        alumniName: 'Anita',
        collegeId: 'col-1',
        collegeName: 'PICT',
        topic: 'Placements',
        description: 'Mock interviews',
        isActive: true,
        createdAt: now,
      );
      final restored = AlumniMentorshipOfferModel.fromJson(original.toJson());
      expect(restored.topic, 'Placements');
      expect(restored.isActive, isTrue);
    });
  });

  group('AuditLogModel JSON', () {
    test('round-trip preserves metadata map', () {
      final original = AuditLogModel(
        id: 'log-1',
        action: 'approve_claim',
        actorId: 'admin-1',
        actorName: 'Admin',
        targetId: 'claim-1',
        targetType: 'college_claim',
        metadata: const {'collegeId': 'col-1'},
        createdAt: now,
      );
      final restored = AuditLogModel.fromJson(original.toJson());
      expect(restored.metadata['collegeId'], 'col-1');
      expect(restored.action, 'approve_claim');
    });
  });
}
