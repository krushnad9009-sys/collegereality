class CollegeFees {
  final int tuitionMin;
  final int tuitionMax;
  final int hostelAnnual;

  const CollegeFees({
    required this.tuitionMin,
    required this.tuitionMax,
    required this.hostelAnnual,
  });

  factory CollegeFees.fromJson(Map<String, dynamic> json) {
    return CollegeFees(
      tuitionMin: (json['tuitionMin'] as num?)?.toInt() ?? 0,
      tuitionMax: (json['tuitionMax'] as num?)?.toInt() ?? 0,
      hostelAnnual: (json['hostelAnnual'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'tuitionMin': tuitionMin,
        'tuitionMax': tuitionMax,
        'hostelAnnual': hostelAnnual,
      };
}

class CollegeScholarship {
  final String name;
  final String eligibility;
  final String amount;

  const CollegeScholarship({
    required this.name,
    required this.eligibility,
    required this.amount,
  });

  factory CollegeScholarship.fromJson(Map<String, dynamic> json) {
    return CollegeScholarship(
      name: json['name'] as String? ?? '',
      eligibility: json['eligibility'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'eligibility': eligibility,
        'amount': amount,
      };
}

class CollegePlacements {
  final double highestPackageLpa;
  final double averagePackageLpa;
  final int placementPercentage;
  final List<String> topRecruiters;

  const CollegePlacements({
    required this.highestPackageLpa,
    required this.averagePackageLpa,
    required this.placementPercentage,
    this.topRecruiters = const [],
  });

  factory CollegePlacements.fromJson(Map<String, dynamic> json) {
    return CollegePlacements(
      highestPackageLpa: (json['highestPackageLpa'] as num?)?.toDouble() ?? 0,
      averagePackageLpa: (json['averagePackageLpa'] as num?)?.toDouble() ?? 0,
      placementPercentage: (json['placementPercentage'] as num?)?.toInt() ?? 0,
      topRecruiters: (json['topRecruiters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'highestPackageLpa': highestPackageLpa,
        'averagePackageLpa': averagePackageLpa,
        'placementPercentage': placementPercentage,
        'topRecruiters': topRecruiters,
      };
}

class CollegeRatings {
  final double overall;
  final double faculty;
  final double infrastructure;
  final double placements;
  final double campusLife;
  final double hostel;
  final double fees;

  const CollegeRatings({
    required this.overall,
    required this.faculty,
    required this.infrastructure,
    required this.placements,
    required this.campusLife,
    this.hostel = 0,
    this.fees = 0,
  });

  factory CollegeRatings.fromJson(Map<String, dynamic> json) {
    return CollegeRatings(
      overall: (json['overall'] as num?)?.toDouble() ?? 0,
      faculty: (json['faculty'] as num?)?.toDouble() ?? 0,
      infrastructure: (json['infrastructure'] as num?)?.toDouble() ?? 0,
      placements: (json['placements'] as num?)?.toDouble() ?? 0,
      campusLife: (json['campusLife'] as num?)?.toDouble() ?? 0,
      hostel: (json['hostel'] as num?)?.toDouble() ?? 0,
      fees: (json['fees'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'faculty': faculty,
        'infrastructure': infrastructure,
        'placements': placements,
        'campusLife': campusLife,
        'hostel': hostel,
        'fees': fees,
      };
}

class CollegeModel {
  final String id;
  final String name;
  final String slug;
  final String city;
  final String state;
  final String address;
  final String type;
  final List<String> courses;
  final String? website;
  final String? coverPhotoUrl;
  final List<String> photoUrls;
  final CollegeFees fees;
  final List<CollegeScholarship> scholarships;
  final CollegePlacements placements;
  final CollegeRatings aggregatedRatings;
  final int reviewCount;
  final List<String> searchKeywords;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CollegeModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.city,
    required this.state,
    required this.address,
    required this.type,
    required this.courses,
    this.website,
    this.coverPhotoUrl,
    this.photoUrls = const [],
    required this.fees,
    this.scholarships = const [],
    required this.placements,
    required this.aggregatedRatings,
    this.reviewCount = 0,
    this.searchKeywords = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  String get locationLabel => '$city, $state';

  factory CollegeModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CollegeModel(
      id: docId ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      address: json['address'] as String? ?? '',
      type: json['type'] as String? ?? 'private',
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      website: json['website'] as String?,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fees: CollegeFees.fromJson(
        (json['fees'] as Map<String, dynamic>?) ?? {},
      ),
      scholarships: (json['scholarships'] as List<dynamic>?)
              ?.map((e) => CollegeScholarship.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      placements: CollegePlacements.fromJson(
        (json['placements'] as Map<String, dynamic>?) ?? {},
      ),
      aggregatedRatings: CollegeRatings.fromJson(
        (json['aggregatedRatings'] as Map<String, dynamic>?) ?? {},
      ),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      searchKeywords: (json['searchKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'city': city,
      'state': state,
      'address': address,
      'type': type,
      'courses': courses,
      'website': website,
      'coverPhotoUrl': coverPhotoUrl,
      'photoUrls': photoUrls,
      'fees': fees.toJson(),
      'scholarships': scholarships.map((e) => e.toJson()).toList(),
      'placements': placements.toJson(),
      'aggregatedRatings': aggregatedRatings.toJson(),
      'reviewCount': reviewCount,
      'searchKeywords': searchKeywords,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String() ?? now,
      'updatedAt': updatedAt?.toIso8601String() ?? now,
    };
  }

  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase().trim();
    return name.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        state.toLowerCase().contains(q) ||
        courses.any((c) => c.toLowerCase().contains(q)) ||
        searchKeywords.any((k) => k.contains(q));
  }

  bool matchesCourse(String? course) {
    if (course == null || course.isEmpty) return true;
    final c = course.toLowerCase();
    return courses.any((item) => item.toLowerCase().contains(c));
  }
}
