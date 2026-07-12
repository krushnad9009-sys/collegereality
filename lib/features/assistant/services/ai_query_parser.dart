import '../../../core/constants/college_constants.dart';
import '../models/ai_query_intent.dart';

/// Multilingual (English, Hindi, Marathi) rule-based NL parser.
/// Produces structured intents — no LLM, no hallucination risk.
class AiQueryParser {
  static final RegExp _feePattern = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:lakh|lac|lakhs|lacs|लाख|lak)',
    caseSensitive: false,
  );

  static final RegExp _naacPattern = RegExp(
    r'naac\s*(a\+\+|a\+|a\s*\+\+|a\s*\+|a\b|b\+\+|b\+|b)',
    caseSensitive: false,
  );

  static const _cityAliases = <String, String>{
    'pune': 'Pune',
    'pun': 'Pune',
    'mumbai': 'Mumbai',
    'bombay': 'Mumbai',
    'delhi': 'Delhi',
    'new delhi': 'Delhi',
    'bangalore': 'Bengaluru',
    'bengaluru': 'Bengaluru',
    'hyderabad': 'Hyderabad',
    'chennai': 'Chennai',
    'kolkata': 'Kolkata',
    'calcutta': 'Kolkata',
    'nagpur': 'Nagpur',
    'nashik': 'Nashik',
    'aurangabad': 'Aurangabad',
    'thane': 'Thane',
    'pimpri': 'Pimpri-Chinchwad',
    'pcmc': 'Pimpri-Chinchwad',
    'indore': 'Indore',
    'bhopal': 'Bhopal',
    'jaipur': 'Jaipur',
    'lucknow': 'Lucknow',
    'chandigarh': 'Chandigarh',
    'vadodara': 'Vadodara',
    'baroda': 'Vadodara',
    'surat': 'Surat',
    'ahmedabad': 'Ahmedabad',
    'coimbatore': 'Coimbatore',
    'vishakhapatnam': 'Visakhapatnam',
    'visakhapatnam': 'Visakhapatnam',
    'vijayawada': 'Vijayawada',
    'kochi': 'Kochi',
    'trivandrum': 'Thiruvananthapuram',
    'thiruvananthapuram': 'Thiruvananthapuram',
    'mysore': 'Mysuru',
    'mysuru': 'Mysuru',
    'gurgaon': 'Gurugram',
    'gurugram': 'Gurugram',
    'noida': 'Noida',
    'ghaziabad': 'Ghaziabad',
    'ludhiana': 'Ludhiana',
    'amritsar': 'Amritsar',
    'patna': 'Patna',
    'ranchi': 'Ranchi',
    'raipur': 'Raipur',
    'bhubaneswar': 'Bhubaneswar',
    'guwahati': 'Guwahati',
    'dehradun': 'Dehradun',
    'shimla': 'Shimla',
    'goa': 'Panaji',
    'panaji': 'Panaji',
    'मुंबई': 'Mumbai',
    'पुणे': 'Pune',
    'नागपूर': 'Nagpur',
    'नाशिक': 'Nashik',
    'औरंगाबाद': 'Aurangabad',
  };

  static const _stateAliases = <String, String>{
    'maharashtra': 'Maharashtra',
    'maharashtr': 'Maharashtra',
    'karnataka': 'Karnataka',
    'tamil nadu': 'Tamil Nadu',
    'tamilnadu': 'Tamil Nadu',
    'uttar pradesh': 'Uttar Pradesh',
    'up': 'Uttar Pradesh',
    'madhya pradesh': 'Madhya Pradesh',
    'mp': 'Madhya Pradesh',
    'west bengal': 'West Bengal',
    'gujarat': 'Gujarat',
    'rajasthan': 'Rajasthan',
    'punjab': 'Punjab',
    'haryana': 'Haryana',
    'kerala': 'Kerala',
    'telangana': 'Telangana',
    'andhra pradesh': 'Andhra Pradesh',
    'bihar': 'Bihar',
    'odisha': 'Odisha',
    'orissa': 'Odisha',
    'delhi': 'Delhi',
    'goa': 'Goa',
    'assam': 'Assam',
    'jharkhand': 'Jharkhand',
    'chhattisgarh': 'Chhattisgarh',
    'uttarakhand': 'Uttarakhand',
    'himachal pradesh': 'Himachal Pradesh',
    'jammu and kashmir': 'Jammu and Kashmir',
    'महाराष्ट्र': 'Maharashtra',
    'कर्नाटक': 'Karnataka',
  };

  static const _courseKeywords = <String, String>{
    'mba': 'MBA',
    'm.b.a': 'MBA',
    'mbbs': 'MBBS',
    'b.tech': 'B.Tech',
    'btech': 'B.Tech',
    'b tech': 'B.Tech',
    'b.e.': 'B.E.',
    'be': 'B.E.',
    'b.e': 'B.E.',
    'engineering': 'B.Tech',
    'इंजिनियरिंग': 'B.Tech',
    'अभियांत्रिकी': 'B.Tech',
    'bba': 'BBA',
    'bca': 'BCA',
    'b.com': 'B.Com',
    'bcom': 'B.Com',
    'b.sc': 'B.Sc',
    'bsc': 'B.Sc',
    'm.tech': 'M.Tech',
    'mtech': 'M.Tech',
    'b.pharm': 'B.Pharm',
    'bpharm': 'B.Pharm',
    'b.arch': 'B.Arch',
    'barch': 'B.Arch',
    'llb': 'LLB',
    'bds': 'BDS',
    'mca': 'MCA',
  };

  AiQueryIntent parse(
    String rawQuery, {
    List<String> contextCollegeIds = const [],
    String? userCity,
    String? userState,
  }) {
    final normalized = _normalize(rawQuery);
    final languages = _detectLanguages(rawQuery);
    final type = _detectQueryType(normalized, contextCollegeIds);
    final city = _extractCity(normalized) ??
        (normalized.contains('near me') ||
                normalized.contains('mere paas') ||
                normalized.contains('mera paas') ||
                normalized.contains('javal') ||
                normalized.contains('जवळ') ||
                normalized.contains('पास')
            ? userCity
            : null);
    final state = _extractState(normalized) ?? userState;
    final course = _extractCourse(normalized);
    final collegeType = _extractCollegeType(normalized);
    final naacGrade = _extractNaacGrade(normalized);
    final maxFees = _extractMaxFees(normalized);
    final requireHostel = _requiresHostel(normalized);
    final nearMe = _isNearMe(normalized);
    final sortBy = _detectSortPriority(normalized);
    final comparisonMetric = _extractComparisonMetric(normalized);
    final compareIds = type == AiQueryType.compare || type == AiQueryType.question
        ? contextCollegeIds
        : const <String>[];

    return AiQueryIntent(
      type: type,
      rawQuery: rawQuery.trim(),
      city: city,
      state: state,
      course: course,
      collegeType: collegeType,
      naacGrade: naacGrade,
      maxFees: maxFees,
      requireHostel: requireHostel,
      nearMe: nearMe,
      sortBy: sortBy,
      compareCollegeIds: compareIds,
      comparisonMetric: comparisonMetric,
      detectedLanguages: languages,
    );
  }

  /// Extract college name fragments for comparison lookup.
  List<String> extractCollegeNameHints(String rawQuery) {
    final q = rawQuery.trim();
    final separators = RegExp(
      r'\b(?:vs|versus|and|aur|ani|with|between|compare|comparison|मध्ये|vs\.)\b',
      caseSensitive: false,
    );
    if (!separators.hasMatch(q)) return [];

    final parts = q.split(separators).map((e) => e.trim()).where((e) {
      if (e.length < 4) return false;
      final lower = e.toLowerCase();
      return !lower.contains('which') &&
          !lower.contains('better') &&
          !lower.contains('compare') &&
          !lower.contains('placement') &&
          !lower.contains('fees') &&
          !lower.contains('hostel') &&
          !lower.contains('faculty');
    }).toList();

    return parts.take(5).toList();
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _detectLanguages(String raw) {
    final langs = <String>{'en'};
    if (RegExp(r'[\u0900-\u097F]').hasMatch(raw)) {
      langs.add('hi');
      langs.add('mr');
    }
    if (RegExp(r'\b(aani|madhe|sarv|javal|chya|la)\b', caseSensitive: false)
        .hasMatch(raw)) {
      langs.add('mr');
    }
    if (RegExp(r'\b(mein|ke andar|wale|sarkar|sabse|accha)\b',
            caseSensitive: false)
        .hasMatch(raw)) {
      langs.add('hi');
    }
    return langs.toList();
  }

  AiQueryType _detectQueryType(String q, List<String> contextIds) {
    final compareWords = [
      'compare',
      'comparison',
      'versus',
      ' vs ',
      ' vs.',
      'better than',
      'which is better',
      'which college is better',
      'kon better',
      'konsa better',
      'कोण चांगले',
      'कोन चांगला',
      'तुलना',
    ];
    final questionWords = [
      'which has',
      'which have',
      'who has',
      'kiske paas',
      'konsa',
      'konala',
      'kontya',
    ];

    if (compareWords.any((w) => q.contains(w))) {
      return AiQueryType.compare;
    }
    if (contextIds.isNotEmpty &&
        (questionWords.any((w) => q.contains(w)) ||
            q.contains('better placement') ||
            q.contains('lower fees') ||
            q.contains('better hostel') ||
            q.contains('better faculty'))) {
      return AiQueryType.question;
    }
    if (contextIds.length >= 2 &&
        (q.contains('better') || q.contains('accha') || q.contains('changa'))) {
      return AiQueryType.compare;
    }
    return AiQueryType.search;
  }

  String? _extractCity(String q) {
    for (final entry in _cityAliases.entries) {
      if (q.contains(entry.key)) return entry.value;
    }
    final inMatch = RegExp(
      r'(?:in|at|mein|me|madhe|मध्ये|मध्ये)\s+([a-z\u0900-\u097F]{3,20})',
      caseSensitive: false,
    ).firstMatch(q);
    if (inMatch != null) {
      final candidate = inMatch.group(1)?.trim().toLowerCase();
      if (candidate != null && _cityAliases.containsKey(candidate)) {
        return _cityAliases[candidate];
      }
    }
    return null;
  }

  String? _extractState(String q) {
    for (final entry in _stateAliases.entries) {
      if (q.contains(entry.key)) return entry.value;
    }
    for (final state in CollegeConstants.indianStates) {
      if (q.contains(state.toLowerCase())) return state;
    }
    return null;
  }

  String? _extractCourse(String q) {
    if (q.contains('computer') ||
        q.contains('cse') ||
        q.contains('it ') ||
        q.contains('information technology')) {
      return 'Computer Engineering';
    }
    final entries = _courseKeywords.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in entries) {
      if (_containsKeyword(q, entry.key)) return entry.value;
    }
    return null;
  }

  bool _containsKeyword(String q, String keyword) {
    if (keyword.length <= 4) {
      return RegExp('\\b${RegExp.escape(keyword)}\\b').hasMatch(q);
    }
    return q.contains(keyword);
  }

  String? _extractCollegeType(String q) {
    const gov = [
      'government',
      'govt',
      'gov',
      'sarkari',
      'sarkar',
      'public',
      'सरकारी',
      'shasan',
      'shasakiya',
    ];
    const pvt = [
      'private',
      'khaskgi',
      'khasgi',
      'खासगी',
      'swasth',
      'svatantra',
    ];
    if (gov.any((w) => q.contains(w))) return 'government';
    if (pvt.any((w) => q.contains(w))) return 'private';
    return null;
  }

  String? _extractNaacGrade(String q) {
    final match = _naacPattern.firstMatch(q);
    if (match != null) {
      return _normalizeNaacGrade(match.group(1) ?? '');
    }
    if (q.contains('a++') || q.contains('a plus plus')) return 'A++';
    if (q.contains('a+') && !q.contains('a++')) return 'A+';
    return null;
  }

  String _normalizeNaacGrade(String raw) {
    final g = raw.replaceAll(' ', '').toUpperCase();
    if (g.contains('A++') || g == 'A++') return 'A++';
    if (g.contains('A+')) return 'A+';
    if (g == 'A') return 'A';
    if (g.contains('B++')) return 'B++';
    if (g.contains('B+')) return 'B+';
    if (g == 'B') return 'B';
    return raw.toUpperCase();
  }

  int? _extractMaxFees(String q) {
    final match = _feePattern.firstMatch(q);
    if (match == null) return null;
    final lakh = double.tryParse(match.group(1) ?? '');
    if (lakh == null) return null;
    if (q.contains('under') ||
        q.contains('below') ||
        q.contains('within') ||
        q.contains('ke andar') ||
        q.contains('paryant') ||
        q.contains('paryant') ||
        q.contains('kami')) {
      return (lakh * 100000).round();
    }
    return (lakh * 100000).round();
  }

  bool _requiresHostel(String q) {
    const hostelWords = [
      'hostel',
      'hostels',
      'boarding',
      'residence',
      'छात्रावास',
      'vasati',
      'vasatigruh',
      'vasati gruh',
    ];
    return hostelWords.any((w) => q.contains(w));
  }

  bool _isNearMe(String q) {
    const nearWords = [
      'near me',
      'nearby',
      'around me',
      'close to me',
      'mere paas',
      'mera paas',
      'meri najdik',
      'najdik',
      'javal',
      'जवळ',
      'paas',
      'पास',
      'lagat',
    ];
    return nearWords.any((w) => q.contains(w));
  }

  AiSortPriority _detectSortPriority(String q) {
    if (q.contains('placement') ||
        q.contains('package') ||
        q.contains('salary') ||
        q.contains('nokri') ||
        q.contains('naukri')) {
      return AiSortPriority.placements;
    }
    if (q.contains('fee') ||
        q.contains('fees') ||
        q.contains('cost') ||
        q.contains('budget') ||
        q.contains('affordable') ||
        q.contains('sasta') ||
        q.contains('swast') ||
        q.contains('किफायती')) {
      return AiSortPriority.feesLow;
    }
    if (q.contains('hostel')) return AiSortPriority.hostel;
    if (q.contains('campus life') ||
        q.contains('campus') ||
        q.contains('fest') ||
        q.contains('life')) {
      return AiSortPriority.campusLife;
    }
    if (q.contains('attendance') ||
        q.contains('attendance pressure') ||
        q.contains('hajir') ||
        q.contains('हजेरी')) {
      return AiSortPriority.attendance;
    }
    if (q.contains('faculty') ||
        q.contains('professor') ||
        q.contains('teacher') ||
        q.contains('shikshak')) {
      return AiSortPriority.faculty;
    }
    if (q.contains('nirf') || q.contains('ranking') || q.contains('rank')) {
      return AiSortPriority.nirf;
    }
    if (q.contains('naac') || q.contains('accreditation')) {
      return AiSortPriority.naac;
    }
    return AiSortPriority.overall;
  }

  String? _extractComparisonMetric(String q) {
    if (q.contains('placement')) return 'placements';
    if (q.contains('fee') || q.contains('fees') || q.contains('cost')) {
      return 'fees';
    }
    if (q.contains('faculty') || q.contains('teacher')) return 'faculty';
    if (q.contains('hostel')) return 'hostel';
    if (q.contains('overall') || q.contains('better')) return 'overall';
    return null;
  }
}
