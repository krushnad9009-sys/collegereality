import 'package:flutter/material.dart';

import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_fonts.dart';
import '../../config/theme/app_spacing.dart';

/// Tokens-based replacement for ad hoc `Card`+`ListTile` rows — an icon in a
/// soft tinted badge, a title/subtitle column, and a trailing widget
/// (defaults to a chevron). Use this anywhere a plain `ListTile` currently
/// stands in for a settings row, menu item, or link-out card.
class PremiumListRow extends StatelessWidget {
  final IconData? leadingIcon;
  final Widget? leading;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool dense;

  const PremiumListRow({
    required this.title,
    this.leadingIcon,
    this.leading,
    this.iconColor,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.dense = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final accent = iconColor ?? primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: dense ? AppSpacing.sm : AppSpacing.md,
          ),
          child: Row(
            children: [
              if (leading != null)
                leading!
              else if (leadingIcon != null) ...[
                Container(
                  width: dense ? 34 : 40,
                  height: dense ? 34 : 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(tokens.buttonRadius * 0.65),
                  ),
                  child: Icon(leadingIcon, size: dense ? 18 : 20, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppFonts.plusJakarta(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? tokens.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppFonts.plusJakarta(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: tokens.textTertiary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (showChevron && onTap != null)
                Icon(Icons.chevron_right_rounded, color: tokens.textTertiary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
