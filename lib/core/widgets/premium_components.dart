import 'package:flutter/material.dart';
import '../../config/theme/app_fonts.dart';

import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_elevation.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_theme.dart';

/// Premium card with soft elevation — calm, layered product feel.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;

  const PremiumCard({
    required this.child,
    this.padding,
    this.onTap,
    this.radius = AppSpacing.radiusLg,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.tokens;
    final bg = color ?? tokens.surfaceElevated;
    final borderRadius = BorderRadius.circular(radius);

    // Every PremiumCard provides its own Material ancestor — not just when
    // tappable — so widgets like ListTile/SwitchListTile/Chip that paint on
    // the nearest Material (ink splashes, selection color) work correctly
    // when nested inside, even without an onTap on the card itself.
    final content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius,
        boxShadow: isDark ? AppElevation.none : AppElevation.soft(AppTheme.primaryDark),
        border: Border.all(
          color: isDark
              ? tokens.borderSubtle.withValues(alpha: 0.6)
              : tokens.borderSubtle.withValues(alpha: 0.85),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        clipBehavior: onTap != null ? Clip.antiAlias : Clip.none,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, borderRadius: borderRadius, child: content),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.plusJakarta(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.15,
                    color: tokens.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppFonts.plusJakarta(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: tokens.textTertiary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PremiumChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool selected;

  const PremiumChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final onSelected = isDark ? AppTheme.gray900 : AppTheme.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.chipRadius),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(tokens.chipRadius),
            border: Border.all(
              color: selected ? colorScheme.primary : tokens.borderSubtle,
            ),
            boxShadow: selected || isDark
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? onSelected : colorScheme.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppFonts.plusJakarta(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? onSelected : tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FadeInSection extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const FadeInSection({
    required this.child,
    this.delayMs = 0,
    super.key,
  });

  @override
  State<FadeInSection> createState() => _FadeInSectionState();
}

class _FadeInSectionState extends State<FadeInSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
