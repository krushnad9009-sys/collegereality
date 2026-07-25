import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_typography.dart';
import 'onboarding_illustrations.dart';
import 'onboarding_palette.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.scene,
    required this.pageIndex,
  });

  final String title;
  final String subtitle;
  final String description;
  final OnboardingScene scene;
  final int pageIndex;
}

class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({
    required this.page,
    required this.pageOffset,
    required this.animationValue,
    required this.maxContentWidth,
    required this.bottomInset,
    required this.bottomControlsHeight,
    super.key,
  });

  final OnboardingPageData page;
  final double pageOffset;
  final double animationValue;
  final double maxContentWidth;
  final double bottomInset;
  final double bottomControlsHeight;

  double _illustrationSize({
    required double width,
    required double availableHeight,
    required bool isCompact,
    required bool isWide,
  }) {
    final widthCap = isWide ? 340.0 : (isCompact ? 240.0 : 300.0);
    final heightCap = (availableHeight * 0.42).clamp(160.0, 340.0);
    return widthCap.clamp(160.0, heightCap);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isWide = constraints.maxWidth >= 900;
        final isShort = constraints.maxHeight < 680;
        final topInset = MediaQuery.of(context).padding.top;

        final availableHeight =
            constraints.maxHeight - topInset - bottomControlsHeight - bottomInset;

        final illustrationSize = _illustrationSize(
          width: constraints.maxWidth,
          availableHeight: availableHeight,
          isCompact: isCompact,
          isWide: isWide,
        );

        final opacity = (1 - pageOffset.abs() * 0.65).clamp(0.0, 1.0);
        final slideX = pageOffset * 48;
        final slideY = pageOffset.abs() * 10;
        final contentScale = (1 - pageOffset.abs() * 0.05).clamp(0.92, 1.0);
        final accent = OnboardingPalette.accentFor(page.pageIndex);

        final titleSize = isWide ? 38.0 : (isCompact ? (isShort ? 28.0 : 32.0) : 36.0);
        final bodySize = isCompact ? (isShort ? 14.0 : 15.0) : 16.0;
        final sectionGap = isShort ? AppSpacing.lg : AppSpacing.section;
        final textGap = isShort ? AppSpacing.sm : AppSpacing.md;

        return SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? AppSpacing.xxl : AppSpacing.section,
              isShort ? AppSpacing.lg : AppSpacing.section,
              isCompact ? AppSpacing.xxl : AppSpacing.section,
              bottomControlsHeight + bottomInset,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: availableHeight.clamp(0, double.infinity),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(slideX, slideY),
                        child: Transform.scale(
                          scale: contentScale,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _IllustrationFrame(
                                accent: accent,
                                compact: isShort,
                                child: OnboardingAnimatedIllustration(
                                  scene: page.scene,
                                  animationValue: animationValue,
                                  pageOffset: pageOffset,
                                  size: illustrationSize,
                                ),
                              ),
                              SizedBox(height: sectionGap),
                              Text(
                                page.title,
                                style: AppTypography.display(page.title).copyWith(
                                      fontSize: titleSize,
                                      color: OnboardingPalette.ink,
                                      height: 1.08,
                                      letterSpacing: -0.8,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                softWrap: true,
                              ),
                              SizedBox(height: textGap),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: isShort ? AppSpacing.xs : AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: accent.withValues(alpha: 0.14)),
                                ),
                                child: Text(
                                  page.subtitle,
                                  style: AppTypography.label(page.subtitle).copyWith(
                                        fontSize: isShort ? 10 : 11,
                                        letterSpacing: 1.1,
                                        color: accent,
                                      ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: isShort ? AppSpacing.md : AppSpacing.lg),
                              Text(
                                page.description,
                                style: AppTypography.body(page.description).copyWith(
                                      fontSize: bodySize,
                                      color: OnboardingPalette.inkMuted,
                                      height: 1.55,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IllustrationFrame extends StatelessWidget {
  const _IllustrationFrame({
    required this.accent,
    required this.child,
    this.compact = false,
  });

  final Color accent;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 24 : 32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OnboardingPalette.warmWhite,
            accent.withValues(alpha: 0.06),
            OnboardingPalette.warmWhiteDeep,
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: compact ? 28 : 40,
            offset: Offset(0, compact ? 12 : 18),
          ),
          BoxShadow(
            color: OnboardingPalette.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.md : AppSpacing.lg,
          vertical: compact ? AppSpacing.lg : AppSpacing.xl,
        ),
        child: child,
      ),
    );
  }
}
