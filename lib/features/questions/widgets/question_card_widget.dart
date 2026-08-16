import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/constants/question_constants.dart';
import '../models/question_model.dart';
import '../utils/question_rich_text_utils.dart';

class QuestionCardWidget extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onTap;

  const QuestionCardWidget({
    required this.question,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy').format(question.createdAt);
    final tokens = context.tokens;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: PremiumCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryChip(category: question.category),
                  const Spacer(),
                  if (question.hasAcceptedAnswer)
                    StatusBadge(
                      label: 'Accepted',
                      color: const Color(0xFF16A34A),
                      icon: Icons.check_circle_rounded,
                      fontSize: 10.5,
                      iconSize: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    )
                  else if (question.mostHelpfulAnswerId != null)
                    StatusBadge(
                      label: 'Helpful',
                      color: AppTheme.secondaryColor,
                      icon: Icons.emoji_events_outlined,
                      fontSize: 10.5,
                      iconSize: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                question.title,
                style: AppFonts.plusJakarta(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: tokens.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              if (question.body.isNotEmpty) ...[
                const SizedBox(height: 8),
                QuestionRichTextUtils.buildRichText(
                  question.body,
                  maxLines: 2,
                  baseStyle: AppFonts.plusJakarta(
                    fontSize: 13,
                    color: tokens.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (question.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.image_outlined, size: 14, color: tokens.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${question.imageUrls.length} image(s)',
                      style: AppFonts.plusJakarta(fontSize: 11, color: tokens.textTertiary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    question.isAnonymous
                        ? Icons.visibility_off_outlined
                        : Icons.person_outline,
                    size: 14,
                    color: tokens.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      question.authorDisplayName,
                      style: AppFonts.plusJakarta(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: tokens.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (question.isAuthorVerified)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: question.isUnanswered
                        ? 'Unanswered'
                        : '${question.answerCount} answer${question.answerCount == 1 ? '' : 's'}',
                    highlight: question.isUnanswered,
                  ),
                  if (question.topAnswerScore > 0) ...[
                    const SizedBox(width: 12),
                    _MetaChip(
                      icon: Icons.arrow_upward_rounded,
                      label: '${question.topAnswerScore} upvotes',
                    ),
                  ],
                  const Spacer(),
                  Text(
                    date,
                    style: AppFonts.plusJakarta(fontSize: 11, color: tokens.textTertiary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        QuestionConstants.categoryLabel(category),
        style: AppFonts.plusJakarta(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = highlight ? AppTheme.warningColor : tokens.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppFonts.plusJakarta(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class QuestionFilterBar extends StatelessWidget {
  final String selectedFilter;
  final String selectedCategory;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;

  const QuestionFilterBar({
    required this.selectedFilter,
    required this.selectedCategory,
    required this.onFilterChanged,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.searchController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: AppFonts.plusJakarta(fontSize: 14, color: tokens.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search questions instantly...',
            hintStyle: AppFonts.plusJakarta(fontSize: 14, color: tokens.textTertiary),
            prefixIcon: Icon(Icons.search_rounded, size: 20, color: tokens.textTertiary),
            filled: true,
            fillColor: tokens.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.buttonRadius),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sort',
          style: AppFonts.plusJakarta(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Latest',
                selected: selectedFilter == QuestionConstants.filterLatest,
                onTap: () => onFilterChanged(QuestionConstants.filterLatest),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Most Helpful',
                selected: selectedFilter == QuestionConstants.filterMostHelpful,
                onTap: () => onFilterChanged(QuestionConstants.filterMostHelpful),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Most Upvoted',
                selected: selectedFilter == QuestionConstants.filterMostUpvoted,
                onTap: () => onFilterChanged(QuestionConstants.filterMostUpvoted),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Unanswered',
                selected: selectedFilter == QuestionConstants.filterUnanswered,
                onTap: () => onFilterChanged(QuestionConstants.filterUnanswered),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Topic',
          style: AppFonts.plusJakarta(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: QuestionConstants.allCategories.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: QuestionConstants.categoryLabel(cat),
                  selected: selectedCategory == cat,
                  onTap: () => onCategoryChanged(cat),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return FilterChip(
      label: Text(label, style: AppFonts.plusJakarta(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: tokens.surfaceMuted,
      selectedColor: primary.withValues(alpha: 0.15),
      checkmarkColor: primary,
      side: BorderSide(color: selected ? primary.withValues(alpha: 0.4) : tokens.borderSubtle),
      labelStyle: AppFonts.plusJakarta(
        color: selected ? primary : tokens.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
