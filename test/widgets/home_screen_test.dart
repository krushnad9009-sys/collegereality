import 'package:college_reality_india/core/constants/college_constants.dart';
import 'package:college_reality_india/features/home/widgets/premium_home_header.dart';
import 'package:college_reality_india/features/home/widgets/premium_home_search_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PremiumHomeHeader shows guest greeting', (tester) async {
    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: PremiumHomeHeader(
        user: null,
        displayName: 'Student',
        subtitle: CollegeConstants.homeExploreLabel(),
      ),
    );

    expect(find.text('Find your dream college'), findsOneWidget);
    expect(
      find.textContaining('Explore 45,020 colleges'),
      findsOneWidget,
    );
  });

  testWidgets('PremiumHomeSearchBar shows search hint', (tester) async {
    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const PremiumHomeSearchBar(),
    );

    expect(
      find.text('College, city, course or exam'),
      findsOneWidget,
    );
  });
}