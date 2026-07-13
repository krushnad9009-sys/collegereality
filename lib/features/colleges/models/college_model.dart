import '../../../core/constants/college_constants.dart';
import '../utils/college_search_utils.dart';

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

  CollegeFees copyWith({
    int? tuitionMin,
    int? tuitionMax,
    int? hostelAnnual,
  }) {
    return CollegeFees(
      tuitionMin: tuitionMin ?? this.tuitionMin,
      tuitionMax: tuitionMax ?? this.tuitionMax,
      hostelAnnual: hostelAnnual ?? this.hostelAnnual,
    );
  }
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

  CollegePlacements copyWith({
    double? highestPackageLpa,
    double? averagePackageLpa,
    int? placementPercentage,
    List<String>? topRecruiters,
  }) {
    return CollegePlacements(
      highestPackageLpa: highestPackageLpa ?? this.highestPackageLpa,
      averagePackageLpa: averagePackageLpa ?? this.averagePackageLpa,
      placementPercentage: placementPercentage ?? this.placementPercentage,
      topRecruiters: topRecruiters ?? this.topRecruiters,
    );
  }
}

class CollegeRatings {
  final double overall;
  final double faculty;
  final double infrastructure;
  final double placements;
  final double campusLife;
  final double hostel;
  final double fees;
  final double teaching;
  final double labs;
  final double library;
  final double sports;
  final double food;
  final double attendance;
  final double safety;

  const CollegeRatings({
    required this.overall,
    required this.faculty,
    required this.infrastructure,
    required this.placements,
    required this.campusLife,
    this.hostel = 0,
    this.fees = 0,
    this.teaching = 0,
    this.labs = 0,
    this.library = 0,
    this.sports = 0,
    this.food = 0,
    this.attendance = 0,
    this.safety = 0,
  });

  double ratingFor(String key) {
    switch (key) {
      case 'overall':
        return overall;
      case 'teaching':
        return teaching;
      case 'placements':
        return placements;
      case 'faculty':
        return faculty;
      case 'labs':
        return labs;
      case 'library':
        return library;
      case 'sports':
        return sports;
      case 'food':
        return food;
      case 'hostel':
        return hostel;
      case 'attendance':
        return attendance;
      case 'infrastructure':
        return infrastructure;
      case 'safety':
        return safety;
      default:
        return 0;
    }
  }

  factory CollegeRatings.fromJson(Map<String, dynamic> json) {
    return CollegeRatings(
      overall: (json['overall'] as num?)?.toDouble() ?? 0,
      faculty: (json['faculty'] as num?)?.toDouble() ?? 0,
      infrastructure: (json['infrastructure'] as num?)?.toDouble() ?? 0,
      placements: (json['placements'] as num?)?.toDouble() ?? 0,
      campusLife: (json['campusLife'] as num?)?.toDouble() ?? 0,
      hostel: (json['hostel'] as num?)?.toDouble() ?? 0,
      fees: (json['fees'] as num?)?.toDouble() ?? 0,
      teaching: (json['teaching'] as num?)?.toDouble() ?? 0,
      labs: (json['labs'] as num?)?.toDouble() ?? 0,
      library: (json['library'] as num?)?.toDouble() ?? 0,
      sports: (json['sports'] as num?)?.toDouble() ?? 0,
      food: (json['food'] as num?)?.toDouble() ?? 0,
      attendance: (json['attendance'] as num?)?.toDouble() ?? 0,
      safety: (json['safety'] as num?)?.toDouble() ?? 0,
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
        'teaching': teaching,
        'labs': labs,
        'library': library,
        'sports': sports,
        'food': food,
        'attendance': attendance,
        'safety': safety,
      };
}

class CollegeAccreditation {
  final String? naacGrade;
  final String? naacCycle;
  final int? nirfRank;
  final String? nirfCategory;
  final bool ugcRecognized;
  final bool aicteApproved;

  const CollegeAccreditation({
    this.naacGrade,
    this.naacCycle,
    this.nirfRank,
    this.nirfCategory,
    this.ugcRecognized = false,
    this.aicteApproved = false,
  });

