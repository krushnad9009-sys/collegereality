import 'dart:convert';

import 'package:flutter/services.dart';
import '../models/college_model.dart';
import '../services/firestore_college_service.dart';

abstract class CollegeRepository {
  Future<List<CollegeModel>> getColleges();
  Stream<List<CollegeModel>> watchColleges();
  Future<CollegeModel?> getCollegeById(String id);
  Future<List<CollegeModel>> search({
    String? query,
    String? city,
    String? state,
  });
  Future<void> seedCollegesIfNeeded();
}

class CollegeRepositoryImpl implements CollegeRepository {
  final FirestoreCollegeService _service;

  CollegeRepositoryImpl(this._service);

  List<CollegeModel>? _cachedAssetColleges;

  @override
  Future<List<CollegeModel>> getColleges() async {
    try {
      final colleges = await _service.getAllColleges();
      if (colleges.isNotEmpty) return colleges;
    } catch (_) {
      // Fall back to asset data when Firestore is unavailable.
    }
    return _loadFromAssets();
  }

  @override
  Stream<List<CollegeModel>> watchColleges() {
    return _service.watchColleges().handleError((_) async* {
      yield await _loadFromAssets();
    });
  }

  @override
  Future<CollegeModel?> getCollegeById(String id) async {
    try {
      final college = await _service.getCollegeById(id);
      if (college != null) return college;
    } catch (_) {
      // Fall back to asset data.
    }
    final assetColleges = await _loadFromAssets();
    for (final college in assetColleges) {
      if (college.id == id) return college;
    }
    return null;
  }

  @override
  Future<List<CollegeModel>> search({
    String? query,
    String? city,
    String? state,
  }) async {
    List<CollegeModel> colleges;
    try {
      if (city != null && city.isNotEmpty) {
        colleges = await _service.searchByCity(city);
      } else if (state != null && state.isNotEmpty) {
        colleges = await _service.searchByState(state);
      } else {
        colleges = await getColleges();
      }
    } catch (_) {
      colleges = await _loadFromAssets();
    }

    if (query != null && query.trim().isNotEmpty) {
      colleges = colleges.where((c) => c.matchesQuery(query)).toList();
    }

    colleges.sort(
      (a, b) => b.aggregatedRatings.overall.compareTo(a.aggregatedRatings.overall),
    );
    return colleges;
  }

  @override
  Future<void> seedCollegesIfNeeded() async {
    try {
      final alreadySeeded = await _service.isSeeded();
      if (alreadySeeded) return;

      final count = await _service.getCollegeCount();
      if (count > 0) {
        await _service.markSeeded();
        return;
      }

      final colleges = await _loadFromAssets();
      await _service.batchCreateColleges(colleges);
      await _service.markSeeded();
    } catch (_) {
      // Seeding is best-effort; asset fallback keeps the app usable.
    }
  }

  Future<List<CollegeModel>> _loadFromAssets() async {
    if (_cachedAssetColleges != null) return _cachedAssetColleges!;

    final jsonString =
        await rootBundle.loadString('assets/data/colleges_seed.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    _cachedAssetColleges = jsonList
        .map((e) => CollegeModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cachedAssetColleges!;
  }
}
