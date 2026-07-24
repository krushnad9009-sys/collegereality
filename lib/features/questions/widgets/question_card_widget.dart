import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_theme.dart';
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
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.gray200.withValues(alpha: 0.9)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CategoryChip(category: question.category),
                    const Spacer(),
                    if (question.hasAcceptedAnswer)
                      _BadgeChip(
                        label: 'Accepted',
                        color: AppTheme.accentColor,
                        icon: Icons.check_circle,
                      )
                    else if (question.mostHelpfulAnswerId != null)
                      _BadgeChip(
                        label: 'Helpful',
                        color: AppTheme.secondaryColor,
                        icon: Icons.emoji_events_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  question.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (question.body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  QuestionRichTextUtils.buildRichText(
                    question.body,
                    maxLines: 2,
                    baseStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.gray600,
                    ),
                  ),
                ],
                if (question.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.image_outlined, size: 14, color: AppTheme.gray500),
                      const SizedBox(width: 4),
                      Text(
                        '${question.imageUrls.length} image(s)',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.gray500),
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
                      color: AppTheme.gray500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        question.authorDisplayName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.gray500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (question.isAuthorVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified,
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
                      icon: Icons.chat_bubble_outline,
                      label: question.isUnanswered
                          ? 'Unanswered'
                          : '${question.answerCount} answer${question.answerCount == 1 ? '' : 's'}',
                      highlight: question.isUnanswered,
                    ),
                    if (question.topAnswerScore > 0) ...[
                      const SizedBox(width: 12),
                      _MetaChip(
                        icon: Icons.arrow_upward,
                        label: '${question.topAnswerScore} upvotes',
                      ),
                    ],
                    const Spacer(),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.gray400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        QuestionConstants.categoryLabel(category),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _BadgeChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: highlight ? AppTheme.warningColor : AppTheme.gray500,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: highlight ? AppTheme.warningColor : AppTheme.gray500,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search questions instantly...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: AppTheme.gray100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sort',
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
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
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
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
    return FilterChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: GoogleFonts.poppins(
        color: selected ? AppTheme.primaryColor : AppTheme.gray600,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}
