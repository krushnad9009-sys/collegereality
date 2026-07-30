import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/careers/utils/resume_scoring_utils.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({
  String? displayName,
  String? course,
  String? collegeName,
  String? aboutMe,
  List<String> interests = const [],
}) {
  final now = DateTime(2026, 1, 1);
  return UserModel(
    uid: 'resume-user',
    email: 'resume@test.com',
    displayName: displayName,
    course: course,
    collegeName: collegeName,
    aboutMe: aboutMe,
    interests: interests,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('scoreResume', () {
    test('returns zero-ish score for empty profile without resume', () {
      final result = scoreResume(
        user: _user(),
        hasResumeFile: false,
        fileSizeBytes: 0,
        extractedSkills: const [],
      );
      expect(result.score, lessThan(30));
      expect(result.suggestions, isNotEmpty);
      expect(result.suggestions.first, contains('Upload your resume'));
    });

    test('awards points for complete profile with resume', () {
      final result = scoreResume(
        user: _user(
          displayName: 'Amit Kumar',
          course: 'B.Tech CSE',
          collegeName: 'COEP Pune',
          aboutMe: 'Built multiple Flutter apps with measurable user growth and impact.',
          interests: const ['Coding'],
        ),
        hasResumeFile: true,
        fileSizeBytes: 512 * 1024,
        extractedSkills: const ['Flutter', 'Dart', 'Firebase'],
      );
      expect(result.score, greaterThanOrEqualTo(70));
      expect(result.suggestions.length, lessThanOrEqualTo(6));
    });

    test('suggests smaller file when over 2 MB', () {
      final result = scoreResume(
        user: _user(displayName: 'Test'),
        hasResumeFile: true,
        fileSizeBytes: 3 * 1024 * 1024,
        extractedSkills: const ['Java', 'Python', 'SQL'],
      );
      expect(
        result.suggestions.any((s) => s.contains('under 2 MB')),
        isTrue,
      );
    });

    test('suggests more skills when fewer than 3 extracted', () {
      final result = scoreResume(
        user: _user(displayName: 'Test', course: 'B.Tech'),
        hasResumeFile: true,
        fileSizeBytes: 100000,
        extractedSkills: const ['Java'],
      );
      expect(
        result.suggestions.any((s) => s.contains('3 technical skills')),
        isTrue,
      );
    });

    test('adds project bonus when skill contains project', () {
      final withProject = scoreResume(
        user: _user(displayName: 'Test', course: 'B.Tech', collegeName: 'X'),
        hasResumeFile: true,
        fileSizeBytes: 100000,
        extractedSkills: const ['Flutter', 'Project Lead', 'SQL'],
      );
      final withoutProject = scoreResume(
        user: _user(displayName: 'Test', course: 'B.Tech', collegeName: 'X'),
        hasResumeFile: true,
        fileSizeBytes: 100000,
        extractedSkills: const ['Flutter', 'Dart', 'SQL'],
      );
      expect(withProject.score, greaterThan(withoutProject.score));
    });

    test('handles null user gracefully', () {
      final result = scoreResume(
        user: null,
        hasResumeFile: false,
        fileSizeBytes: 0,
        extractedSkills: const [],
      );
      expect(result.score, lessThan(50));
      expect(result.suggestions.any((s) => s.contains('full name')), isTrue);
    });

    test('clamps score between 0 and 100', () {
      final result = scoreResume(
        user: _user(
          displayName: 'Full',
          course: 'B.Tech',
          collegeName: 'College',
          aboutMe: 'A' * 100,
          interests: const ['A', 'B'],
        ),
        hasResumeFile: true,
        fileSizeBytes: 500000,
        extractedSkills: const ['A', 'B', 'C', 'project'],
      );
      expect(result.score, inInclusiveRange(0, 100));
    });

    test('suggests competitive score target when below 50', () {
      final result = scoreResume(
        user: _user(displayName: 'Only Name'),
        hasResumeFile: false,
        fileSizeBytes: 0,
        extractedSkills: const [],
      );
      expect(result.score, lessThan(50));
      expect(
        result.suggestions.any((s) => s.contains('70+')),
        isTrue,
      );
    });
  });

  group('extractSkillsFromFileName', () {
    test('detects common tech keywords in filename', () {
      final skills = extractSkillsFromFileName('amit_react_python_resume.pdf');
      expect(skills, containsAll(['React', 'Python']));
    });

    test('maps ml to Machine Learning and node to Node.js', () {
      final skills = extractSkillsFromFileName('dev_ml_node_cv.docx');
      expect(skills, contains('Machine Learning'));
      expect(skills, contains('Node.js'));
    });

    test('returns empty for unrelated filenames', () {
      expect(extractSkillsFromFileName('my_document.pdf'), isEmpty);
    });

    test('is case insensitive', () {
      final skills = extractSkillsFromFileName('FLUTTER_JavaScript.pdf');
      expect(skills, contains('Flutter'));
      expect(skills, contains('Javascript'));
    });
  });
}
