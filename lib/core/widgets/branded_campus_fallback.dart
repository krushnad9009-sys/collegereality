import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_theme.dart';
import '../utils/college_image_helper.dart';

/// Branded fallback when no campus photo URL is available.
class BrandedCampusFallback extends StatelessWidget {
  final String collegeId;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const BrandedCampusFallback({
    required this.collegeId,
    required this.height,
    this.width,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CollegeImageHelper.coverGradient(collegeId);

    final content = Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Icon(
              Icons.account_balance_rounded,
              size: height * 0.75,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'College Reality',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.92),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: height * 0.35,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.black.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }
}
