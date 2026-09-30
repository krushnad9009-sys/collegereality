import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/verification_constants.dart';
import '../../admin/services/admin_action_logger.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/services/firestore_college_service.dart';
import '../../communication/models/public_guide_profile.dart';
import '../../communication/services/communication_firestore_service.dart';
import 'home_featured.dart';

/// Reads/writes the Super Admin-curated Home "Top Picks"
/// (`homepage_featured/current`). Writes are Super Admin-only in
/// firestore.rules; reads are public (the doc holds only ids).
class HomeFeaturedService {
  HomeFeaturedService({
    required this._colleges,
    required this._guides,
    FirebaseFirestore? firestore,
  }) : _firestoreOverride = firestore;

  final FirestoreCollegeService _colleges;
  final CommunicationFirestoreService _guides;
  final FirebaseFirestore? _firestoreOverride;

  static const collection = 'homepage_featured';
  static const docId = 'current';

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection(collection).doc(docId);

  Stream<HomeFeaturedConfig> watch() => _doc
      .snapshots()
      .map((s) => HomeFeaturedConfig.fromJson(s.data()));

  Future<void> save({
    required List<String> collegeIds,
    required List<String> guideIds,
  }) async {
    await _doc.set({
      'collegeIds': collegeIds.take(HomeFeaturedConfig.maxItems).toList(),
      'guideIds': guideIds.take(HomeFeaturedConfig.maxItems).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
    });
    try {
      await AdminActionLogger().log(
        action: 'home.featured.update',
        targetId: docId,
        targetType: collection,
        metadata: {'collegeIds': collegeIds, 'guideIds': guideIds},
      );
    } catch (e) {
      debugPrint('[HomeFeatured] audit log failed: $e');
    }
  }

  /// Colleges in curated order. [activeOnly] (Home) drops deactivated or
  /// deleted colleges; the admin screen passes false to show them flagged.
  Future<List<CollegeModel>> loadColleges(
    List<String> ids, {
    bool activeOnly = true,
  }) async {
    final results = await Future.wait(ids.map((id) async {
      try {
        return await _colleges.getCollegeById(id);
      } catch (_) {
        return null;
      }
    }));
    final byId = <String, CollegeModel>{
      for (final c in results)
        if (c != null && (!activeOnly || c.isActive)) c.id: c,
    };
    return inFeaturedOrder(ids, byId);
  }

  /// Guides in curated order. On Home only guides still in guide mode and
  /// still verified are shown (a pinned guide who went inactive or lost
  /// verification simply drops out rather than showing a dead card).
  Future<List<PublicGuideProfile>> loadGuides(
    List<String> ids, {
    bool availableOnly = true,
  }) async {
    final results = await Future.wait(ids.map((id) async {
      try {
        return await _guides.getPublicGuideProfile(id);
      } catch (_) {
        return null;
      }
    }));
    final byId = <String, PublicGuideProfile>{
      for (final g in results)
        if (g != null &&
            (!availableOnly ||
                VerificationConstants.isApprovedStudentOrAlumni(
                  g.verificationBadge,
                  g.verificationStatus,
                )))
          g.uid: g,
    };
    return inFeaturedOrder(ids, byId);
  }
}
