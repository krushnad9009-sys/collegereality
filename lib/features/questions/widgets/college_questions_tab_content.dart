import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../colleges/models/college_model.dart';
import '../providers/question_provider.dart';
import 'ask_question_sheet.dart';
import 'ask_student_button.dart';
import 'question_card_widget.dart';
import 'question_shimmer.dart';
import 'unanswered_questions_banner.dart';

class CollegeQuestionsTabContent extends ConsumerStatefulWidget {
  final CollegeModel college;

  const CollegeQuestionsTabContent({required this.college, super.key});

  @override
  ConsumerState<CollegeQuestionsTabContent> createState() =>
      _CollegeQuestionsTabContentState();
}

class _CollegeQuestionsTabContentState
    extends ConsumerState<CollegeQuestionsTabContent> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= max - 200) {
      ref.read(questionListFilterProvider(widget.college.id).notifier).showMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collegeId = widget.college.id;
    final resultAsync = ref.watch(displayedCollegeQuestionsProvider(collegeId));
    final filterState = ref.watch(questionListFilterProvider(collegeId));
    final isWide = MediaQuery.of(context).size.width >= 600;
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return resultAsync.when(
      loading: () => const QuestionListShimmer(),
      error: (e, _) => AsyncErrorView(
        message: 'Error loading questions: $e',
        onRetry: () =>
            ref.invalidate(displayedCollegeQuestionsProvider(collegeId)),
      ),
      data: (result) {
        final questions = result.questions;
        return ListView(
          controller: _scrollController,
          padding: EdgeInsets.all(isWide ? AppSpacing.xxl : AppSpacing.lg),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondaryColor.withValues(alpha: 0.12),
                    primary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(tokens.cardRadius),
                border: Border.all(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask a Student',
                    style: AppFonts.plusJakarta(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: tokens.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Get honest answers from verified students and alumni of ${widget.college.name}.',
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      color: tokens.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AskStudentButton(
                    collegeId: collegeId,
                    collegeName: widget.college.name,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            UnansweredQuestionsBanner(
              collegeId: collegeId,
              collegeName: widget.college.name,
            ),
            QuestionFilterBar(
              searchController: _searchController,
              selectedFilter: filterState.filter,
              selectedCategory: filterState.category,
              onFilterChanged: (filter) {
                ref.read(questionListFilterProvider(collegeId).notifier)
                  ..setFilter(filter)
                  ..resetPagination();
              },
              onCategoryChanged: (category) {
                ref.read(questionListFilterProvider(collegeId).notifier)
                  ..setCategory(category)
                  ..resetPagination();
              },
              onSearchChanged: (query) {
                ref.read(questionListFilterProvider(collegeId).notifier)
                  ..setSearchQuery(query)
                  ..resetPagination();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${result.totalFiltered} question${result.totalFiltered == 1 ? '' : 's'}',
              style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            if (questions.isEmpty)
              _EmptyState(
                hasSearch: filterState.searchQuery.isNotEmpty ||
                    filterState.filter != 'latest' ||
                    filterState.category != 'all',
                onAsk: () => showAskQuestionSheet(
                  context: context,
                  ref: ref,
                  collegeId: collegeId,
                  collegeName: widget.college.name,
                ),
              )
            else
              ...questions.map(
                (question) => QuestionCardWidget(
                  question: question,
                  onTap: () => context.push(
                    RouteNames.collegeQuestionPath(collegeId, question.id),
                  ),
                ),
              ),
            if (result.hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(questionListFilterProvider(collegeId).notifier)
                        .showMore(),
                    icon: const Icon(Icons.expand_more_rounded, size: 18),
                    label: Text(
                      'Load more questions',
                      style: AppFonts.plusJakarta(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAsk;

  const _EmptyState({
    required this.hasSearch,
    required this.onAsk,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: AsyncEmptyView(
        icon: Icons.quiz_outlined,
        title: hasSearch ? 'No matching questions' : 'No questions yet',
        subtitle: hasSearch
            ? 'Try a different search, topic, or sort filter'
            : 'Be the first to ask a verified student',
        action: hasSearch
            ? null
            : FilledButton.icon(
                onPressed: onAsk,
                icon: const Icon(Icons.question_answer_outlined, size: 18),
                label: Text(
                  'Ask a Student',
                  style: AppFonts.plusJakarta(fontWeight: FontWeight.w700),
                ),
              ),
      ),
    );
  }
}
