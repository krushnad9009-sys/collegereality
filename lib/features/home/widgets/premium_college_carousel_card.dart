import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/cr_score_constants.dart';
import '../../../core/widgets/college_image_widget.dart';
import '../../../core/widgets/college_logo_widget.dart';
import '../../colleges/models/college_model.dart';
import '../../ranking/utils/cr_score_engine.dart';

/// Premium horizontal college card for home carousels.
class PremiumCollegeCarouselCard extends StatefulWidget {
  final CollegeModel college;
  final VoidCallback? onTap;
  final double? height;

  const PremiumCollegeCarouselCard({
    required this.college,
    this.onTap,
    this.height,
    super.key,
  });

  @override
  State<PremiumCollegeCarouselCard> createState() =>
      _PremiumCollegeCarouselCardState();
}

class _PremiumCollegeCarouselCardState
    extends State<PremiumCollegeCarouselCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final crScore = CrScoreEngine.effectiveScore(widget.college);
    const cardWidth = 300.0;
    const imageHeight = 168.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap ??
          () => context.go(RouteNames.collegeDetailsPath(widget.college.id)),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: cardWidth,
          height: widget.height,
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppTheme.primaryDark.withValues(alpha: 0.1),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: AppTheme.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
            border: Border.all(
              color: tokens.borderSubtle.withValues(alpha: isDark ? 0.45 : 0.8),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: imageHeight,
                width: cardWidth,
                child: Stack(
                  children: [
                    CollegeImageWidget(
                      collegeId: widget.college.id,
                      imageUrl: widget.college.coverPhotoUrl,
                      height: imageHeight,
                      width: cardWidth,
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.5),
                          ],
                          stops: const [0.5, 1],
                        ),
                      ),
                    ),
                  ),
                  if (widget.college.isFeatured)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.accentColor, Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Trending',
                          style: AppFonts.plusJakarta(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (crScore > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _CarouselCrBadge(score: crScore),
                    ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CollegeLogoWidget(
                        collegeId: widget.college.id,
                        collegeName: widget.college.name,
                        logoUrl: widget.college.logoUrl,
                        radius: 20,
                      ),
                    ),
                  ),
                ],
              ),
              ),
              Expanded(
                child: ClipRect(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                      widget.college.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.plusJakarta(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.3,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.primaryColor.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${widget.college.city}, ${widget.college.state}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.plusJakarta(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (widget.college.ownershipLabel.isNotEmpty)
                          _CarouselMetaPill(
                            icon: Icons.account_balance_outlined,
                            label: widget.college.ownershipLabel,
                            color: AppTheme.primaryColor,
                          ),
                        if (widget.college.category != 'General')
                          _CarouselMetaPill(
                            icon: Icons.category_outlined,
                            label: widget.college.category,
                            color: AppTheme.secondaryColor,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MiniStat(
                          icon: Icons.work_outline_rounded,
                          value: widget.college.aggregatedRatings.placements > 0
                              ? widget.college.aggregatedRatings.placements
                                  .toStringAsFixed(1)
                              : '—',
                          label: 'Placement',
                          color: AppTheme.accentColor,
                        ),
                        const SizedBox(width: 8),
                        _MiniStat(
                          icon: Icons.star_rounded,
                          value: widget.college.aggregatedRatings.overall > 0
                              ? widget.college.aggregatedRatings.overall
                                  .toStringAsFixed(1)
                              : '—',
                          label: '${widget.college.reviewCount} reviews',
                          color: AppTheme.warningColor,
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarouselCrBadge extends StatelessWidget {
  final double score;

  const _CarouselCrBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = CrScoreConstants.colorForScore(score);
    final grade = CrScoreConstants.gradeForScore(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.white, 0.12) ?? color],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CR ${score.toStringAsFixed(0)}',
            style: AppFonts.plusJakarta(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          Text(
            grade,
            style: AppFonts.plusJakarta(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CarouselMetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppFonts.plusJakarta(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                      height: 1,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.plusJakarta(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
