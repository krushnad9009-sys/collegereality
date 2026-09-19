import 'dart:typed_data';

import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/verification/models/verification_request_model.dart';
import 'package:college_reality_india/features/verification/providers/verification_provider.dart';
import 'package:college_reality_india/features/verification/services/verification_firestore_service.dart';
import 'package:college_reality_india/features/verification/services/verification_storage_service.dart';
import 'package:college_reality_india/features/verification/widgets/student_verification_documents_section.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_harness.dart';

class _FakePicker extends FilePicker {
  _FakePicker(this.file);
  final PlatformFile? file;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async =>
      file == null ? null : FilePickerResult([file!]);
}

class _SubmitCall {
  final String documentType;
  final String collegeId;
  final String fileName;
  final int byteLength;
  final bool phoneVerified;
  _SubmitCall(this.documentType, this.collegeId, this.fileName, this.byteLength,
      this.phoneVerified);
}

class _FakeService extends Fake implements VerificationFirestoreService {
  final calls = <_SubmitCall>[];

  @override
  Future<VerificationRequestModel> submitDocument({
    required UserModel user,
    required String documentType,
    required String verificationRole,
    required String collegeId,
    required String collegeName,
    required Uint8List bytes,
    required String fileName,
  }) async {
    calls.add(_SubmitCall(
        documentType, collegeId, fileName, bytes.length, user.isPhoneVerified));
    return VerificationRequestModel(
      id: 'r1',
      userId: user.uid,
      documentType: documentType,
      storagePath: 'verification_documents/${user.uid}/x.pdf',
      contentHash: 'h',
      status: VerificationConstants.statusPendingReview,
      createdAt: DateTime(2026, 9, 19),
    );
  }
}

UserModel _user({
  bool email = true,
  bool phone = true,
  String status = VerificationConstants.statusIncomplete,
  String badge = VerificationConstants.badgeNone,
}) =>
    testUserModel(uid: 'u1', emailVerified: email).copyWith(
      isPhoneVerified: phone,
      verificationStatus: status,
      verificationBadge: badge,
    );

VerificationRequestModel _request({String? adminNote}) => VerificationRequestModel(
      id: 'r1',
      userId: 'u1',
      documentType: VerificationConstants.documentCollegeId,
      storagePath: 'verification_documents/u1/college_id_r1_scan.pdf',
      contentHash: 'h',
      status: VerificationConstants.statusRejected,
      adminNote: adminNote,
      createdAt: DateTime(2026, 9, 12),
    );

