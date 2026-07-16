import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/admission_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../models/admission_prediction_model.dart';
import '../models/cutoff_record_model.dart';
import '../models/entrance_exam_model.dart';
import '../models/scholarship_model.dart';
import '../../../core/utils/firestore_seed_guard.dart';
import '../utils/admission_utils.dart';

class FirestoreAdmissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _scholarships =>
      _firestore.collection(FirestoreConstants.scholarshipsCollection);
  CollectionReference<Map<String, dynamic>> get _exams =>
      _firestore.collection(FirestoreConstants.entranceExamsCollection);
  CollectionReference<Map<String, dynamic>> get _cutoffs =>
      _firestore.collection(FirestoreConstants.cutoffRecordsCollection);
  CollectionReference<Map<String, dynamic>> get _predictions =>
      _firestore.collection(FirestoreConstants.admissionPredictionsCollection);
  CollectionReference<Map<String, dynamic>> get _savedScholarships =>
      _firestore.collection(FirestoreConstants.savedScholarshipsCollection);
  DocumentReference<Map<String, dynamic>> get _meta =>
      _firestore.collection(FirestoreConstants.metaCollection).doc(
            AdmissionConstants.metaAdmissionSeededDoc,
          );

  Future<void> ensureSeeded() async {
    await FirestoreSeedGuard.tryBootstrapSeed(
      metaDocId: AdmissionConstants.metaAdmissionSeededDoc,
      sampleQuery: _scholarships.limit(1).get(),
      seed: _seedFromAssets,
    );
  }

  Future<void> _seedFromAssets() async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    final scholarshipsJson =
        await rootBundle.loadString('assets/data/scholarships_seed.json');
    for (final item in jsonDecode(scholarshipsJson) as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      final name = map['name'] as String;
      map['nameLower'] = name.toLowerCase();
      map['searchText'] = buildAdmissionSearchText([
        name,
        map['eligibility'] as String? ?? '',
        ...(map['courses'] as List<dynamic>? ?? []).cast<String>(),
      ]);
      map['createdAt'] = now.toIso8601String();
      map['updatedAt'] = now.toIso8601String();
      map['isActive'] = true;
      batch.set(_scholarships.doc(id), map);
    }

    final examsJson =
        await rootBundle.loadString('assets/data/entrance_exams_seed.json');
    for (final item in jsonDecode(examsJson) as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      final name = map['name'] as String;
      map['searchText'] = buildAdmissionSearchText([
        name,
        map['category'] as String? ?? '',
        map['conductingBody'] as String? ?? '',
      ]);
      map['createdAt'] = now.toIso8601String();
      map['updatedAt'] = now.toIso8601String();
      map['isActive'] = true;
      batch.set(_exams.doc(id), map);
    }

    final cutoffsJson =
        await rootBundle.loadString('assets/data/cutoffs_seed.json');
    for (final item in jsonDecode(cutoffsJson) as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      map['updatedAt'] = now.toIso8601String();
      batch.set(_cutoffs.doc(id), map);
    }

    await batch.commit();
  }

  Future<List<ScholarshipModel>> getScholarships() async {
    await ensureSeeded();
    final snapshot = await _scholarships
        .where('isActive', isEqualTo: true)
        .orderBy('nameLower')
        .get();
    return snapshot.docs
        .map((doc) => ScholarshipModel.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  Stream<List<ScholarshipModel>> watchScholarships() async* {
    await ensureSeeded();
    yield* _scholarships
        .where('isActive', isEqualTo: true)
        .orderBy('nameLower')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScholarshipModel.fromJson(doc.data(), docId: doc.id))
            .toList());
  }

  Future<ScholarshipModel?> getScholarshipById(String id) async {
    final doc = await _scholarships.doc(id).get();
    if (!doc.exists) return null;
    return ScholarshipModel.fromJson(doc.data()!, docId: doc.id);
  }

  Future<List<EntranceExamModel>> getExams() async {
    await ensureSeeded();
    final snapshot =
        await _exams.where('isActive', isEqualTo: true).orderBy('name').get();
    return snapshot.docs
        .map((doc) => EntranceExamModel.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  Stream<List<EntranceExamModel>> watchExams() async* {
    await ensureSeeded();
    yield* _exams
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EntranceExamModel.fromJson(doc.data(), docId: doc.id))
            .toList());
  }

  Future<EntranceExamModel?> getExamById(String id) async {
    final doc = await _exams.doc(id).get();
    if (!doc.exists) return null;
    return EntranceExamModel.fromJson(doc.data()!, docId: doc.id);
  }

  Future<List<CutoffRecordModel>> getCutoffs({String? examId}) async {
    await ensureSeeded();
    Query<Map<String, dynamic>> query = _cutoffs.orderBy('year', descending: true);
    if (examId != null && examId.isNotEmpty) {
      query = _cutoffs
          .where('examId', isEqualTo: examId)
          .orderBy('year', descending: true);
    }
    final snapshot = await query.limit(500).get();
    return snapshot.docs
        .map((doc) => CutoffRecordModel.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  Stream<List<CutoffRecordModel>> watchCutoffs({String? examId}) async* {
    await ensureSeeded();
    Query<Map<String, dynamic>> query = _cutoffs.orderBy('year', descending: true);
    if (examId != null && examId.isNotEmpty) {
      query = _cutoffs
          .where('examId', isEqualTo: examId)
          .orderBy('year', descending: true);
    }
    yield* query.limit(500).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => CutoffRecordModel.fromJson(doc.data(), docId: doc.id))
        .toList());
  }

  Future<AdmissionPredictionModel> savePrediction(AdmissionPredictionModel prediction) async {
    final id = prediction.id.isEmpty ? _uuid.v4() : prediction.id;
    final saved = AdmissionPredictionModel(
      id: id,
      userId: prediction.userId,
      examId: prediction.examId,
      examName: prediction.examName,
      rank: prediction.rank,
      percentile: prediction.percentile,
      marks: prediction.marks,
      scoreType: prediction.scoreType,
      category: prediction.category,
      gender: prediction.gender,
      state: prediction.state,
      homeUniversity: prediction.homeUniversity,
      results: prediction.results,
      label: prediction.label,
      createdAt: prediction.createdAt,
    );
    await _predictions.doc(id).set(saved.toJson());
    return saved;
  }

  Stream<List<AdmissionPredictionModel>> watchUserPredictions(String userId) {
    return _predictions
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdmissionPredictionModel.fromJson(doc.data(), docId: doc.id))
            .toList());
  }

  Future<void> deletePrediction(String predictionId) async {
    await _predictions.doc(predictionId).delete();
  }

  Future<void> saveScholarship(String userId, String scholarshipId) async {
    final docId = '${userId}_$scholarshipId';
    await _savedScholarships.doc(docId).set({
      'userId': userId,
      'scholarshipId': scholarshipId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unsaveScholarship(String userId, String scholarshipId) async {
    await _savedScholarships.doc('${userId}_$scholarshipId').delete();
  }

  Stream<Set<String>> watchSavedScholarshipIds(String userId) {
    return _savedScholarships
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['scholarshipId'] as String)
            .toSet());
  }

  Future<bool> isScholarshipSaved(String userId, String scholarshipId) async {
    final doc = await _savedScholarships.doc('${userId}_$scholarshipId').get();
    return doc.exists;
  }
}

class AdmissionFirestoreException implements Exception {
  final String message;
  AdmissionFirestoreException({required this.message});
  @override
  String toString() => message;
}
