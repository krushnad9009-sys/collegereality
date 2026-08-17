import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

/// College-specific "Talk to a Verified Student" decision-making CTA.
///
/// This is the single entry point into the verified-student/alumni
/// consultation flow (same [RouteNames.guidesDirectory] destination the
/// old Home-screen CTA used to open) — now placed where it belongs: on the
/// college a student is actually deciding about, with copy naming that
/// college rather than a generic pitch.
class TalkToVerifiedStudentCard extends StatelessWidget {
  final String collegeName;

  const TalkToVerifiedStudentCard({required this.collegeName, super.key});

  /// Uses the college's real short-form name (e.g. "COEP", "IIT") in the
  /// headline when the name is already commonly written that way; never
  /// invents an abbreviation. The full college name always appears in the
  /// supporting line.
  String get _headline {
    final words = collegeName.trim().split(RegExp(r'\s+'));
    final firstWord = words.isNotEmpty ? words.first : '';
    final looksLikeAcronym = firstWord.length >= 2 &&
        firstWord.length <= 6 &&
        RegExp(r'^[A-Z]+$').hasMatch(firstWord);
    return looksLikeAcronym ? 'Talk to a Verified $firstWord Student' : 'Talk to a Verified Student';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(RouteNames.guidesDirectory),
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(tokens.buttonRadius * 0.85),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _headline,
                      style: AppFonts.plusJakarta(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Get real answers from students who actually study at $collegeName.',
                style: AppFonts.plusJakarta(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Talk to a Verified Student',
                    style: AppFonts.plusJakarta(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
