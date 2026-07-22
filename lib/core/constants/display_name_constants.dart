class DisplayNameConstants {
  DisplayNameConstants._();

  static const String modeRealName = 'real_name';
  static const String modeAnonymousVerifiedStudent = 'anonymous_verified_student';
  static const String modeAnonymousVerifiedAlumni = 'anonymous_verified_alumni';
  static const String modeCustom = 'custom';

  static const int changeCooldownDays = 90;
  static const int customNameMinLength = 3;
  static const int customNameMaxLength = 30;

  static const String anonymousVerifiedStudentLabel = 'Anonymous Verified Student';
  static const String anonymousVerifiedAlumniLabel = 'Anonymous Verified Alumni';

  static const List<String> allModes = [
    modeRealName,
    modeAnonymousVerifiedStudent,
    modeAnonymousVerifiedAlumni,
    modeCustom,
  ];
}
