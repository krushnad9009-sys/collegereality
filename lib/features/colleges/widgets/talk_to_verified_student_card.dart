import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

/// Bold hero version of the "Talk to a Verified Student" USP, designed to sit
/// high on the college profile — directly under the name / rating / location —
/// so the single most valuable action is the first thing a deciding student
/// sees. Gradient surface, trust line, and one unmissable primary CTA.
class TalkToVerifiedStudentHero extends StatelessWidget {
  final String collegeName;

  /// Verified students + alumni linked to this college. Drives the trust line
  /// ("N verified students & alumni"); a friendly fallback shows when 0.
  final int verifiedCount;

  const TalkToVerifiedStudentHero({
    required this.collegeName,
    this.verifiedCount = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final radius = tokens.cardRadius;

    final trustLine = verifiedCount > 0
        ? '$verifiedCount verified ${verifiedCount == 1 ? 'student' : 'students'} & alumni ready to help'
        : 'Only document-verified students & alumni — no fake reviews';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THE #1 WAY TO KNOW THE REALITY',
                        style: AppFonts.plusJakarta(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Talk to a Verified Student',
                        style: AppFonts.plusJakarta(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Get honest answers about $collegeName — placements, hostel, '
              'teaching, campus life — from people who actually study there.',
              style: AppFonts.plusJakarta(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trustLine,
                    style: AppFonts.plusJakarta(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go(RouteNames.guidesDirectory),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: scheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.buttonRadius),
                  ),
                ),
                icon: const Icon(Icons.forum_rounded, size: 18),
                label: Text(
                  'Connect with Verified Students',
                  style: AppFonts.plusJakarta(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
