import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/config/release_config.dart';
import 'home_header_widget.dart';

/// Side gutter shared by the Home header and the Home body, so the two can
/// never drift apart.
double homeContentGutter(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600 ? AppSpacing.lg : AppSpacing.xxl;

/// Home top bar. It uses the same max width ([AppSpacing.maxContentWidth])
/// and gutter ([homeContentGutter]) as the scrolling body, so the hamburger
/// lines up with the hero card's left edge and the avatar with its right
/// edge on every screen size -- on wide screens the icons no longer sit at
/// the far edges of the window while the content is centred.
///
///   [ ☰ ]  College Reality                    [ 🔔 ] [ D ]
class HomeAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final User? user;
  final VoidCallback onMenuPressed;

  const HomeAppHeader({
    required this.user,
    required this.onMenuPressed,
    super.key,
  });

  // Matches the 42px bell/avatar chips so all three controls share one height.
  static const double _controlSize = 42;
  static const double _verticalPadding = AppSpacing.md;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_controlSize + 2 * _verticalPadding);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Material(
      color: tokens.surfaceMuted,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: homeContentGutter(context),
                vertical: _verticalPadding,
              ),
              child: Row(
                children: [
                  _MenuButton(onPressed: onMenuPressed),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      ReleaseConfig.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.plusJakarta(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  if (user != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    HomeHeaderActions(user: user!, onDark: false),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MenuButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Tooltip(
      message: 'Open navigation menu',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: HomeAppHeader._controlSize,
            height: HomeAppHeader._controlSize,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primary.withValues(alpha: 0.16)),
            ),
            child: Icon(Icons.menu, color: primary, size: 22),
          ),
        ),
      ),
    );
  }
}
