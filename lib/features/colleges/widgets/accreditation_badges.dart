import 'package:flutter/material.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/widgets/status_badge.dart';
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
      badges.add(StatusBadge(
        label: universityName!,
        icon: Icons.account_balance_outlined,
        color: const Color(0xFF1E40AF),
      ));
    }
    if (accreditation.naacGrade != null &&
        accreditation.naacGrade!.isNotEmpty &&
        accreditation.naacGrade != 'Not Accredited') {
      badges.add(StatusBadge(
        label: 'NAAC ${accreditation.naacGrade}',
        icon: Icons.verified_outlined,
        color: const Color(0xFF059669),
      ));
    }
    if (accreditation.nirfRank != null && accreditation.nirfRank! > 0) {
      final category = accreditation.nirfCategory?.isNotEmpty == true
          ? ' (${accreditation.nirfCategory})'
          : '';
      badges.add(StatusBadge(
        label: 'NIRF #${accreditation.nirfRank}$category',
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFFD97706),
      ));
    }
    if (accreditation.ugcRecognized) {
      badges.add(const StatusBadge(
        label: 'UGC',
        icon: Icons.check_circle_outline,
        color: Color(0xFF7C3AED),
      ));
    }
    if (accreditation.aicteApproved) {
      badges.add(const StatusBadge(
        label: 'AICTE',
        icon: Icons.approval_outlined,
        color: Color(0xFFDC2626),
      ));
    }

    if (badges.isEmpty) {
      return Text(
        'Accreditation details unavailable',
        style: AppFonts.plusJakarta(
          fontSize: 13,
          color: context.tokens.textTertiary,
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: badges);
  }
}
