import '../../colleges/models/college_model.dart';

class AiCollegeRecommendation {
  final CollegeModel college;
  final double score;
  final List<String> reasons;
  final int rank;

  const AiCollegeRecommendation({
    required this.college,
    required this.score,
    required this.reasons,
    required this.rank,
  });
}
