import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_theme.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final List<LegalSection> sections;

  const LegalDocumentScreen({
    required this.title,
    required this.sections,
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
              'Your data is stored securely using Google Firebase services. You may request account deletion from your profile settings.',
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

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Terms of Service',
      sections: [
        LegalSection(
          heading: 'Acceptance',
          body:
              'By using College Reality India, you agree to these Terms of Service and our Privacy Policy.',
        ),
        LegalSection(
          heading: 'User Content',
          body:
              'Reviews and community posts must be honest and respectful. We may remove content that violates our community guidelines or applicable law.',
        ),
        LegalSection(
          heading: 'College Information',
          body:
              'College listings are compiled from official AISHE data and user contributions. We strive for accuracy but do not guarantee completeness. Verify admission details with institutions directly.',
        ),
        LegalSection(
          heading: 'Account Termination',
          body:
              'You may delete your account at any time. We may suspend accounts that abuse the platform.',
        ),
      ],
    );
  }
}
