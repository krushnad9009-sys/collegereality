import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/ai_source_citation.dart';

class AiSourceCitationsPanel extends StatelessWidget {
  final List<AiSourceCitation> sources;

  const AiSourceCitationsPanel({required this.sources, super.key});

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOURCES',
            style: AppFonts.plusJakarta(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: tokens.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          ...sources.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: s.actionRoute.isNotEmpty
                    ? () => context.push(s.actionRoute)
                    : null,
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: tokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    border: Border.all(color: tokens.borderSubtle),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StatusBadge(
                        label: _labelFor(s.type),
                        icon: _iconFor(s.type),
                        color: AppTheme.primaryColor,
                        iconSize: 12,
                        fontSize: 10.5,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.label,
                              style: AppFonts.plusJakarta(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: tokens.textPrimary,
                              ),
                            ),
                            if (s.excerpt.isNotEmpty)
                              Text(
                                s.excerpt,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.plusJakarta(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: tokens.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (s.actionRoute.isNotEmpty)
                        Icon(
                          Icons.open_in_new,
                          size: 12,
                          color: tokens.textTertiary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(AiSourceType type) {
    switch (type) {
      case AiSourceType.profile:
        return Icons.school_outlined;
      case AiSourceType.review:
        return Icons.rate_review_outlined;
      case AiSourceType.answer:
        return Icons.question_answer_outlined;
      case AiSourceType.communityPost:
        return Icons.groups_outlined;
    }
  }

  String _labelFor(AiSourceType type) {
    switch (type) {
      case AiSourceType.profile:
        return 'Profile';
      case AiSourceType.review:
        return 'Review';
      case AiSourceType.answer:
        return 'Answer';
      case AiSourceType.communityPost:
        return 'Post';
    }
  }
}
