import 'package:flutter/material.dart';

import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_fonts.dart';

/// One shared visual family for every small tinted status/verification pill
/// in the app (verified, trending, featured, CR-score, etc.) — a tinted
/// background, a matching soft border, an optional icon, and a label, all
/// in one consistent shape. Restyle existing badge widgets (guide badges,
/// verification badges, trending pills) to this look rather than
/// reinventing the container each time.
class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final double iconSize;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    required this.label,
    required this.color,
    this.icon,
    this.iconSize = 14,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppFonts.plusJakarta(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Solid-fill variant of [StatusBadge] for use on top of images/hero media
/// where a translucent tint would lose contrast (e.g. "Trending" pill over
/// a college cover photo).
class SolidStatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color? foreground;

  const SolidStatusBadge({
    required this.label,
    required this.color,
    this.icon,
    this.foreground,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppFonts.plusJakarta(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Presence semantics shared across guide availability, community presence,
/// and profile online status.
enum PresenceState { online, busy, offline }

extension PresenceStateX on PresenceState {
  Color get color => switch (this) {
        PresenceState.online => const Color(0xFF16A34A),
        PresenceState.busy => const Color(0xFFD97706),
        PresenceState.offline => const Color(0xFF94A3B8),
      };

  String get label => switch (this) {
        PresenceState.online => 'Online',
        PresenceState.busy => 'Busy',
        PresenceState.offline => 'Offline',
      };
}

/// A small filled dot indicating live presence — the shared visual atom
/// behind guide availability badges and community presence indicators.
class PresenceDot extends StatelessWidget {
  final PresenceState state;
  final double size;
  final bool ring;

  const PresenceDot({
    required this.state,
    this.size = 10,
    this.ring = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state.color,
        border: ring ? Border.all(color: tokens.surfaceElevated, width: 2) : null,
      ),
    );
  }
}

/// A labeled presence pill (dot + text), the standard "Online now" /
/// "Busy" / "Offline" indicator used on guide cards and profile headers.
class PresencePill extends StatelessWidget {
  final PresenceState state;
  final String? labelOverride;

  const PresencePill({required this.state, this.labelOverride, super.key});

  @override
  Widget build(BuildContext context) {
    final color = state.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PresenceDot(state: state, size: 7, ring: false),
          const SizedBox(width: 5),
          Text(
            labelOverride ?? state.label,
            style: AppFonts.plusJakarta(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