  factory CollegeAccreditation.fromJson(Map<String, dynamic> json) {
    return CollegeAccreditation(
      naacGrade: json['naacGrade'] as String?,
      naacCycle: json['naacCycle'] as String?,
      nirfRank: (json['nirfRank'] as num?)?.toInt(),
      nirfCategory: json['nirfCategory'] as String?,
      ugcRecognized: json['ugcRecognized'] as bool? ?? false,
      aicteApproved: json['aicteApproved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'naacGrade': naacGrade,
        'naacCycle': naacCycle,
        'nirfRank': nirfRank,
        'nirfCategory': nirfCategory,
        'ugcRecognized': ugcRecognized,
        'aicteApproved': aicteApproved,
      };

  CollegeAccreditation copyWith({
    String? naacGrade,
    String? naacCycle,
    int? nirfRank,
    String? nirfCategory,
    bool? ugcRecognized,
    bool? aicteApproved,
  }) {
    return CollegeAccreditation(
      naacGrade: naacGrade ?? this.naacGrade,
      naacCycle: naacCycle ?? this.naacCycle,
      nirfRank: nirfRank ?? this.nirfRank,
      nirfCategory: nirfCategory ?? this.nirfCategory,
      ugcRecognized: ugcRecognized ?? this.ugcRecognized,
      aicteApproved: aicteApproved ?? this.aicteApproved,
    );
  }
}

class CollegeHostel {
  final bool available;
  final bool boysHostel;
  final bool girlsHostel;
  final bool acAvailable;
  final bool messIncluded;
  final int annualFee;
  final List<String> amenities;
  final String? description;

  const CollegeHostel({
    this.available = false,
    this.boysHostel = false,
    this.girlsHostel = false,
    this.acAvailable = false,
    this.messIncluded = false,
    this.annualFee = 0,
    this.amenities = const [],
    this.description,
  });

  factory CollegeHostel.fromJson(Map<String, dynamic> json) {
    return CollegeHostel(
      available: json['available'] as bool? ?? false,
      boysHostel: json['boysHostel'] as bool? ?? false,
      girlsHostel: json['girlsHostel'] as bool? ?? false,
      acAvailable: json['acAvailable'] as bool? ?? false,
      messIncluded: json['messIncluded'] as bool? ?? false,
      annualFee: (json['annualFee'] as num?)?.toInt() ?? 0,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'available': available,
        'boysHostel': boysHostel,
        'girlsHostel': girlsHostel,
        'acAvailable': acAvailable,
        'messIncluded': messIncluded,
        'annualFee': annualFee,
        'amenities': amenities,
        'description': description,
      };

  CollegeHostel copyWith({
    bool? available,
    bool? boysHostel,
    bool? girlsHostel,
    bool? acAvailable,
    bool? messIncluded,
    int? annualFee,
    List<String>? amenities,
    String? description,
  }) {
    return CollegeHostel(
      available: available ?? this.available,
      boysHostel: boysHostel ?? this.boysHostel,
      girlsHostel: girlsHostel ?? this.girlsHostel,
      acAvailable: acAvailable ?? this.acAvailable,
      messIncluded: messIncluded ?? this.messIncluded,
      annualFee: annualFee ?? this.annualFee,
      amenities: amenities ?? this.amenities,
      description: description ?? this.description,
    );
  }
}

class CollegeCourse {
  final String name;
  final String degree;
  final String duration;
  final int seats;
  final int? annualFees;

  const CollegeCourse({
    required this.name,
    this.degree = '',
    this.duration = '',
    this.seats = 0,
    this.annualFees,
  });

  factory CollegeCourse.fromJson(Map<String, dynamic> json) {
    return CollegeCourse(
      name: json['name'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      seats: (json['seats'] as num?)?.toInt() ?? 0,
      annualFees: (json['annualFees'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'degree': degree,
        'duration': duration,
        'seats': seats,
        'annualFees': annualFees,
      };
}

class CollegeModel {
  final String id;
  final String name;
  final String nameLower;
  final String slug;
  final String city;
  final String state;
  final String address;
  final String type;
  final List<String> courses;
  final List<CollegeCourse> coursesDetailed;
  final String? website;
  final String? logoUrl;
  final String? coverPhotoUrl;
  final List<String> photoUrls;
  final double? latitude;
  final double? longitude;
  final String? googleMapsUrl;
  final String? universityName;
  final String? phone;
  final String? email;
  final List<String> officialLinks;
  final String cityLower;
  final String universityLower;
  final String stateLower;
  final CollegeFees fees;
  final List<CollegeScholarship> scholarships;
  final CollegePlacements placements;
  final CollegeHostel hostel;
  final CollegeAccreditation accreditation;
  final CollegeRatings aggregatedRatings;
  final int reviewCount;
  final Map<String, int> ratingDistribution;
  final List<String> searchKeywords;
  final List<String> searchTokens;
  final bool isActive;
  final bool isFeatured;
  final String? adminNotes;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CollegeModel({
    required this.id,
    required this.name,
    required this.nameLower,
    required this.slug,
    required this.city,
    required this.state,
    required this.address,
    required this.type,
    required this.courses,
    this.coursesDetailed = const [],
    this.website,
    this.logoUrl,
    this.coverPhotoUrl,
    this.photoUrls = const [],
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
    this.universityName,
    this.phone,
    this.email,
    this.officialLinks = const [],
    String? cityLower,
    String? universityLower,
    String? stateLower,
    required this.fees,
    this.scholarships = const [],
    required this.placements,
    this.hostel = const CollegeHostel(),
    this.accreditation = const CollegeAccreditation(),
    required this.aggregatedRatings,
    this.reviewCount = 0,
    this.ratingDistribution = const {},
    this.searchKeywords = const [],
    this.searchTokens = const [],
    this.isActive = true,
    this.isFeatured = false,
    this.adminNotes,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  })  : cityLower = cityLower ?? CollegeSearchUtils.normalizeCity(city),
        universityLower =
            universityLower ?? CollegeSearchUtils.normalizeUniversity(universityName),
        stateLower = stateLower ?? CollegeSearchUtils.normalizeState(state);

  String get locationLabel => '$city, $state';

  String get mapsLink {
    if (googleMapsUrl != null && googleMapsUrl!.trim().isNotEmpty) {
      return googleMapsUrl!.trim();
    }
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    final encoded = Uri.encodeComponent('$name, $address, $city, $state');
    return 'https://www.google.com/maps/search/?api=1&query=$encoded';
  }

  List<String> get displayCourses {
    if (coursesDetailed.isNotEmpty) {
      return coursesDetailed.map((c) => c.name).toList();
    }
    return courses;
  }

  factory CollegeModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    final name = json['name'] as String? ?? '';
    return CollegeModel(
      id: docId ?? json['id'] as String? ?? '',
      name: name,
      nameLower: json['nameLower'] as String? ??
          CollegeSearchUtils.normalizeName(name),
      slug: json['slug'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      address: json['address'] as String? ?? '',
      type: json['type'] as String? ?? 'private',
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      coursesDetailed: (json['coursesDetailed'] as List<dynamic>?)
              ?.map((e) => CollegeCourse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      website: json['website'] as String?,
      logoUrl: json['logoUrl'] as String?,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      googleMapsUrl: json['googleMapsUrl'] as String?,
      universityName: json['universityName'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      officialLinks: (json['officialLinks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      cityLower: json['cityLower'] as String? ??
          CollegeSearchUtils.normalizeCity(json['city'] as String? ?? ''),
      universityLower: json['universityLower'] as String? ??
          CollegeSearchUtils.normalizeUniversity(json['universityName'] as String?),
      stateLower: json['stateLower'] as String? ??
          CollegeSearchUtils.normalizeState(json['state'] as String? ?? ''),
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
      hostel: CollegeHostel.fromJson(
        (json['hostel'] as Map<String, dynamic>?) ?? {},
      ),
      accreditation: CollegeAccreditation.fromJson(
        (json['accreditation'] as Map<String, dynamic>?) ?? {},
      ),
      aggregatedRatings: CollegeRatings.fromJson(
        (json['aggregatedRatings'] as Map<String, dynamic>?) ?? {},
      ),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      ratingDistribution:
          (json['ratingDistribution'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
              {},
      searchKeywords: (json['searchKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      searchTokens: (json['searchTokens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      adminNotes: json['adminNotes'] as String?,
      updatedBy: json['updatedBy'] as String?,
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
    final tokens = searchTokens.isNotEmpty
        ? searchTokens
        : CollegeSearchUtils.buildSearchTokens(
            name: name,
            city: city,
            state: state,
            courses: courses,
          );
    return {
      'id': id,
      'name': name,
      'nameLower': nameLower.isNotEmpty
          ? nameLower
          : CollegeSearchUtils.normalizeName(name),
      'slug': slug.isNotEmpty ? slug : CollegeSearchUtils.buildSlug(name, city),
      'city': city,
      'state': state,
      'address': address,
      'type': type,
      'courses': courses,
      'coursesDetailed': coursesDetailed.map((e) => e.toJson()).toList(),
      'website': website,
      'logoUrl': logoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'photoUrls': photoUrls,
      'latitude': latitude,
      'longitude': longitude,
      'googleMapsUrl': googleMapsUrl,
      'universityName': universityName,
      'phone': phone,
      'email': email,
      'officialLinks': officialLinks,
      'cityLower': cityLower.isNotEmpty
          ? cityLower
          : CollegeSearchUtils.normalizeCity(city),
      'universityLower': universityLower.isNotEmpty
          ? universityLower
          : CollegeSearchUtils.normalizeUniversity(universityName),
      'stateLower': stateLower.isNotEmpty
          ? stateLower
          : CollegeSearchUtils.normalizeState(state),
      'fees': fees.toJson(),
      'scholarships': scholarships.map((e) => e.toJson()).toList(),
      'placements': placements.toJson(),
      'hostel': hostel.toJson(),
      'accreditation': accreditation.toJson(),
      'aggregatedRatings': aggregatedRatings.toJson(),
      'reviewCount': reviewCount,
      'ratingDistribution': ratingDistribution,
      'searchKeywords': searchKeywords,
      'searchTokens': tokens,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'adminNotes': adminNotes,
      'updatedBy': updatedBy,
      'createdAt': createdAt?.toIso8601String() ?? now,
      'updatedAt': updatedAt?.toIso8601String() ?? now,
    };
  }

  CollegeModel copyWith({
    String? id,
    String? name,
    String? nameLower,
    String? slug,
    String? city,
    String? state,
    String? address,
    String? type,
    List<String>? courses,
    List<CollegeCourse>? coursesDetailed,
    String? website,
    String? logoUrl,
    String? coverPhotoUrl,
    List<String>? photoUrls,
    double? latitude,
    double? longitude,
    String? googleMapsUrl,
    String? universityName,
    String? phone,
    String? email,
    List<String>? officialLinks,
    String? cityLower,
    String? universityLower,
    String? stateLower,
    CollegeFees? fees,
    List<CollegeScholarship>? scholarships,
    CollegePlacements? placements,
    CollegeHostel? hostel,
    CollegeAccreditation? accreditation,
    CollegeRatings? aggregatedRatings,
    int? reviewCount,
    Map<String, int>? ratingDistribution,
    List<String>? searchKeywords,
    List<String>? searchTokens,
    bool? isActive,
    bool? isFeatured,
    String? adminNotes,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final nextName = name ?? this.name;
    final nextCity = city ?? this.city;
    final nextState = state ?? this.state;
    final nextUniversity = universityName ?? this.universityName;
    return CollegeModel(
      id: id ?? this.id,
      name: nextName,
      nameLower: nameLower ?? CollegeSearchUtils.normalizeName(nextName),
      slug: slug ?? this.slug,
      city: nextCity,
      state: nextState,
      address: address ?? this.address,
      type: type ?? this.type,
      courses: courses ?? this.courses,
      coursesDetailed: coursesDetailed ?? this.coursesDetailed,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      photoUrls: photoUrls ?? this.photoUrls,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      universityName: nextUniversity,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      officialLinks: officialLinks ?? this.officialLinks,
      cityLower: cityLower ?? CollegeSearchUtils.normalizeCity(nextCity),
      universityLower: universityLower ??
          CollegeSearchUtils.normalizeUniversity(nextUniversity),
      stateLower: stateLower ?? CollegeSearchUtils.normalizeState(nextState),
      fees: fees ?? this.fees,
      scholarships: scholarships ?? this.scholarships,
      placements: placements ?? this.placements,
      hostel: hostel ?? this.hostel,
      accreditation: accreditation ?? this.accreditation,
      aggregatedRatings: aggregatedRatings ?? this.aggregatedRatings,
      reviewCount: reviewCount ?? this.reviewCount,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      searchTokens: searchTokens ?? this.searchTokens,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      adminNotes: adminNotes ?? this.adminNotes,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static CollegeModel createDraft({required String id}) {
    return CollegeModel(
      id: id,
      name: '',
      nameLower: '',
      slug: '',
      city: '',
      state: CollegeConstants.indianStates.first,
      address: '',
      type: CollegeConstants.collegeTypes.first,
      courses: const [],
      fees: const CollegeFees(tuitionMin: 0, tuitionMax: 0, hostelAnnual: 0),
      placements: const CollegePlacements(
        highestPackageLpa: 0,
        averagePackageLpa: 0,
        placementPercentage: 0,
      ),
      aggregatedRatings: const CollegeRatings(
        overall: 0,
        faculty: 0,
        infrastructure: 0,
        placements: 0,
        campusLife: 0,
      ),
    );
  }
}

class CollegeSearchPage {
  final List<CollegeModel> colleges;
  final String? lastDocumentId;
  final bool hasMore;

  const CollegeSearchPage({
    required this.colleges,
    this.lastDocumentId,
    this.hasMore = false,
  });
}

class CollegeDirectoryMeta {
  final List<String> states;
  final List<String> courses;
  final int totalColleges;
  final DateTime? updatedAt;

  const CollegeDirectoryMeta({
    this.states = CollegeConstants.indianStates,
    this.courses = CollegeConstants.popularCourses,
    this.totalColleges = 0,
    this.updatedAt,
  });

  factory CollegeDirectoryMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CollegeDirectoryMeta();
    return CollegeDirectoryMeta(
      states: (json['states'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          CollegeConstants.indianStates,
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          CollegeConstants.popularCourses,
      totalColleges: (json['totalColleges'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
