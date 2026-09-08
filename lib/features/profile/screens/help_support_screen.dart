import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/widgets/index.dart';

/// Help & Support hub: contact channels and legal documents.
/// Reached from the Profile hub via "Help & Support".
class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  static const _supportEmail = 'support@collegereality.in';

  Future<void> _email(BuildContext context, {required String subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'No email app found. Write to $_supportEmail',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.lg,
          AppSpacing.pageH,
          AppSpacing.section,
        ),
        children: [
          PremiumCard(
            radius: tokens.cardRadius,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                PremiumListRow(
                  leadingIcon: Icons.mail_outline_rounded,
                  title: 'Contact support',
                  subtitle: _supportEmail,
                  onTap: () => _email(
                    context,
                    subject: 'College Reality — Support request',
                  ),
                ),
                Divider(color: tokens.borderSubtle, height: 1),
                PremiumListRow(
                  leadingIcon: Icons.bug_report_outlined,
                  title: 'Report a problem',
                  subtitle: 'Tell us what went wrong',
                  onTap: () => _email(
                    context,
                    subject: 'College Reality — Bug report',
                  ),
                ),
                Divider(color: tokens.borderSubtle, height: 1),
                PremiumListRow(
                  leadingIcon: Icons.lightbulb_outline_rounded,
                  title: 'Suggest an improvement',
                  onTap: () => _email(
                    context,
                    subject: 'College Reality — Feedback',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PremiumCard(
            radius: tokens.cardRadius,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                PremiumListRow(
                  leadingIcon: Icons.privacy_tip_outlined,
                  title: 'Privacy policy',
                  onTap: () => context.push(RouteNames.privacyPolicy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
