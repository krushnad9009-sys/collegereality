import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_theme.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final List<LegalSection> sections;

  /// Optional lead-in paragraph rendered above the first section.
  final String? intro;

  /// Tappable mailto link at the end of the document.
  final String? contactEmail;

  const LegalDocumentScreen({
    required this.title,
    required this.sections,
    this.intro,
    this.contactEmail,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (intro != null && intro!.trim().isNotEmpty) ...[
            Text(
              intro!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.gray700,
              ),
            ),
            const SizedBox(height: 24),
          ],
          for (final section in sections) ...[
            LegalSectionView(
              section: section,
              headingStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              bodyStyle: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.gray700,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (contactEmail != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => launchUrl(Uri.parse('mailto:$contactEmail')),
                child: Text('Contact: $contactEmail'),
              ),
            ),
        ],
      ),
    );
  }
}

class LegalSection {
  final String heading;

  /// Paragraph shown under the heading (optional when [bullets] are used).
  final String body;

  /// List items. An item starting with a short "Label: " (e.g.
  /// "Document Privacy: ...") renders the label in bold.
  final List<String> bullets;

  /// Render [bullets] as 1., 2., 3. instead of dots.
  final bool numbered;

  /// Paragraph shown after the list.
  final String? footer;

  const LegalSection({
    required this.heading,
    this.body = '',
    this.bullets = const [],
    this.numbered = false,
    this.footer,
  });

  /// Plain-text form (search, tests, copy).
  String get plainText => [
        if (body.isNotEmpty) body,
        ...bullets,
        ?footer,
      ].join(' ');
}

/// Renders one [LegalSection]: heading, paragraph, bullet / numbered list
/// with hanging indents (wrapped lines align under the text, not the
/// marker, on every screen width), and an optional closing paragraph.
/// Shared by [LegalDocumentScreen] and the onboarding Terms card so both
/// always show the same document the same way.
class LegalSectionView extends StatelessWidget {
  final LegalSection section;
  final TextStyle headingStyle;
  final TextStyle bodyStyle;

  const LegalSectionView({
    required this.section,
    required this.headingStyle,
    required this.bodyStyle,
    super.key,
  });

  static final _label = RegExp(r'^([^:]{2,48}):\s+(.*)$', dotAll: true);

  Widget _item(String marker, String text) {
    final m = _label.firstMatch(text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(marker, style: bodyStyle),
          ),
          Expanded(
            child: m == null
                ? Text(text, style: bodyStyle)
                : Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: '${m.group(1)}: ',
                        style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: m.group(2)),
                    ]),
                    style: bodyStyle,
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.heading, style: headingStyle),
        const SizedBox(height: 8),
        if (section.body.isNotEmpty) ...[
          Text(section.body, style: bodyStyle),
          if (section.bullets.isNotEmpty) const SizedBox(height: 8),
        ],
        for (var i = 0; i < section.bullets.length; i++)
          _item(section.numbered ? '${i + 1}.' : '•', section.bullets[i]),
        if (section.footer != null) ...[
          const SizedBox(height: 4),
          Text(section.footer!, style: bodyStyle),
        ],
      ],
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Privacy Policy',
      contactEmail: 'privacy@collegereality.in',
      sections: [
        LegalSection(
          heading: 'Overview',
          body:
              'College Kundli ("we", "our") respects your privacy. This policy explains how we collect, use, and protect your information when you use our mobile application.',
        ),
        LegalSection(
          heading: 'Information We Collect',
          body:
              'We collect account information (name, email), profile details you provide, college search activity, reviews, and device identifiers for notifications. College directory data is sourced from official AISHE open-government datasets.',
        ),
        LegalSection(
          heading: 'How We Use Data',
          body:
              'We use your data to provide college search, personalized recommendations, reviews, bookmarks, and community features. We do not sell your personal information to third parties.',
        ),
        LegalSection(
          heading: 'Data Storage',
          body:
              'Your data is stored securely on our servers. You may request account deletion from your profile settings.',
        ),
        LegalSection(
          heading: 'Updates',
          body:
              'We may update this policy. Continued use of the app after changes constitutes acceptance. Last updated: July 2026.',
        ),
      ],
    );
  }
}

/// "Last Updated" date of [termsOfServiceSections] -- change it whenever
/// the Terms text changes.
const String termsLastUpdated = 'September 30, 2026';

/// Lead-in shown above [termsOfServiceSections].
const String termsAndConditionsIntro =
    'Last Updated: $termsLastUpdated\n'
    'App Name: College Kundli\n'
    'Package Name: com.collegereality.india\n\n'
    'Please read these Terms and Conditions ("Terms") carefully before using '
    'the College Kundli mobile application and platform operated by us. By '
    'accessing or using the Service, you agree to be bound by these Terms.';

/// Where Terms questions go (tappable at the end of the Terms screen).
const String termsContactEmail = 'support@collegereality.in';

