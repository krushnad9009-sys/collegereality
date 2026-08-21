import 'package:college_reality_india/features/assistant/screens/ai_assistant_screen.dart';
import 'package:college_reality_india/features/colleges/providers/college_provider.dart';
import 'package:college_reality_india/features/colleges/repositories/college_repository.dart';
import 'package:college_reality_india/features/community_feed/providers/college_community_feed_provider.dart';
import 'package:college_reality_india/features/community_feed/repositories/college_community_feed_repository.dart';
import 'package:college_reality_india/features/questions/providers/question_provider.dart';
import 'package:college_reality_india/features/questions/repositories/question_repository.dart';
import 'package:college_reality_india/features/reviews/providers/review_provider.dart';
import 'package:college_reality_india/features/reviews/repositories/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_harness.dart';

class _MockCollegeRepository extends Mock implements CollegeRepository {}

class _MockReviewRepository extends Mock implements ReviewRepository {}

class _MockQuestionRepository extends Mock implements QuestionRepository {}

class _MockCollegeCommunityFeedRepository extends Mock
    implements CollegeCommunityFeedRepository {}

/// Regression coverage for the "remove all automatic AI suggested
/// questions" fix: the empty-state screen must render with zero
/// automatically generated/predefined question chips, while the manual
/// input field and send control keep working. None of the mocked
/// repositories' methods are ever called here -- the empty state never
/// sends a message -- they only exist so the Firestore-backed repository
/// providers never construct a real FirebaseFirestore instance in a test
/// environment with no Firebase app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Override> repoOverrides() => [
        collegeRepositoryProvider.overrideWithValue(_MockCollegeRepository()),
        reviewRepositoryProvider.overrideWithValue(_MockReviewRepository()),
        questionRepositoryProvider.overrideWithValue(_MockQuestionRepository()),
        collegeCommunityFeedRepositoryProvider
            .overrideWithValue(_MockCollegeCommunityFeedRepository()),
      ];

  testWidgets(
    'AI Assistant empty state shows no automatic suggested questions',
    (tester) async {
      await pumpScreen(
        tester,
        overrides: [...testAuthOverrides(), ...repoOverrides()],
        child: const AiAssistantScreen(),
      );

      // Previously-removed suggestion source text must never appear.
      expect(find.text('Try asking'), findsNothing);
      expect(find.textContaining('Hostel review'), findsNothing);
      expect(find.textContaining('ragging'), findsNothing);
      expect(find.textContaining('CET percentile'), findsNothing);
      expect(
        find.textContaining('Best engineering colleges in Pune'),
        findsNothing,
      );
      expect(find.textContaining('Is this college good'), findsNothing);
      expect(find.textContaining('How are the placements'), findsNothing);

      // The intro card is expected to remain; there should be nothing else.
      expect(find.text('India\'s Smartest AI Assistant'), findsOneWidget);

      // The manual input path must still be fully present and enabled.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'What is the average CTC?',
      );
      expect(find.text('What is the average CTC?'), findsOneWidget);
    },
  );

  testWidgets(
    'AI Assistant anchored to a college also shows no automatic suggestions',
    (tester) async {
      await pumpScreen(
        tester,
        overrides: [...testAuthOverrides(), ...repoOverrides()],
        child: const AiAssistantScreen(
          anchorCollegeId: 'c1',
          anchorCollegeName: 'Test Engineering College',
        ),
      );

      expect(find.text('Try asking'), findsNothing);
      expect(find.textContaining('Is this college good'), findsNothing);
      expect(find.textContaining('How is the hostel'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    },
  );
}
