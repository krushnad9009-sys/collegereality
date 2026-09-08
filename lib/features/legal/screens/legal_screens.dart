import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_theme.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final List<LegalSection> sections;

  /// Optional lead-in paragraph rendered above the first section.
  final String? intro;

  const LegalDocumentScreen({
    required this.title,
    required this.sections,
    this.intro,
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
            Text(
              section.heading,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              section.body,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.gray700,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (title.contains('Privacy'))
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse('mailto:privacy@collegereality.in'),
              ),
              child: const Text('Contact: privacy@collegereality.in'),
            ),
        ],
      ),
    );
  }
}

class LegalSection {
  final String heading;
  final String body;

  const LegalSection({required this.heading, required this.body});
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Privacy Policy',
      sections: [
        LegalSection(
          heading: 'Overview',
          body:
              'College Reality India ("we", "our") respects your privacy. This policy explains how we collect, use, and protect your information when you use our mobile application.',
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

/// Lead-in paragraph shown above [termsOfServiceSections].
const String termsAndConditionsIntro =
    'Welcome to College Reality ("Platform"). By accessing or using our '
    'services, you agree to be bound by these Terms:';

/// Canonical Terms & Conditions copy, shared by the read-only
/// [TermsOfServiceScreen] and the mandatory post-login [TermsGateScreen].
const List<LegalSection> termsOfServiceSections = [
  LegalSection(
    heading: '1. User Role & Intermediary Status',
    body:
        'College Reality is a peer-to-peer informational platform connecting '
        'prospective students with verified seniors/alumni. The views, answers, '
        'and reviews expressed by verified users are strictly their personal '
        'opinions and do not represent the official stance of any educational '
        'institution or this Platform.',
  ),
  LegalSection(
    heading: '2. Document Verification & AI Processing',
    body:
        'Document upload for verification (Aadhaar/College ID/Marksheet) is '
        'processed via automated system algorithms solely to maintain community '
        'trust. Documents are handled securely and never sold to third parties. '
        'Uploading fake, altered, or fraudulent documents will result in '
        'immediate termination.',
  ),
  LegalSection(
    heading: '3. Institutional Disclaimer',
    body:
        'Colleges listed on this platform are for informational and '
        'navigational purposes only. College Reality is an independent entity '
        'and is not directly endorsed by or affiliated with the listed '
        'institutions.',
  ),
  LegalSection(
    heading: '4. No Admission Guarantee & Counseling Disclaimer',
    body:
        'The platform, its AI prediction tools, and verified peers offer '
        'guidance based on past data and personal experiences. The Platform '
        'provides NO GUARANTEE for admission, seats, or official cut-offs. All '
        'admission decisions rest solely with the student and parents.',
  ),
  LegalSection(
    heading: '5. Code of Conduct & Misuse',
    body:
        'Harassment, abusive language, spamming, or sharing false marketing '
        'content in chats or reviews is strictly prohibited. Any violation will '
        'lead to immediate content removal and permanent account suspension.',
  ),
  LegalSection(
    heading: '6. Account Termination Rights',
    body:
        'The Admin reserves the full right to suspend or permanently block any '
        'account found violating community standards, uploading fraudulent '
        'verification proofs, or engaging in unauthorized activity without '
        'prior notice or refund.',
  ),
  LegalSection(
    heading: '7. Data Privacy & Safety',
    body:
        'User data and verification documents are encrypted and managed in '
        'accordance with applicable privacy standards. Verification records are '
        'strictly accessed for validation purposes.',
  ),
  LegalSection(
    heading: '8. Limitation of Liability',
    body:
        'The Platform shall not be held liable for any financial, academic, or '
        'personal decisions made based on chats, recommendations, or reviews '
        'hosted on the platform.',
  ),
  LegalSection(
    heading: '9. Jurisdiction & Dispute Resolution',
    body:
        'Any legal disputes arising out of or in connection with this Platform '
        'shall be subject to the exclusive jurisdiction of the courts located '
        'in Pune, Maharashtra, India.',
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
    );
  }
}
