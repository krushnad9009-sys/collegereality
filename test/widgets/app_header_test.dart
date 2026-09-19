import 'package:college_reality_india/config/theme/app_spacing.dart';
import 'package:college_reality_india/features/home/widgets/app_header.dart';
import 'package:college_reality_india/features/home/widgets/home_header_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

final _signedIn = MockUser(
  uid: 'u1',
  email: 'student@example.com',
  displayName: 'Test Student',
);

Future<void> _pumpHeader(
  WidgetTester tester, {
  required double width,
  required User? user,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await pumpScreen(
    tester,
    overrides: testAuthOverrides(
      firebaseUser: user,
      userDetail: user == null
          ? null
          : testUserModel(uid: 'u1', email: 'student@example.com'),
    ),
    child: Scaffold(
      appBar: HomeAppHeader(user: user, onMenuPressed: () {}),
      body: const SizedBox.expand(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The body is `Center > ConstrainedBox(maxContentWidth) > Padding(gutter)`,
  // so its content spans [left, right] below.
  for (final width in [375.0, 900.0, 1600.0]) {
    testWidgets('header edges match the body content edges at ${width.toInt()}px',
        (tester) async {
      await _pumpHeader(tester, width: width, user: _signedIn);

      final gutter = width < 600 ? AppSpacing.lg : AppSpacing.xxl;
      final boxWidth =
          width < AppSpacing.maxContentWidth ? width : AppSpacing.maxContentWidth;
      final contentLeft = (width - boxWidth) / 2 + gutter;
      final contentRight = (width + boxWidth) / 2 - gutter;

      final menu = find.byTooltip('Open navigation menu');
      expect(tester.getTopLeft(menu).dx, moreOrLessEquals(contentLeft));
      expect(
        tester.getTopRight(find.byType(HomeHeaderActions)).dx,
        moreOrLessEquals(contentRight),
      );
    });
  }

  testWidgets('title sits 12px after the hamburger, on the same row',
      (tester) async {
    await _pumpHeader(tester, width: 900, user: _signedIn);

    final menu = find.byTooltip('Open navigation menu');
    final title = find.text('College Reality');

    expect(
      tester.getTopLeft(title).dx - tester.getTopRight(menu).dx,
      moreOrLessEquals(12),
    );
    expect(
      tester.getCenter(title).dy,
      moreOrLessEquals(tester.getCenter(menu).dy),
    );
  });

  testWidgets('signed-out visitors get hamburger and title only',
      (tester) async {
    await _pumpHeader(tester, width: 900, user: null);

    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
    expect(find.text('College Reality'), findsOneWidget);
    expect(find.byType(HomeHeaderActions), findsNothing);
  });
}
