import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/college_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/utils/firestore_seed_guard.dart';
import '../../../core/utils/college_image_helper.dart';
import '../models/college_model.dart';
import '../utils/college_search_utils.dart';
import 'firestore_college_service.dart';

/// Seeds the college directory from bundled JSON when Firestore is empty.
class CollegeSeedService {
  CollegeSeedService(this._collegeService);

  final FirestoreCollegeService _collegeService;

  Future<bool> ensureSeeded() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return false;
    }

    if (FirestoreSeedGuard.collegeSeedCompleted) return true;

    final alreadySeeded = await FirestoreSeedGuard.isMetaSeeded(
      CollegeConstants.metaDirectoryDoc,
    );
    if (alreadySeeded) {
      FirestoreSeedGuard.completeCollegeSeed();
      return true;
    }

    final hasColleges = await FirestoreSeedGuard.hasSampleData(
      FirebaseFirestore.instance
          .collection(FirestoreConstants.collegesCollection)
          .limit(1)
          .get(),
    );
    if (hasColleges) {
      await _collegeService.updateDirectoryMeta(
        totalColleges: await _collegeService.getCollegeCount(),
      );
      FirestoreSeedGuard.completeCollegeSeed();
      return true;
    }

    if (!FirestoreSeedGuard.tryBeginCollegeSeed()) return false;

    try {
      final colleges = await _loadAllSeedColleges();
      if (colleges.isEmpty) {
        FirestoreSeedGuard.failCollegeSeed();
        return false;
      }
      await _collegeService.batchSeedColleges(colleges);
      await _collegeService.updateDirectoryMeta(
        totalColleges: colleges.length,
        states: CollegeConstants.indianStates,
        courses: CollegeConstants.popularCourses,
        seededAt: DateTime.now(),
      );
      FirestoreSeedGuard.completeCollegeSeed();
      return true;
    } on FirebaseException catch (_) {
      FirestoreSeedGuard.failCollegeSeed();
      return false;
    } catch (_) {
      FirestoreSeedGuard.failCollegeSeed();
      return false;
    }
  }

  Future<List<CollegeModel>> _loadAllSeedColleges() async {
    final merged = <String, CollegeModel>{};

    Future<void> loadAsset(String path) async {
      final raw = await rootBundle.loadString(path);
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final college = _collegeFromSeedMap(item as Map<String, dynamic>);
        merged[college.id] = college;
      }
    }

    await loadAsset('assets/data/colleges_seed.json');
    await loadAsset('assets/data/prominent_colleges_seed.json');
    return merged.values.toList();
  }

  CollegeModel _collegeFromSeedMap(Map<String, dynamic> map) {
    final name = map['name'] as String? ?? '';
    final city = map['city'] as String? ?? '';
    final state = map['state'] as String? ?? '';
    final district = map['district'] as String? ?? city;
    final university = map['universityName'] as String? ?? '';
    final courses = (map['courses'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final id = map['id'] as String? ??
        CollegeSearchUtils.buildSlug(name, city).replaceAll('-', '_');
    final coverPhotoUrl = CollegeImageHelper.resolveCoverUrl(
      map['coverPhotoUrl'] as String?,
      collegeId: id,
    );

    final feesMap = map['fees'] as Map<String, dynamic>? ?? {};
    final placementsMap = map['placements'] as Map<String, dynamic>? ?? {};
    final hostelMap = map['hostel'] as Map<String, dynamic>? ?? {};
    final accreditationMap = map['accreditation'] as Map<String, dynamic>? ?? {};
    final ratingsMap = map['aggregatedRatings'] as Map<String, dynamic>? ?? {};

    final searchKeywords = (map['searchKeywords'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return CollegeModel(
      id: id,
      name: name,
      nameLower: CollegeSearchUtils.normalizeName(name),
      slug: map['slug'] as String? ?? CollegeSearchUtils.buildSlug(name, city),
      city: city,
      district: district,
      state: state,
      address: map['address'] as String? ?? '',
      type: map['type'] as String? ?? 'private',
      courses: courses,
      website: map['website'] as String?,
      coverPhotoUrl: coverPhotoUrl,
      photoUrls: (map['photoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      googleMapsUrl: map['googleMapsUrl'] as String?,
      universityName: university.isEmpty ? null : university,
      fees: CollegeFees.fromJson(feesMap),
      scholarships: (map['scholarships'] as List<dynamic>?)
              ?.map((e) => CollegeScholarship.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      placements: CollegePlacements.fromJson(placementsMap),
      hostel: CollegeHostel.fromJson(hostelMap),
      accreditation: CollegeAccreditation.fromJson(accreditationMap),
      aggregatedRatings: ratingsMap.isEmpty
          ? const CollegeRatings(
              overall: 0,
              faculty: 0,
              infrastructure: 0,
              placements: 0,
              campusLife: 0,
            )
          : CollegeRatings.fromJson(ratingsMap),
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      searchKeywords: searchKeywords,
      searchTokens: CollegeSearchUtils.buildSearchTokens(
        name: name,
        city: city,
        district: district,
        state: state,
        university: university,
        courses: courses,
        keywords: searchKeywords,
      ),
      isActive: map['isActive'] as bool? ?? true,
      isFeatured: map['isFeatured'] as bool? ?? false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