/// Canonical Terms & Conditions copy, shared by the read-only
/// [TermsOfServiceScreen] and the mandatory post-login PermissionsTermsScreen.
const List<LegalSection> termsOfServiceSections = [
  LegalSection(
    heading: '1. Nature of Platform & Services',
    bullets: [
      'Peer-to-Peer Consultation: College Kundli is a communication platform '
          'that connects students/prospective students ("Users") with verified '
          'college seniors or alumni ("Guides") for guidance through voice '
          'calls, chat, and shared insights.',
      'No Official Affiliation: College Kundli is an independent platform and '
          'is not affiliated, endorsed, or associated with any university, '
          'government educational board, or admission counseling body.',
    ],
  ),
  LegalSection(
    heading: '2. Eligibility & Account Registration',
    bullets: [
      'You must be at least 18 years of age or have parental consent to use '
          'this application.',
      'You agree to provide accurate, complete, and updated information during '
          'account setup (Name, Phone Number, College Details).',
      'You are solely responsible for maintaining the confidentiality of your '
          'login credentials and for all activities under your account.',
    ],
  ),
  LegalSection(
    heading: '3. Guide Onboarding & Mandatory College Verification',
    body: 'To maintain platform authenticity, any user registering or '
        'onboarding as a Guide must complete our mandatory verification '
        'process:',
    bullets: [
      'Multi-Criteria Ratings: Guides must submit ratings (1 to 5 stars) '
          'across defined categories: Overall College Experience, '
          'Study/Academics, Campus Environment, and Placements.',
      'Mandatory Text Review: Guides must write a detailed, authentic review '
          'of their college.',
      'Verification Document Upload: Guides must upload valid proof of '
          'enrollment or graduation (e.g., Student ID Card, Fee Receipt, '
          'Marksheet, or Degree).',
      'Document Privacy: Uploaded proof documents are strictly used by College '
          'Kundli administrators for identity verification and will NEVER be '
          'displayed publicly to other users.',
      'Zero-Tolerance for Fraud: Uploading fake, altered, or misleading '
          'documents will lead to immediate account termination and a '
          'permanent platform ban.',
      'Approval Rights: Super Admins reserve the right to approve, reject, or '
          'request re-verification for any Guide profile at their sole '
          'discretion.',
    ],
  ),
  LegalSection(
    heading: '4. Calls, Chats, and Shared Wallet Rules',
    bullets: [
      'Call Wallet Balance: Users must top-up their in-app wallet ("Call '
          'Wallet") using supported payment gateways (e.g., Razorpay) to place '
          'consultation calls or initiate paid chats beyond any offered free '
          'promotional minutes.',
      "Billing & Metering: Calls and chats are billed based on the Guide's set "
          'rate or default fallback rate. Billing is calculated per '
          'second/minute of actual call duration.',
      'Shared Wallet Utility: Wallet balance is held in a unified account '
          'balance. Users can use their remaining balance across any available '
          'Guide on the platform until the balance is exhausted.',
      'Non-Refundable Balance: Funds deposited into the Call Wallet are '
          'non-refundable to bank accounts or payment sources once credited, '
          'except in cases of system billing errors or failed call connections '
          'verified by platform logs.',
    ],
  ),
  LegalSection(
    heading: '5. Code of Conduct & Prohibited Uses',
    body: 'When using College Kundli, users and guides strictly agree NOT to:',
    numbered: true,
    bullets: [
      'Use abusive, profane, harassing, discriminatory, or sexually explicit '
          'language during calls or chat sessions.',
      'Share or request personal contact information (Phone numbers, Personal '
          'Emails, Social Media handles, or Bank Account details) to bypass the '
          'platform.',
      'Attempt or process off-platform transactions.',
      'Record, stream, screenshot, or distribute audio calls or private chat '
          'logs without explicit written consent from all parties and College '
          'Kundli.',
      'Post defamatory, false, or malicious college reviews.',
    ],
    footer: 'Violation of these conduct rules will result in immediate '
        'suspension, wallet forfeiture, or a permanent ban.',
  ),
  LegalSection(
    heading: '6. Disclaimer of Warranties & Limitation of Liability',
    bullets: [
      'Informational Purpose: Opinions, advice, and reviews provided by Guides '
          'are their personal views and experiences. College Kundli does not '
          'guarantee admission, academic success, or job placement based on '
          'Guide advice.',
      'Independent Verification: Users are strongly advised to independently '
          'verify critical admission deadlines, fee structures, and course '
          'details via official university websites.',
      'Service Interruptions: College Kundli is not liable for temporary '
          'service interruptions, call drops, or network failures caused by '
          'third-party infrastructure.',
    ],
  ),
  LegalSection(
    heading: '7. Intellectual Property',
    body: 'All rights, title, and interest in and to the College Kundli '
        'platform—including app design, branding, code, database schemas, and '
        'features—are and will remain the exclusive property of College '
        'Kundli.',
  ),
  LegalSection(
    heading: '8. Governing Law & Jurisdiction',
    body: 'These Terms shall be governed, construed, and enforced in accordance '
        'with the Laws of India, including the Information Technology Act, '
        '2000. Any disputes arising under or in connection with these Terms '
        'shall be subject to the exclusive jurisdiction of the courts located '
        'in Pune, Maharashtra, India.',
  ),
  LegalSection(
    heading: '9. Contact Us',
    body: 'If you have any questions or concerns regarding these Terms & '
        'Conditions, please reach out to us at support@collegereality.in or '
        'via the in-app Help & Support section.',
  ),
];

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Terms & Conditions',
      intro: termsAndConditionsIntro,
      sections: termsOfServiceSections,
      contactEmail: termsContactEmail,
    );
  }
}
