import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';

/// College detail overflow menu for ecosystem actions.
class CollegeEcosystemMenu extends StatelessWidget {
  final String collegeId;
  final String collegeName;

  const CollegeEcosystemMenu({
    required this.collegeId,
    required this.collegeName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'request':
            context.push(RouteNames.requestCollege);
          case 'edit':
            context.push(RouteNames.suggestEditPath(collegeId, collegeName));
          case 'report':
            context.push(RouteNames.reportCollegeDataPath(collegeId, collegeName));
          case 'claim':
            context.push(RouteNames.claimCollegePath(collegeId, collegeName));
        }
      },
      itemBuilder: (context) => [
        _item('request', Icons.add_business_outlined, 'Add My College'),
        _item('edit', Icons.edit_outlined, 'Suggest Edit'),
        _item('report', Icons.flag_outlined, 'Report Wrong Info'),
        _item('claim', Icons.verified_outlined, 'Claim College'),
      ],
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
        ],
      ),
    );
  }
}
