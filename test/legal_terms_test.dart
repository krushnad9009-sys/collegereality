import 'package:college_reality_india/features/legal/screens/legal_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Terms & Conditions content', () {
    test('has the 9 sections of the September 30, 2026 Terms, in order', () {
      expect(termsLastUpdated, 'September 30, 2026');
      expect(termsOfServiceSections.map((s) => s.heading), [
        '1. Nature of Platform & Services',
        '2. Eligibility & Account Registration',
        '3. Guide Onboarding & Mandatory College Verification',
        '4. Calls, Chats, and Shared Wallet Rules',
        '5. Code of Conduct & Prohibited Uses',
        '6. Disclaimer of Warranties & Limitation of Liability',
        '7. Intellectual Property',
        '8. Governing Law & Jurisdiction',
        '9. Contact Us',
      ]);
    });

    test('intro carries date, app name and package', () {
      expect(termsAndConditionsIntro, contains('Last Updated: September 30, 2026'));
      expect(termsAndConditionsIntro, contains('App Name: College Kundli'));
      expect(termsAndConditionsIntro,
          contains('Package Name: com.collegereality.india'));
    });

    test('key clauses are present', () {
      final all = termsOfServiceSections.map((s) => s.plainText).join(' ');
      for (final phrase in [
        'will NEVER be displayed publicly',
        'Non-Refundable Balance',
        'Information Technology Act, 2000',
        'Pune, Maharashtra, India',
        'support@collegereality.in',
      ]) {
        expect(all, contains(phrase));
      }
      final conduct = termsOfServiceSections[4];
      expect(conduct.numbered, isTrue);
      expect(conduct.bullets, hasLength(5));
      expect(conduct.footer, contains('permanent ban'));
    });
  });

  testWidgets(
      'Terms screen renders cleanly on a small phone with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(
        size: Size(320, 640),
        textScaler: TextScaler.linear(1.3),
      ),
      child: MaterialApp(home: TermsOfServiceScreen()),
    ));
    await tester.pump();

    // Bold label + numbered list render; no layout overflow anywhere.
    final label =
        find.textContaining('Peer-to-Peer Consultation', findRichText: true);
    await tester.scrollUntilVisible(label, 200);
    expect(label, findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('5. Code of Conduct & Prohibited Uses'),
      300,
    );
    expect(find.text('1.'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Contact: support@collegereality.in'),
      300,
    );
    expect(tester.takeException(), isNull);
  });
}
