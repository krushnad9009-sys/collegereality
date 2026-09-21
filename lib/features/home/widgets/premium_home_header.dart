import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_fonts.dart';

/// The hero's greeting block, in white on the royal-blue card:
///
///   Good afternoon, dk007
///   Real reviews & verified CR Scores, personalized for you
///
/// Signed-out visitors get a short welcome instead of a name (their "Sign in"
/// button lives in the hero's top bar).
class PremiumHomeHeader extends StatelessWidget {
  final User? user;
  final String displayName;
  final String subtitle;

  const PremiumHomeHeader({
    required this.user,
    required this.displayName,
    required this.subtitle,
    super.key,
  });

  static String greetingFor(DateTime now) {
    final hour = now.hour;
    return hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = user != null
        ? '${greetingFor(DateTime.now())}, $displayName'
        : 'Find your dream college';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.plusJakarta(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.plusJakarta(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            height: 1.35,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
      ],
    );
  }
}