Future<_FakeService> _pump(
  WidgetTester tester, {
  required UserModel user,
  bool phoneVerified = true,
  String? collegeId = 'c1',
  String? collegeName = 'Test College',
  VerificationRequestModel? request,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = _FakeService();
  await pumpScreen(
    tester,
    overrides: [
      ...testAuthOverrides(),
      verificationServiceProvider.overrideWithValue(service),
      userVerificationRequestProvider.overrideWith((ref, uid) async => request),
    ],
    child: Scaffold(
      body: SingleChildScrollView(
        child: StudentVerificationDocumentsSection(
          user: user,
          isPhoneVerified: phoneVerified,
          collegeId: collegeId,
          collegeName: collegeName,
        ),
      ),
    ),
  );
  return service;
}

Future<void> _selectType(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudentVerificationDocumentsSection', () {
    testWidgets('shows the title, description, format hint and 3 types',
        (tester) async {
      await _pump(tester, user: _user());

      expect(find.text('Student Verification Documents'), findsOneWidget);
      expect(
        find.text(
          'Upload valid student proofs for badge verification '
          '(Marksheet, College ID, or APAAR ID).',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Allowed formats: PDF, JPG, PNG · Max size: 5 MB'),
        findsOneWidget,
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('College ID Card'), findsOneWidget);
      expect(find.text('Marksheet / Transcript'), findsOneWidget);
      expect(find.text('APAAR ID'), findsOneWidget);
    });

    testWidgets('blocks upload until email and phone are verified',
        (tester) async {
      await _pump(tester, user: _user(phone: false), phoneVerified: false);

      expect(
        find.text('Verify your email and mobile number above first.'),
        findsOneWidget,
      );
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });

    testWidgets('asks for a college when none is selected', (tester) async {
      await _pump(tester, user: _user(), collegeId: null, collegeName: null);

      expect(
        find.text('Select your college in Academic Details below before uploading.'),
        findsOneWidget,
      );
    });

    testWidgets('picks a file, previews it and uploads with the chosen type',
        (tester) async {
      FilePicker.platform = _FakePicker(
        PlatformFile(name: 'id_card.pdf', size: 40000, bytes: Uint8List(40000)),
      );
      final service = await _pump(tester, user: _user(), phoneVerified: true);

      await _selectType(tester, 'APAAR ID');
      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();

      expect(find.text('id_card.pdf'), findsOneWidget);
      expect(find.text('PDF · 39 KB'), findsOneWidget);

      await tester.tap(find.text('Upload for Verification'));
      await tester.pumpAndSettle();

      expect(service.calls, hasLength(1));
      final call = service.calls.single;
      expect(call.documentType, VerificationConstants.documentApaarAadhaar);
      expect(call.collegeId, 'c1');
      expect(call.fileName, 'id_card.pdf');
      expect(call.byteLength, 40000);
      expect(find.text('Document uploaded. It is now pending review.'),
          findsOneWidget);
    });

    testWidgets('a file over 5 MB is rejected with a message', (tester) async {
      final tooBig = VerificationConstants.maxBadgeProofBytes + 1;
      FilePicker.platform = _FakePicker(
        PlatformFile(name: 'big.pdf', size: tooBig, bytes: Uint8List(tooBig)),
      );
      final service = await _pump(tester, user: _user());

      await _selectType(tester, 'College ID Card');
      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();

      expect(find.textContaining('maximum size is 5 MB'), findsOneWidget);
      expect(find.text('big.pdf'), findsNothing);
      expect(service.calls, isEmpty);
    });

    testWidgets('pending review shows the status card and no upload form',
        (tester) async {
      await _pump(
        tester,
        user: _user(status: VerificationConstants.statusPendingReview),
        request: _request(),
      );

      expect(find.text('Uploaded - Pending Review'), findsOneWidget);
      expect(find.text('College ID Card'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });

    testWidgets('approved shows Verified and no upload form', (tester) async {
      await _pump(
        tester,
        user: _user(
          status: VerificationConstants.statusApproved,
          badge: VerificationConstants.badgeVerifiedStudent,
        ),
        request: _request(),
      );

      expect(find.text('Verified'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });

    testWidgets('rejected shows the reason and allows a new upload',
        (tester) async {
      await _pump(
        tester,
        user: _user(status: VerificationConstants.statusRejected),
        request: _request(adminNote: 'Photo is too blurry to read.'),
      );

      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Photo is too blurry to read.'), findsOneWidget);
      expect(find.text('Upload a new document'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });
  });

  group('VerificationStorageService.objectName', () {
    test('uses {docType}_{requestId}_{name}.{ext}', () {
      expect(
        VerificationStorageService.objectName(
          requestId: 'abc',
          extension: 'pdf',
          documentType: 'college_id',
          fileName: 'My ID Card.pdf',
        ),
        'college_id_abc_My_ID_Card.pdf',
      );
    });

    test('a hostile file name cannot add a path segment or ..', () {
      final name = VerificationStorageService.objectName(
        requestId: 'abc',
        extension: 'png',
        documentType: 'college_id',
        fileName: '../../victim/../x.png',
      );
      expect(name.contains('/'), isFalse);
      expect(name.contains('..'), isFalse);
      expect(name, 'college_id_abc_victim_x.png');
    });

    test('empty or symbol-only names fall back to "document"', () {
      expect(
        VerificationStorageService.objectName(
          requestId: 'abc',
          extension: 'jpg',
          documentType: 'apaar_aadhaar_id',
          fileName: '!!!.jpg',
        ),
        'apaar_aadhaar_id_abc_document.jpg',
      );
    });

    test('long names are capped', () {
      final name = VerificationStorageService.objectName(
        requestId: 'abc',
        extension: 'pdf',
        documentType: 'college_id',
        fileName: '${'a' * 200}.pdf',
      );
      expect(name.length, lessThan(80));
    });

    test('legacy and multi-document shapes are unchanged', () {
      expect(
        VerificationStorageService.objectName(requestId: 'abc', extension: 'pdf'),
        'abc.pdf',
      );
      expect(
        VerificationStorageService.objectName(
          requestId: 'abc',
          extension: 'pdf',
          slot: 2,
          documentType: 'college_id',
          fileName: 'x.pdf',
        ),
        'abc-2.pdf',
      );
    });
  });
}
