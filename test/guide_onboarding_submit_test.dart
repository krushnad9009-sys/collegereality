import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/guide_onboarding/guide_onboarding_rules.dart';
import 'package:college_reality_india/features/guide_onboarding/guide_onboarding_service.dart';
import 'package:college_reality_india/features/reviews/models/review_model.dart';
import 'package:college_reality_india/features/reviews/services/firestore_review_service.dart';
import 'package:college_reality_india/features/verification/models/verification_request_model.dart';
import 'package:college_reality_india/features/verification/services/verification_firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Reviews extends Mock implements FirestoreReviewService {}

class _Verification extends Mock implements VerificationFirestoreService {}

class _Db extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class _Col extends Mock implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Doc extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  final now = DateTime(2026, 10, 6);
  final user = UserModel(
    uid: 'u1',
    email: 'u@test.com',
    createdAt: now,
    updatedAt: now,
  );
  final docs = [
    GuideVerificationDoc(
        documentType: 'student_id', bytes: Uint8List(20000), fileName: 'id.jpg'),
    GuideVerificationDoc(
        documentType: 'fee_receipt', bytes: Uint8List(20000), fileName: 'f.pdf'),
  ];
  ReviewModel review(String id) => ReviewModel(
        id: id,
        collegeId: 'c1',
        collegeName: 'College One',
        userId: 'u1',
        anonymousAlias: 'A',
        ratings: const {},
        textReview: 'x' * 200,
        pros: const [],
        cons: const [],
        photoUrls: const [],
        videoUrls: const [],
        isVerifiedStudent: false,
        yesNoAnswers: const {},
        status: ReviewModel.statusPendingVerification,
        createdAt: now,
        updatedAt: now,
      );

  late _Reviews reviews;
  late _Verification verification;
  late GuideOnboardingService service;
  final calls = <String>[];

  setUpAll(() {
    registerFallbackValue(review(''));
    registerFallbackValue(user);
    registerFallbackValue(SetOptions(merge: true));
  });

  setUp(() {
    calls.clear();
    reviews = _Reviews();
    verification = _Verification();
    final db = _Db();
    final col = _Col();
    final doc = _Doc();
    when(() => db.collection(any())).thenReturn(col);
    when(() => col.doc(any())).thenReturn(doc);
    when(() => doc.set(any(), any())).thenAnswer((_) async {
      calls.add('users');
    });
    service = GuideOnboardingService(
      reviews: reviews,
      verification: verification,
      firestore: db,
    );
    when(() => reviews.findPendingVerificationReview(
          userId: any(named: 'userId'),
          collegeId: any(named: 'collegeId'),
        )).thenAnswer((_) async => null);
    when(() => reviews.createPendingVerificationReview(any()))
        .thenAnswer((_) async {
      calls.add('review');
      return review('r1');
    });
    when(() => verification.getActiveRequest(any()))
        .thenAnswer((_) async => null);
    when(() => verification.submitGuideVerificationDocuments(
          user: any(named: 'user'),
          verificationRole: any(named: 'verificationRole'),
          collegeId: any(named: 'collegeId'),
          collegeName: any(named: 'collegeName'),
          documents: any(named: 'documents'),
        )).thenAnswer((_) async {
      calls.add('documents');
      return VerificationRequestModel(
        id: 'req',
        userId: 'u1',
        documentType: 'student_id',
        storagePath: 'verification_documents/u1/x',
        contentHash: 'h',
        status: 'pending_review',
        createdAt: now,
      );
    });
  });

  Future<bool> submit() => service.submit(
        user: user,
        collegeId: 'c1',
        collegeName: 'College One',
        ratings: const {},
        reviewText: 'x' * 200,
        documentState: DocumentStepState.needsUpload,
        documents: docs,
      );

  test('uploads documents BEFORE writing the review', () async {
    expect(await submit(), isFalse);
    expect(calls, ['documents', 'review', 'users']);
  });

  test('a failed document upload leaves no review behind', () async {
    when(() => verification.submitGuideVerificationDocuments(
          user: any(named: 'user'),
          verificationRole: any(named: 'verificationRole'),
          collegeId: any(named: 'collegeId'),
          collegeName: any(named: 'collegeName'),
          documents: any(named: 'documents'),
        )).thenThrow(VerificationException('upload failed'));

    await expectLater(submit(), throwsA(isA<VerificationException>()));
    verifyNever(() => reviews.createPendingVerificationReview(any()));
  });

  test('retry: documents already under review are not uploaded again and '
      'the earlier pending review is reused', () async {
    when(() => verification.getActiveRequest(any())).thenAnswer(
      (_) async => VerificationRequestModel(
        id: 'req',
        userId: 'u1',
        documentType: 'student_id',
        storagePath: 'verification_documents/u1/x',
        contentHash: 'h',
        status: 'pending_review',
        createdAt: now,
      ),
    );
    when(() => reviews.findPendingVerificationReview(
          userId: 'u1',
          collegeId: 'c1',
        )).thenAnswer((_) async => review('existing'));

    await submit();
    expect(calls, ['users']);
    verifyNever(() => reviews.createPendingVerificationReview(any()));
  });
}
