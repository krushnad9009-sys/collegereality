import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../models/ai_source_citation.dart';

class AiSourceCitationsPanel extends StatelessWidget {
  final List<AiSourceCitation> sources;

  const AiSourceCitationsPanel({required this.sources, super.key});

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sources',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.gray600,
            ),
          ),
          const SizedBox(height: 4),
          ...sources.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: s.actionRoute.isNotEmpty
                    ? () => context.push(s.actionRoute)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_iconFor(s.type), size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.label,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (s.excerpt.isNotEmpty)
                              Text(
                                s.excerpt,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppTheme.gray600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (s.actionRoute.isNotEmpty)
                        Icon(Icons.open_in_new, size: 12, color: AppTheme.gray500),
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
}
