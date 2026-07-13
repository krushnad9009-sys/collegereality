import '../models/careers_models.dart';

class CareerMatchResult<T> {
  final T item;
  final int score;
  final String reason;

  const CareerMatchResult({required this.item, required this.score, required this.reason});
}

List<CareerMatchResult<JobModel>> recommendJobs({
  required List<JobModel> jobs,
  required String? degree,
  required String? branch,
  required List<String> skills,
  int limit = 10,
}) {
  final degreeLower = (degree ?? '').toLowerCase();
  final branchLower = (branch ?? '').toLowerCase();
  final skillSet = skills.map((s) => s.toLowerCase()).toSet();

  final results = <CareerMatchResult<JobModel>>[];
  for (final job in jobs) {
    if (!job.isActive) continue;
    var score = 0;
    final reasons = <String>[];

    for (final skill in job.skills) {
      if (skillSet.contains(skill.toLowerCase())) {
        score += 15;
        reasons.add('Skill match: $skill');
      }
    }

    final eligibility = job.eligibility.toLowerCase();
    if (degreeLower.isNotEmpty && eligibility.contains(degreeLower)) {
      score += 25;
      reasons.add('Degree match');
    }
    if (branchLower.isNotEmpty &&
        (eligibility.contains(branchLower) || job.searchText.contains(branchLower))) {
      score += 20;
      reasons.add('Branch match');
    }
    if (job.jobLevel == 'fresher') {
      score += 10;
      reasons.add('Fresher friendly');
    }

    if (score > 0) {
      results.add(CareerMatchResult(
        item: job,
        score: score,
        reason: reasons.take(2).join(' · '),
      ));
    }
  }

  results.sort((a, b) => b.score.compareTo(a.score));
  return results.take(limit).toList();
}

List<CareerMatchResult<InternshipModel>> recommendInternships({
  required List<InternshipModel> internships,
  required List<String> skills,
  int limit = 10,
}) {
  final skillSet = skills.map((s) => s.toLowerCase()).toSet();

  final results = <CareerMatchResult<InternshipModel>>[];
  for (final internship in internships) {
    if (!internship.isActive) continue;
    var score = 0;
    final reasons = <String>[];

    for (final skill in internship.skills) {
      if (skillSet.contains(skill.toLowerCase())) {
        score += 20;
        reasons.add('Skill match: $skill');
      }
    }
    if (internship.isPaid) {
      score += 5;
      reasons.add('Paid internship');
    }
    if (internship.isRemote) {
      score += 5;
      reasons.add('Work from home');
    }

    if (score > 0) {
      results.add(CareerMatchResult(
        item: internship,
        score: score,
        reason: reasons.take(2).join(' · '),
      ));
    }
  }

  results.sort((a, b) => b.score.compareTo(a.score));
  return results.take(limit).toList();
}

List<String> generateCareerSuggestions({
  required String? degree,
  required String? branch,
  required List<String> skills,
  required List<JobModel> jobs,
  required List<InternshipModel> internships,
}) {
  final suggestions = <String>[];
  final skillSet = skills.map((s) => s.toLowerCase()).toSet();

  if (skills.isEmpty) {
    suggestions.add('Add skills to your profile (e.g. Python, Java, React) to get better matches.');
  }
  if (degree == null || degree.isEmpty) {
    suggestions.add('Complete your degree/course in profile for degree-based job recommendations.');
  }

  final topJobSkills = <String>{};
  for (final job in jobs.take(20)) {
    topJobSkills.addAll(job.skills);
  }
  final missing = topJobSkills
      .where((s) => !skillSet.contains(s.toLowerCase()))
      .take(3)
      .toList();
  if (missing.isNotEmpty) {
    suggestions.add('In-demand skills in your field: ${missing.join(', ')}.');
  }

  final paidCount = internships.where((i) => i.isPaid).length;
  if (paidCount > 0) {
    suggestions.add('$paidCount paid internships available — apply early for better chances.');
  }

  if (branch != null && branch.isNotEmpty) {
    suggestions.add('Explore $branch roles in product companies and startups for faster growth.');
  }

  if (suggestions.isEmpty) {
    suggestions.add('Keep your resume updated and apply to 3–5 roles per week for steady progress.');
  }

  return suggestions.take(5).toList();
}
