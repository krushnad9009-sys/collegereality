import '../models/admission_prediction_model.dart';
import '../models/cutoff_record_model.dart';
import '../models/entrance_exam_model.dart';
import '../models/scholarship_model.dart';
import '../services/firestore_admission_service.dart';

abstract class AdmissionRepository {
  Future<void> ensureSeeded();
  Future<List<ScholarshipModel>> getScholarships();
  Stream<List<ScholarshipModel>> watchScholarships();
  Future<ScholarshipModel?> getScholarshipById(String id);
  Future<List<EntranceExamModel>> getExams();
  Stream<List<EntranceExamModel>> watchExams();
  Future<EntranceExamModel?> getExamById(String id);
  Future<List<CutoffRecordModel>> getCutoffs({String? examId});
  Stream<List<CutoffRecordModel>> watchCutoffs({String? examId});
  Future<AdmissionPredictionModel> savePrediction(AdmissionPredictionModel prediction);
  Stream<List<AdmissionPredictionModel>> watchUserPredictions(String userId);
  Future<void> deletePrediction(String predictionId);
  Future<void> saveScholarship(String userId, String scholarshipId);
  Future<void> unsaveScholarship(String userId, String scholarshipId);
  Stream<Set<String>> watchSavedScholarshipIds(String userId);
  Future<bool> isScholarshipSaved(String userId, String scholarshipId);
}

class AdmissionRepositoryImpl implements AdmissionRepository {
  final FirestoreAdmissionService _service;

  AdmissionRepositoryImpl(this._service);

  @override
  Future<void> ensureSeeded() => _service.ensureSeeded();

  @override
  Future<List<ScholarshipModel>> getScholarships() => _service.getScholarships();

  @override
  Stream<List<ScholarshipModel>> watchScholarships() => _service.watchScholarships();

  @override
  Future<ScholarshipModel?> getScholarshipById(String id) =>
      _service.getScholarshipById(id);

  @override
  Future<List<EntranceExamModel>> getExams() => _service.getExams();

  @override
  Stream<List<EntranceExamModel>> watchExams() => _service.watchExams();

  @override
  Future<EntranceExamModel?> getExamById(String id) => _service.getExamById(id);

  @override
  Future<List<CutoffRecordModel>> getCutoffs({String? examId}) =>
      _service.getCutoffs(examId: examId);

  @override
  Stream<List<CutoffRecordModel>> watchCutoffs({String? examId}) =>
      _service.watchCutoffs(examId: examId);

  @override
  Future<AdmissionPredictionModel> savePrediction(AdmissionPredictionModel prediction) =>
      _service.savePrediction(prediction);

  @override
  Stream<List<AdmissionPredictionModel>> watchUserPredictions(String userId) =>
      _service.watchUserPredictions(userId);

  @override
  Future<void> deletePrediction(String predictionId) =>
      _service.deletePrediction(predictionId);

  @override
  Future<void> saveScholarship(String userId, String scholarshipId) =>
      _service.saveScholarship(userId, scholarshipId);

  @override
  Future<void> unsaveScholarship(String userId, String scholarshipId) =>
      _service.unsaveScholarship(userId, scholarshipId);

  @override
  Stream<Set<String>> watchSavedScholarshipIds(String userId) =>
      _service.watchSavedScholarshipIds(userId);

  @override
  Future<bool> isScholarshipSaved(String userId, String scholarshipId) =>
      _service.isScholarshipSaved(userId, scholarshipId);
}
