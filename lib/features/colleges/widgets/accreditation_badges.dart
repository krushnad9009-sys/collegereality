import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../models/college_model.dart';

class AccreditationBadges extends StatelessWidget {
  final CollegeAccreditation accreditation;
  final String? universityName;

  const AccreditationBadges({
    required this.accreditation,
    this.universityName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    if (universityName != null && universityName!.trim().isNotEmpty) {
      badges.add(_Badge(
        label: universityName!,
        icon: Icons.account_balance_outlined,
        color: const Color(0xFF1E40AF),
      ));
    }
    if (accreditation.naacGrade != null &&
        accreditation.naacGrade!.isNotEmpty &&
        accreditation.naacGrade != 'Not Accredited') {
      badges.add(_Badge(
        label: 'NAAC ${accreditation.naacGrade}',
        icon: Icons.verified_outlined,
        color: const Color(0xFF059669),
      ));
    }
    if (accreditation.nirfRank != null && accreditation.nirfRank! > 0) {
      final category = accreditation.nirfCategory?.isNotEmpty == true
          ? ' (${accreditation.nirfCategory})'
          : '';
      badges.add(_Badge(
        label: 'NIRF #${accreditation.nirfRank}$category',
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFFD97706),
      ));
    }
    if (accreditation.ugcRecognized) {
      badges.add(const _Badge(
        label: 'UGC',
        icon: Icons.check_circle_outline,
        color: Color(0xFF7C3AED),
      ));
    }
    if (accreditation.aicteApproved) {
      badges.add(const _Badge(
        label: 'AICTE',
        icon: Icons.approval_outlined,
        color: Color(0xFFDC2626),
      ));
    }

    if (badges.isEmpty) {
      return Text(
        'Accreditation details unavailable',
        style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.gray500),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: badges);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
