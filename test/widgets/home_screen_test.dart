import 'package:college_reality_india/features/home/widgets/premium_home_header.dart';
import 'package:college_reality_india/features/home/widgets/premium_home_search_bar.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PremiumHomeHeader shows the guest welcome', (tester) async {
    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const PremiumHomeHeader(
        user: null,
        displayName: 'Student',
        subtitle: 'Find the right college with real student information',
      ),
    );

    expect(find.text('Find your dream college'), findsOneWidget);
    expect(
      find.text('Find the right college with real student information'),
      findsOneWidget,
    );
  });

  testWidgets('PremiumHomeHeader greets a signed-in user on one line', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: PremiumHomeHeader(
        user: MockUser(uid: 'u1', displayName: 'dk007'),
        displayName: 'dk007',
        subtitle: 'Real reviews & verified CR Scores, personalized for you',
      ),
    );

    // "Good afternoon, dk007" -- greeting and name in ONE text, with the
    // subtitle underneath.
    expect(
      find.text('Real reviews & verified CR Scores, personalized for you'),
      findsOneWidget,
    );
    expect(find.textContaining(', dk007'), findsOneWidget);
    expect(
      find.text('${PremiumHomeHeader.greetingFor(DateTime.now())}, dk007'),
      findsOneWidget,
    );
  });

  test('greeting follows the time of day', () {
    expect(
      PremiumHomeHeader.greetingFor(DateTime(2026, 1, 1, 8)),
      'Good morning',
    );
    expect(
      PremiumHomeHeader.greetingFor(DateTime(2026, 1, 1, 13)),
      'Good afternoon',
    );
    expect(
      PremiumHomeHeader.greetingFor(DateTime(2026, 1, 1, 20)),
      'Good evening',
    );
  });

  testWidgets('PremiumHomeSearchBar shows the "Find the right college" hint', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const PremiumHomeSearchBar(),
    );

    expect(find.text('Find the right college'), findsOneWidget);
  });
}
