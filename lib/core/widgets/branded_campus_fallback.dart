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

  /// Full college name, used to render a real initials watermark (e.g. "GT")
  /// instead of a generic school icon, so every fallback is visually
  /// distinct per college rather than identical branding. Optional so
  /// existing call sites that only have a collegeId keep working.
  final String? collegeName;

  const BrandedCampusFallback({
    required this.collegeId,
    required this.height,
    this.width,
    this.borderRadius,
    this.collegeName,
    super.key,
  });

  String get _initials {
    final name = collegeName?.trim() ?? '';
    if (name.isEmpty) return '';
    final parts = name.split(RegExp(r'\s+'));
    return parts.length >= 2
        ? '${parts.first[0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = CollegeImageHelper.coverGradient(collegeId);
    final initials = _initials;

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
          if (initials.isNotEmpty)
            // The college's own initials, oversized and low-opacity, as a
            // deterministic per-college watermark -- this is what makes
            // every fallback look designed and distinct instead of every
            // photo-less college sharing one identical generic mark.
            Positioned(
              right: -height * 0.14,
              top: -height * 0.22,
              child: Text(
                initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: height * 0.95,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.14),
                  height: 1,
                  letterSpacing: -4,
                ),
              ),
            )
          else
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
                  initials.isNotEmpty ? initials : 'College Reality',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: initials.isNotEmpty ? 20 : 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.95),
                    letterSpacing: initials.isNotEmpty ? 1 : 0.4,
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
