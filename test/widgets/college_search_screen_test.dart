import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/providers/college_provider.dart';
import 'package:college_reality_india/features/colleges/screens/college_search_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CollegeSearchScreen shows search chrome', (tester) async {
    await pumpRouterApp(
      tester,
      initialLocation: '/college-search',
      overrides: [
        ...testAuthOverrides(),
        collegeDirectoryMetaProvider.overrideWith(
          (ref) async => const CollegeDirectoryMeta(totalColleges: 0),
        ),
        indianStatesProvider.overrideWith((ref) async => <String>[]),
        indianCoursesProvider.overrideWith((ref) async => <String>[]),
        collegeSearchPageProvider.overrideWith(
          (ref, params) async => const CollegeSearchPage(colleges: []),
        ),
      ],
      routes: [
        GoRoute(
          path: '/college-search',
          builder: (_, _) => const CollegeSearchScreen(),
        ),
      ],
    );

    expect(find.text('Search Colleges'), findsWidgets);
  });
}
