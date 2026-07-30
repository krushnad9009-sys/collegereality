import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/cr_score_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../colleges/models/college_model.dart';
import '../../engagement/providers/engagement_provider.dart';
import '../../ranking/utils/cr_score_engine.dart';
import '../../../core/widgets/college_image_widget.dart';
import '../../../core/widgets/college_logo_widget.dart';

/// Production-grade college card used across Home, Search, and Browse.
class CollegeCardWidget extends ConsumerStatefulWidget {
  final String collegeId;
  final String collegeName;
  final String location;
  final String city;
  final double rating;
  final double? crScore;
  final double placementRating;
  final int reviewCount;
  final String? imageUrl;
  final String? logoUrl;
  final bool showVerifiedBadge;
  final VoidCallback? onTap;
  final bool isSelectedForCompare;
  final VoidCallback? onCompareToggle;
  final bool compact;
  final bool showSaveButton;
  final String? ownershipLabel;
  final String? categoryLabel;

  const CollegeCardWidget({
    required this.collegeId,
    required this.collegeName,
    required this.location,
    required this.city,
    required this.rating,
    this.crScore,
    this.placementRating = 0,
    required this.reviewCount,
    this.imageUrl,
    this.logoUrl,
    this.showVerifiedBadge = false,
    this.onTap,
    this.isSelectedForCompare = false,
    this.onCompareToggle,
    this.compact = false,
    this.showSaveButton = true,
    this.ownershipLabel,
    this.categoryLabel,
    super.key,
  });

  factory CollegeCardWidget.fromCollege(
    CollegeModel college, {
    VoidCallback? onTap,
    bool isSelectedForCompare = false,
    VoidCallback? onCompareToggle,
    bool compact = false,
  }) {
    return CollegeCardWidget(
      collegeId: college.id,
      collegeName: college.name,
      location: college.state,
      city: college.city,
      rating: college.aggregatedRatings.overall,
      placementRating: college.aggregatedRatings.placements,
      crScore: CrScoreEngine.effectiveScore(college),
      reviewCount: college.reviewCount,
      imageUrl: college.coverPhotoUrl,
      logoUrl: college.logoUrl,
      showVerifiedBadge:
          college.verifiedStudentCount > 0 || college.reviewCount >= 3,
      ownershipLabel: college.ownershipLabel,
      categoryLabel: college.category != 'General' ? college.category : null,
      onTap: onTap,
      isSelectedForCompare: isSelectedForCompare,
      onCompareToggle: onCompareToggle,
      compact: compact,
    );
  }

  @override
  ConsumerState<CollegeCardWidget> createState() => _CollegeCardWidgetState();
}

class _CollegeCardWidgetState extends ConsumerState<CollegeCardWidget> {
  bool _pressed = false;

  Future<void> _toggleSave() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to save colleges')),
        );
        context.go(RouteNames.login);
      }
      return;
    }
    await ref
        .read(engagementRepositoryProvider)
        .toggleFavoriteCollege(user.uid, widget.collegeId);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = tokens.cardRadius;
    final imageHeight = widget.compact ? 152.0 : 204.0;
    final favoriteIds =
        ref.watch(favoriteCollegeIdsProvider).valueOrNull ?? {};
    final isSaved = favoriteIds.contains(widget.collegeId);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.982 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: widget.isSelectedForCompare
                  ? AppTheme.accentColor.withValues(alpha: 0.55)
                  : tokens.borderSubtle.withValues(alpha: isDark ? 0.45 : 0.85),
              width: widget.isSelectedForCompare ? 1.5 : 1,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.38),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppTheme.primaryDark.withValues(alpha: 0.09),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: AppTheme.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CollegeImageWidget(
                    collegeId: widget.collegeId,
                    imageUrl: widget.imageUrl,
                    height: imageHeight,
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.62),
                          ],
                          stops: const [0.42, 1],
                        ),
                      ),
                    ),
                  ),
                  if (widget.showVerifiedBadge)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _VerifiedChip(),
                    ),
                  if (widget.crScore != null && widget.crScore! > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _CrScoreBadge(score: widget.crScore!),
                    ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: _LogoFrame(
                      collegeId: widget.collegeId,
                      collegeName: widget.collegeName,
                      logoUrl: widget.logoUrl,
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.showSaveButton)
                          _ActionChip(
                            icon: isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            selected: isSaved,
                            tooltip: isSaved ? 'Saved' : 'Save college',
                            onTap: _toggleSave,
                          ),
                        if (widget.onCompareToggle != null) ...[
                          const SizedBox(width: 6),
                          _ActionChip(
                            icon: widget.isSelectedForCompare
                                ? Icons.check_rounded
                                : Icons.compare_arrows_rounded,
                            selected: widget.isSelectedForCompare,
                            tooltip: widget.isSelectedForCompare
                                ? 'In compare'
                                : 'Compare',
                            onTap: widget.onCompareToggle!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  widget.compact ? AppSpacing.lg : AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.collegeName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: widget.compact ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        height: 1.22,
                        letterSpacing: -0.35,
                        color: tokens.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppTheme.primaryColor.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${widget.city}, ${widget.location}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: tokens.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.ownershipLabel != null &&
                            widget.ownershipLabel!.isNotEmpty)
                          _MetricPill(
                            icon: Icons.account_balance_outlined,
                            label: widget.ownershipLabel!,
                            color: AppTheme.primaryColor,
                          ),
                        if (widget.categoryLabel != null &&
                            widget.categoryLabel!.isNotEmpty)
                          _MetricPill(
                            icon: Icons.category_outlined,
                            label: widget.categoryLabel!,
                            color: AppTheme.secondaryColor,
                          ),
                        _MetricPill(
                          icon: Icons.work_outline_rounded,
                          label: widget.placementRating > 0
                              ? '${widget.placementRating.toStringAsFixed(1)} Placement'
                              : 'Placements',
                          color: AppTheme.accentColor,
                        ),
                        _MetricPill(
                          icon: Icons.star_rounded,
                          label: widget.rating > 0
                              ? '${widget.rating.toStringAsFixed(1)} · ${widget.reviewCount} reviews'
                              : '${widget.reviewCount} reviews',
                          color: AppTheme.warningColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrScoreBadge extends StatelessWidget {
  final double score;

  const _CrScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = CrScoreConstants.colorForScore(score);
    final grade = CrScoreConstants.gradeForScore(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.white, 0.14) ?? color],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'CR SCORE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          Text(
            score.toStringAsFixed(0),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
              color: Colors.white,
            ),
          ),
          Text(
            grade,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoFrame extends StatelessWidget {
  final String collegeId;
  final String collegeName;
  final String? logoUrl;

  const _LogoFrame({
    required this.collegeId,
    required this.collegeName,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CollegeLogoWidget(
        collegeId: collegeId,
        collegeName: collegeName,
        logoUrl: logoUrl,
        radius: 22,
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.accentColor
                  : Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppTheme.gray700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
