import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../models/ai_suggestion_group.dart';
import 'ai_recommendation_card.dart';

class AiSuggestionSection extends StatelessWidget {
  final List<AiSuggestionGroup> suggestions;
  final void Function(String collegeId)? onAddToCompare;

  const AiSuggestionSection({
    required this.suggestions,
    this.onAddToCompare,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: suggestions.map((group) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _iconFor(group.type),
                    size: 18,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.title,
                    style: AppFonts.plusJakarta(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...group.items.map(
                (item) => AiRecommendationCard(
                  recommendation: item,
                  onAddToCompare: onAddToCompare != null
                      ? () => onAddToCompare!(item.college.id)
                      : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(AiSuggestionType type) {
    switch (type) {
      case AiSuggestionType.similar:
        return Icons.content_copy_rounded;
      case AiSuggestionType.betterAlternative:
        return Icons.trending_up_rounded;
      case AiSuggestionType.budgetAlternative:
        return Icons.savings_outlined;
      case AiSuggestionType.nearbyAlternative:
        return Icons.near_me_outlined;
    }
  }
}
