import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_theme.dart';
import '../utils/college_image_helper.dart';

/// Cached circular logo for college cards and detail headers.
class CollegeLogoWidget extends StatelessWidget {
  final String? logoUrl;
  final String collegeId;
  final String collegeName;
  final double radius;

  const CollegeLogoWidget({
    required this.collegeId,
    required this.collegeName,
    this.logoUrl,
    this.radius = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = CollegeImageHelper.resolveLogoUrl(logoUrl, collegeId: collegeId);
    if (resolved != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.gray100,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: resolved,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            memCacheWidth: (radius * 2 * 2).round(),
            placeholder: (_, _) => _initials(),
            errorWidget: (_, _, _) => _initials(),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: CollegeImageHelper.logoColor(collegeId),
      child: _initials(),
    );
  }

  Widget _initials() {
    final parts = collegeName.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts[1][0]}'.toUpperCase()
        : collegeName.isNotEmpty
            ? collegeName[0].toUpperCase()
            : 'C';
    return Text(
      initials,
      style: GoogleFonts.poppins(
        fontSize: radius * 0.75,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}
