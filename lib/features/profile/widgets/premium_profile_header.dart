import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../models/premium_student_profile.dart';
import '../../verification/widgets/verification_badge_widget.dart';
import 'availability_chip.dart';

class PremiumProfileHeader extends StatelessWidget {
  final PremiumStudentProfile profile;

  const PremiumProfileHeader({required this.profile, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(tokens.cardRadius),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.85),
                    primary.withValues(alpha: 0.45),
                  ],
                ),
                image: profile.coverPhotoURL != null
                    ? DecorationImage(
                        image: NetworkImage(profile.coverPhotoURL!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.18),
                          BlendMode.darken,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              left: AppSpacing.xl,
              bottom: -40,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.surfaceElevated,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  backgroundImage: profile.photoURL != null
                      ? NetworkImage(profile.photoURL!)
                      : null,
                  child: profile.photoURL == null
                      ? Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName[0].toUpperCase()
                              : 'S',
                          style: AppFonts.plusJakarta(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 52),
        Text(
          profile.displayName,
          style: AppFonts.plusJakarta(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: tokens.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            VerificationBadgeWidget(badge: profile.verificationBadge),
            AvailabilityChip(status: profile.effectiveAvailability),
          ],
        ),
      ],
    );
  }
}
