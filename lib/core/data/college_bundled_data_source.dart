import 'dart:convert';

import 'package:flutter/services.dart';

import '../../features/colleges/models/college_model.dart';
import '../../features/colleges/utils/college_search_utils.dart';
import '../utils/college_image_helper.dart';

/// In-memory access to bundled college JSON for offline / quota fallback.
class CollegeBundledDataSource {
  CollegeBundledDataSource._();

  static List<CollegeModel>? _cache;

  static const int minimumFallbackCount = 20;

  static Future<List<CollegeModel>> loadAll() async {
    if (_cache != null && _cache!.isNotEmpty) return _cache!;

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
    await loadAsset('assets/data/india_colleges_seed.json');

    _cache = merged.values.toList();
    return _cache!;
  }

  static Future<List<CollegeModel>> featuredFallback({int limit = 24}) async {
    final all = await loadAll();
    return _prioritize(all, limit: limit < minimumFallbackCount ? minimumFallbackCount : limit);
  }

  static Future<List<CollegeModel>> trendingFallback({int limit = 12}) async {
    final featured = await featuredFallback(limit: minimumFallbackCount);
    return featured.take(limit).toList();
  }

  static Future<List<CollegeModel>> topRatedFallback({int limit = 8}) async {
    final all = await loadAll();
    final sorted = [...all]
      ..sort(
        (a, b) =>
            b.aggregatedRatings.overall.compareTo(a.aggregatedRatings.overall),
      );
    final results = sorted.take(limit).toList();
    if (results.length >= limit) return results;
    return _prioritize(all, limit: limit < minimumFallbackCount ? minimumFallbackCount : limit)
        .take(limit)
        .toList();
  }

  static Future<CollegeSearchPage> search({
    String? query,
    String? state,
    String? city,
    String? course,
    String? category,
    int limit = 24,
    bool includeInactive = false,
  }) async {
    final all = await loadAll();
    var results = all.where((c) => includeInactive || c.isActive).toList();

    if (state != null && state.isNotEmpty) {
      results = results.where((c) => c.state == state).toList();
    }
    if (city != null && city.isNotEmpty) {
      final cityLower = CollegeSearchUtils.normalizeCity(city);
      results = results
          .where(
            (c) =>
                c.cityLower.contains(cityLower) ||
                c.districtLower.contains(cityLower),
          )
          .toList();
    }
    if (course != null && course.isNotEmpty) {
      results = results.where((c) => c.courses.contains(course)).toList();
    }
    if (category != null && category.isNotEmpty) {
      results = results.where((c) => c.category == category).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      results = results
          .where((c) => CollegeSearchUtils.matchesQuery(c, query.trim()))
          .toList();
    }

    final page = results.take(limit).toList();
    return CollegeSearchPage(
      colleges: page,
      lastDocumentId: page.isEmpty ? null : page.last.id,
      hasMore: results.length > limit,
    );
  }

  static Future<List<CollegeModel>> autocomplete(String query, {int limit = 12}) async {
    if (query.trim().isEmpty) return [];
    final page = await search(query: query, limit: limit);
    return page.colleges;
  }

  static List<CollegeModel> _prioritize(List<CollegeModel> colleges, {required int limit}) {
    final sorted = [...colleges]
      ..sort((a, b) {
        final featuredCompare =
            (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
        if (featuredCompare != 0) return featuredCompare;

        final photoCompare = (_hasCover(b) ? 1 : 0).compareTo(_hasCover(a) ? 1 : 0);
        if (photoCompare != 0) return photoCompare;

        final ratingCompare = b.aggregatedRatings.overall
            .compareTo(a.aggregatedRatings.overall);
        if (ratingCompare != 0) return ratingCompare;

        return a.nameLower.compareTo(b.nameLower);
      });
    return sorted.take(limit).toList();
  }

  static bool _hasCover(CollegeModel college) {
    final url = college.coverPhotoUrl;
    return url != null && url.trim().isNotEmpty && url != 'null';
  }

  static CollegeModel _collegeFromSeedMap(Map<String, dynamic> map) {
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

    final searchKeywords = <String>[
      ...((map['searchKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          []),
    ];
    final category = map['category'] as String?;
    if (category != null && category.isNotEmpty) {
      searchKeywords.add(category.toLowerCase());
    }

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
      category: category ?? 'General',
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
