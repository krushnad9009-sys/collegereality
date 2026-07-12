import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_constants.dart';
import '../models/college_model.dart';

class FirestoreCollegeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _colleges =>
      _firestore.collection(FirestoreConstants.collegesCollection);

  Future<int> getCollegeCount() async {
    final snapshot = await _colleges.limit(1).get();
    if (snapshot.docs.isEmpty) return 0;
    final countSnapshot = await _colleges.count().get();
    return countSnapshot.count ?? 0;
  }

  Future<List<CollegeModel>> getAllColleges() async {
    final snapshot = await _colleges
        .where('isActive', isEqualTo: true)
        .orderBy('aggregatedRatings.overall', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => CollegeModel.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  Stream<List<CollegeModel>> watchColleges() {
    return _colleges
        .where('isActive', isEqualTo: true)
        .orderBy('aggregatedRatings.overall', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CollegeModel.fromJson(doc.data(), docId: doc.id))
            .toList());
  }

  Future<CollegeModel?> getCollegeById(String id) async {
    final doc = await _colleges.doc(id).get();
    if (!doc.exists) return null;
    return CollegeModel.fromJson(doc.data()!, docId: doc.id);
  }

  Future<List<CollegeModel>> searchByCity(String city) async {
    final snapshot = await _colleges
        .where('isActive', isEqualTo: true)
        .where('city', isEqualTo: city)
        .get();
    return snapshot.docs
        .map((doc) => CollegeModel.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  Future<List<CollegeModel>> searchByState(String state) async {
    final snapshot = await _colleges
        .where('isActive', isEqualTo: true)
        .where('state', isEqualTo: state)
        .get();
    return snapshot.docs
        .map((doc) => CollegeModel.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  Future<void> batchCreateColleges(List<CollegeModel> colleges) async {
    const batchSize = 450;
    for (var i = 0; i < colleges.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = colleges.skip(i).take(batchSize);
      for (final college in chunk) {
        batch.set(_colleges.doc(college.id), college.toJson());
      }
      await batch.commit();
    }
  }

  Future<bool> isSeeded() async {
    final doc = await _firestore
        .collection(FirestoreConstants.metaCollection)
        .doc(FirestoreConstants.collegesSeededDoc)
        .get();
    return doc.exists && (doc.data()?['done'] as bool? ?? false);
  }

  Future<void> markSeeded() async {
    await _firestore
        .collection(FirestoreConstants.metaCollection)
        .doc(FirestoreConstants.collegesSeededDoc)
        .set({
      'done': true,
      'seededAt': DateTime.now().toIso8601String(),
      'count': 100,
    });
  }
}

class CollegeFirestoreException implements Exception {
  final String message;
  CollegeFirestoreException({required this.message});
  @override
  String toString() => message;
}
