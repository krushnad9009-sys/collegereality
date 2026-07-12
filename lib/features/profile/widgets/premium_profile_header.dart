import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../models/premium_student_profile.dart';
import '../../verification/widgets/verification_badge_widget.dart';
import 'availability_chip.dart';

class PremiumProfileHeader extends StatelessWidget {
  final PremiumStudentProfile profile;

  const PremiumProfileHeader({required this.profile, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                image: profile.coverPhotoURL != null
                    ? DecorationImage(
                        image: NetworkImage(profile.coverPhotoURL!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            Positioned(
              left: 20,
              bottom: -40,
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.white,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  backgroundImage: profile.photoURL != null
                      ? NetworkImage(profile.photoURL!)
                      : null,
                  child: profile.photoURL == null
                      ? Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName[0].toUpperCase()
                              : 'S',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Text(
          profile.displayName,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
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
