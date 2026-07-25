import 'package:flutter/material.dart';

import '../../../../config/theme/app_typography.dart';
import 'onboarding_palette.dart';

class OnboardingGradientButton extends StatefulWidget {
  const OnboardingGradientButton({
    required this.label,
    required this.onPressed,
    required this.pageIndex,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final int pageIndex;

  @override
  State<OnboardingGradientButton> createState() => _OnboardingGradientButtonState();
}

class _OnboardingGradientButtonState extends State<OnboardingGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingPalette.gradientFor(widget.pageIndex);
    final accent = OnboardingPalette.accentFor(widget.pageIndex);

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.38),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: (_) => _pressController.forward(),
            onTapUp: (_) => _pressController.reverse(),
            onTapCancel: () => _pressController.reverse(),
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white.withValues(alpha: 0.18),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 17),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: AppTypography.button(widget.label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingGhostButton extends StatefulWidget {
  const OnboardingGhostButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<OnboardingGhostButton> createState() => _OnboardingGhostButtonState();
}

class _OnboardingGhostButtonState extends State<OnboardingGhostButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.72),
          border: Border.all(color: OnboardingPalette.inkSoft.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: OnboardingPalette.ink.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: (_) => _pressController.forward(),
            onTapUp: (_) => _pressController.reverse(),
            onTapCancel: () => _pressController.reverse(),
            borderRadius: BorderRadius.circular(18),
            splashColor: OnboardingPalette.royalBlue.withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 17),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: AppTypography.button(widget.label).copyWith(
                      color: OnboardingPalette.royalBlue,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    required this.count,
    required this.pageController,
    required this.currentPage,
    super.key,
  });

  final int count;
  final PageController pageController;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, _) {
        final page = pageController.hasClients && pageController.position.haveDimensions
            ? pageController.page ?? currentPage.toDouble()
            : currentPage.toDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            final distance = (page - index).abs().clamp(0.0, 1.0);
            final isActive = distance < 0.5;
            final width = 8 + (1 - distance) * 22;
            final accent = OnboardingPalette.accentFor(index);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: width,
              height: isActive ? 8 : 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: OnboardingPalette.gradientFor(index),
                      )
                    : null,
                color: isActive ? null : OnboardingPalette.inkSoft.withValues(alpha: 0.22),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}
