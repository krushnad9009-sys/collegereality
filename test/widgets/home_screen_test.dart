import 'package:college_reality_india/features/home/widgets/home_hero_banner.dart';
import 'package:college_reality_india/features/home/widgets/premium_home_search_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HomeHeroBanner shows guest greeting', (tester) async {
    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const HomeHeroBanner(
        greeting: 'Find your dream college',
        subtitle: 'Explore 47,000+ colleges with real campus photos & ratings',
      ),
    );

    expect(find.text('Find your dream college'), findsOneWidget);
    expect(
      find.textContaining('Explore 47,000+ colleges'),
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
      find.text('Search colleges, cities, courses & more'),
      findsOneWidget,
    );
  });
}