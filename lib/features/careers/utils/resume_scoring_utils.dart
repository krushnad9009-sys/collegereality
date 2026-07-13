import '../../auth/models/user_model.dart';

class ResumeScoreResult {
  final int score;
  final List<String> suggestions;

  const ResumeScoreResult({required this.score, required this.suggestions});
}

ResumeScoreResult scoreResume({
  required UserModel? user,
  required bool hasResumeFile,
  required int fileSizeBytes,
  required List<String> extractedSkills,
}) {
  var score = 0;
  final suggestions = <String>[];

  if (hasResumeFile) {
    score += 30;
  } else {
    suggestions.add('Upload your resume to unlock apply-with-resume and improve visibility.');
  }

  if (fileSizeBytes > 0 && fileSizeBytes < 2 * 1024 * 1024) {
    score += 10;
  } else if (fileSizeBytes >= 2 * 1024 * 1024) {
    suggestions.add('Keep resume file under 2 MB for faster recruiter downloads.');
  }

  if (user?.displayName != null && user!.displayName!.isNotEmpty) {
    score += 10;
  } else {
    suggestions.add('Add your full name to your profile.');
  }

  if (user?.course != null && user!.course!.isNotEmpty) {
    score += 10;
  } else {
    suggestions.add('Add your degree/course for better job matching.');
  }

  if (user?.collegeName != null && user!.collegeName!.isNotEmpty) {
    score += 10;
  } else {
    suggestions.add('Link your college for campus credibility.');
  }

  if (extractedSkills.length >= 3) {
    score += 15;
  } else {
    suggestions.add('List at least 3 technical skills (e.g. Python, SQL, React).');
  }

  if (user?.aboutMe != null && user!.aboutMe!.length > 50) {
    score += 10;
  } else {
    suggestions.add('Write a 2–3 line summary highlighting projects and achievements.');
  }

  if (user?.interests.isNotEmpty == true) score += 5;

  if (score < 50) {
    suggestions.add('Aim for 70+ resume score before applying to competitive roles.');
  }
  if (extractedSkills.any((s) => s.toLowerCase().contains('project'))) {
    score += 5;
  } else {
    suggestions.add('Include 1–2 project descriptions with measurable outcomes.');
  }

  return ResumeScoreResult(
    score: score.clamp(0, 100),
    suggestions: suggestions.take(6).toList(),
  );
}

List<String> extractSkillsFromFileName(String fileName) {
  final common = [
    'java', 'python', 'react', 'flutter', 'sql', 'aws', 'node',
    'javascript', 'typescript', 'spring', 'figma', 'ml', 'data',
  ];
  final lower = fileName.toLowerCase();
  return common.where((s) => lower.contains(s)).map((s) {
    switch (s) {
      case 'ml':
        return 'Machine Learning';
      case 'node':
        return 'Node.js';
      default:
        return s[0].toUpperCase() + s.substring(1);
    }
  }).toList();
}
