class StudentLifeConstants {
  StudentLifeConstants._();

  static const String metaStudentLifeSeededDoc = 'studentLifeSeeded';

  // Event categories
  static const String eventTechnical = 'technical';
  static const String eventCultural = 'cultural';
  static const String eventSports = 'sports';
  static const String eventWorkshop = 'workshop';
  static const String eventSeminar = 'seminar';
  static const String eventWebinar = 'webinar';
  static const String eventHackathon = 'hackathon';

  static const List<String> eventCategories = [
    eventTechnical,
    eventCultural,
    eventSports,
    eventWorkshop,
    eventSeminar,
    eventWebinar,
    eventHackathon,
  ];

  // Club types
  static const String clubCoding = 'coding';
  static const String clubRobotics = 'robotics';
  static const String clubAiMl = 'ai_ml';
  static const String clubEntrepreneurship = 'entrepreneurship';
  static const String clubNss = 'nss';
  static const String clubNcc = 'ncc';
  static const String clubSports = 'sports';
  static const String clubMusic = 'music';
  static const String clubDance = 'dance';
  static const String clubPhotography = 'photography';
  static const String clubDrama = 'drama';
  static const String clubTechnical = 'technical';

  static const List<String> clubTypes = [
    clubCoding,
    clubRobotics,
    clubAiMl,
    clubEntrepreneurship,
    clubNss,
    clubNcc,
    clubSports,
    clubMusic,
    clubDance,
    clubPhotography,
    clubDrama,
    clubTechnical,
  ];

  // Competition scope
  static const String scopeCollege = 'college';
  static const String scopeInterCollege = 'inter_college';
  static const String scopeNational = 'national';

  // Community types
  static const String communityBranch = 'branch';
  static const String communityYear = 'year';
  static const String communityCollege = 'college';

  // Feed sort modes
  static const String feedLatest = 'latest';
  static const String feedTrending = 'trending';
  static const String feedPinned = 'pinned';

  static String collegeFeedCommunityId(String collegeId) =>
      'college_feed_${collegeId.trim()}';

  // Post types
  static const String postDiscussion = 'discussion';
  static const String postPoll = 'poll';
  static const String postAnnouncement = 'announcement';

  // Status
  static const String statusActive = 'active';
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusPublished = 'published';
  static const String statusHidden = 'hidden';

  static const String reportStatusOpen = 'open';
  static const String reportStatusReviewed = 'reviewed';
  static const String reportStatusActionTaken = 'action_taken';

  static const String joinStatusPending = 'pending';
  static const String joinStatusApproved = 'approved';
  static const String joinStatusRejected = 'rejected';

  static String eventCategoryLabel(String category) {
    switch (category) {
      case eventTechnical:
        return 'Technical';
      case eventCultural:
        return 'Cultural';
      case eventSports:
        return 'Sports';
      case eventWorkshop:
        return 'Workshop';
      case eventSeminar:
        return 'Seminar';
      case eventWebinar:
        return 'Webinar';
      case eventHackathon:
        return 'Hackathon';
      default:
        return category;
    }
  }

  static String clubTypeLabel(String type) {
    switch (type) {
      case clubCoding:
        return 'Coding Club';
      case clubRobotics:
        return 'Robotics Club';
      case clubAiMl:
        return 'AI/ML Club';
      case clubEntrepreneurship:
        return 'Entrepreneurship Club';
      case clubNss:
        return 'NSS';
      case clubNcc:
        return 'NCC';
      case clubSports:
        return 'Sports Club';
      case clubMusic:
        return 'Music Club';
      case clubDance:
        return 'Dance Club';
      case clubPhotography:
        return 'Photography Club';
      case clubDrama:
        return 'Drama Club';
      case clubTechnical:
        return 'Technical Club';
      default:
        return type;
    }
  }

  static String competitionScopeLabel(String scope) {
    switch (scope) {
      case scopeCollege:
        return 'College';
      case scopeInterCollege:
        return 'Inter-College';
      case scopeNational:
        return 'National';
      default:
        return scope;
    }
  }
}
