import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/chat_conversation_model.dart';

/// Premium list tile for a community thread (Ask Seniors / Student Q&A) —
/// consistent card styling, real reply-count and resolved-state, no
/// fabricated data.
class CommunityThreadCard extends StatelessWidget {
  const CommunityThreadCard({
    required this.thread,
    required this.icon,
    required this.color,
    required this.replyLabel,
    required this.onTap,
    super.key,
  });

  final ChatConversationModel thread;
  final IconData icon;
  final Color color;
  final String replyLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolved = thread.isResolved;
    final resolvedColor = const Color(0xFF16A34A);
    final iconColor = resolved ? resolvedColor : color;

    return PremiumCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              resolved ? Icons.check_circle_rounded : icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.title ?? 'Question',
                  style: AppFonts.plusJakarta(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((thread.lastMessageText ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    thread.lastMessageText!,
                    style: AppFonts.plusJakarta(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: tokens.textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tokens.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${thread.replyCount} $replyLabel',
                        style: AppFonts.plusJakarta(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                    if (resolved) ...[
                      const SizedBox(width: 6),
                      StatusBadge(
                        label: 'Resolved',
                        color: resolvedColor,
                        icon: Icons.check_circle_rounded,
                        fontSize: 11,
                        iconSize: 12,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: tokens.textTertiary),
        ],
      ),
    );
  }
}
